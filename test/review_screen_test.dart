// The screen that shows back what was typed, before anything is worked out
// from it.
//
// Two things are worth a test here and the rest is layout. One: the review
// lists every measurement the room form asked for, whatever shape the room is —
// the two lists are built in different files and would otherwise drift the day
// an eighth shape became a ninth. Two: the direction it reports is the one the
// floor will actually be laid in, which is not always the one stored.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/cubit/laying_cubit.dart';
import 'package:floor_calculator/cubit/room_cubit.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/pages/review_screen.dart';
import 'package:floor_calculator/pages/room_parameters_screen.dart';
import 'package:floor_calculator/room_kind.dart';

/// Each shape's own measurements, after the overall 4000 by 3000, in the order
/// the room form asks for them.
const _cutsFor = <RoomKind, List<String>>{
  RoomKind.rectangle: [],
  RoomKind.uneven: ['4000', '3000', '5000'],
  RoomKind.chamfer: ['900'],
  RoomKind.chamferPair: ['800', '1000'],
  RoomKind.lShaped: ['1500', '1000'],
  // A T and a П are measured by the piece in the middle of their cut wall: how
  // far it runs along the wall, and how deep it is.
  RoomKind.tShaped: ['1600', '700'],
  RoomKind.zShaped: ['1500', '1200', '1000', '900'],
  RoomKind.uShaped: ['1000', '700'],
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(560, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp(savedLocaleCode: 'en', savedSystem: 'metric'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, List<String> values, {int from = 0}) async {
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextField).at(from + i), values[i]);
      await tester.pumpAndSettle();
    }
  }

  Future<void> next(WidgetTester tester) async {
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();
  }

  testWidgets('every measurement the room form asked for is shown back',
      (tester) async {
    // The load-bearing one. [roomMeasurements] and the form's own box list are
    // built in two places from the same state, and nothing but this says they
    // agree: a shape added to one and forgotten in the other would show a user
    // a review with a number missing from it.
    await pump(tester);
    // Below the MaterialApp: the localisations it provides are not in scope
    // at its own element.
    final strings = AppStrings.of(tester.element(find.byType(Scaffold)));
    final room = tester.element(find.byType(MaterialApp));

    for (final kind in RoomKind.values) {
      await fill(tester, ['4000', '3000']);
      await tester.tap(find.byKey(ValueKey(kind)));
      await tester.pumpAndSettle();
      final cut = _cutsFor[kind]!;
      await fill(tester, cut, from: 2);

      // One box on the form per measurement in the list, and in the same order.
      expect(find.byType(TextField), findsNWidgets(2 + cut.length), reason: '$kind');
      final state = BlocProvider.of<RoomCubit>(room).state;
      final listed = roomMeasurements(strings, state);
      expect(listed.length, 2 + cut.length, reason: '$kind');
      expect(listed.map((m) => m.valueMm).toList(),
          [4000, 3000, ...cut.map(int.parse)],
          reason: '$kind: the list reads the same values the boxes hold');
      expect(listed.map((m) => m.title).toSet().length, listed.length,
          reason: '$kind: two measurements answering to one name');
    }
  });

  testWidgets('the whole walk ends on a review of what was typed', (tester) async {
    await pump(tester);
    await fill(tester, ['4000', '3000']);
    await next(tester);
    await fill(tester, ['1380', '190', '8', '10', '300']);
    await next(tester);

    // The room, the plank and the laying, all three read back.
    expect(find.text('Rectangular'), findsOneWidget);
    expect(find.text('4000 mm'), findsOneWidget);
    expect(find.text('3000 mm'), findsOneWidget);
    expect(find.text('1380 mm'), findsOneWidget);
    expect(find.text('190 mm'), findsOneWidget);
    expect(find.text('8 pcs'), findsOneWidget);
    expect(find.text('Along length'), findsOneWidget);
    expect(find.text('10 mm'), findsOneWidget);
    expect(find.text('300 mm'), findsOneWidget);
    // The fraction and what it came to, because the user chose one and the
    // floor is laid to the other.
    expect(find.text('1/2 · 690 mm'), findsOneWidget);

    expect(find.text('Calculate'), findsOneWidget);
    expect(find.byType(TextField), findsNothing,
        reason: 'nothing is editable here: the way to change a number is back');
  });

  testWidgets('the direction shown is the one the floor will be laid in',
      (tester) async {
    // A user picks 45° in a rectangle, goes back and notches the room. The
    // laying screen does not rewrite their answer — it reads it through the
    // room — so the review has to read it the same way or it will promise a
    // diagonal floor and deliver one laid along the room.
    const room = RoomState(
      roomLength: 4000,
      roomWidth: 3000,
      notchLength: 1500,
      notchWidth: 1000,
      roomKind: RoomKind.lShaped,
    );
    expect(room.shape!.takesDiagonal, isFalse);
    expect(
        ReviewScreen.effectiveDirection(
            room, const LayingState(direction: Direction.diagonal)),
        Direction.length);

    // And a room that refuses one of the two straight ways is turned the only
    // way it takes.
    const wallNotch = RoomState(
      roomLength: 4000,
      roomWidth: 3000,
      notchLength: 1500,
      notchLength2: 1500,
      notchWidth: 700,
      roomKind: RoomKind.uShaped,
    );
    expect(wallNotch.shape!.takesAlongLength, isFalse);
    expect(
        ReviewScreen.effectiveDirection(
            wallNotch, const LayingState(direction: Direction.length)),
        Direction.width);
  });
}
