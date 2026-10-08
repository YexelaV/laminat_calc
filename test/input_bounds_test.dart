// The edges of what the form accepts, driven through the real screens.
//
// The bounds in constants.dart are two kinds of number mixed together: the ones
// the engine or the geometry needs, and the ones that were a guess at what a
// floor looks like. The guesses were refusing laminate that is sold — a
// herringbone block 200 mm long, a strip 50 mm across, a pack of 36 tiles — so
// they came down. This is what keeps them down: the stress suite proves the
// engine lays such a floor, and this proves the form lets one be typed.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/laminate_cubit.dart';
import 'package:floor_calculator/cubit/laying_cubit.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/room_kind.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> fill(WidgetTester tester, List<String> values) async {
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextField).at(i), values[i]);
      await tester.pumpAndSettle();
    }
  }

  bool nextEnabled(WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Next')).onPressed != null;

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();
  }

  testWidgets('a tile-sized plank, a pack of 36 and the new floors go through',
      (tester) async {
    tester.view.physicalSize = const Size(560, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp(savedLocaleCode: 'en', savedSystem: 'metric'));
    await tester.pumpAndSettle();
    final laminate = cubitIn<LaminateCubit>(tester);
    final laying = cubitIn<LayingCubit>(tester);

    await fill(tester, ['4000', '3000']);
    await next(tester);

    // Every one of these three was refused before: the plank floors were
    // 300 × 90 and a pack held at most 20. The plank and the laying share a
    // screen, so the gap and the shortest offcut follow in the same run.
    await fill(tester, [
      '$MIN_PLANK_LENGTH',
      '$MIN_PLANK_WIDTH',
      '36',
      '10',
      '$MIN_MIN_LENGTH',
    ]);
    expect(find.textContaining('Minimum'), findsNothing);
    expect(find.textContaining('Maximum'), findsNothing);
    expect(nextEnabled(tester), isTrue);
    expect(laminate.state.laminateLength, MIN_PLANK_LENGTH);
    expect(laminate.state.laminateWidth, MIN_PLANK_WIDTH);
    expect(laminate.state.quantityPerPack, 36);

    // And the exact offset at its floor, which is the one the 1/4 button has
    // been handing the engine all along without asking this field's leave.
    await tester.tap(find.text('exact'));
    await tester.pumpAndSettle();
    await fill(tester, [
      '$MIN_PLANK_LENGTH',
      '$MIN_PLANK_WIDTH',
      '36',
      '10',
      '$MIN_ROW_OFFSET',
      '$MIN_MIN_LENGTH',
    ]);
    expect(find.textContaining('Minimum'), findsNothing);
    expect(nextEnabled(tester), isTrue);
    expect(laying.state.rowOffset, MIN_ROW_OFFSET);
    expect(laying.state.minimumLaminateLength, MIN_MIN_LENGTH);
  });

  testWidgets('no expansion gap at all is a gap the form takes', (tester) async {
    // Zero is a real answer here and not an empty field. A threshold strip or a
    // skirting fixed to the floor leaves nothing to inset by, and a floor laid
    // tight to the wall is still a floor to count.
    //
    // Nothing refuses it today. This is what keeps it that way: the gap is the
    // one measurement on the form whose floor is zero, so the day a minimum is
    // tightened along with the rest it would go unnoticed everywhere else.
    tester.view.physicalSize = const Size(560, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp(savedLocaleCode: 'en', savedSystem: 'metric'));
    await tester.pumpAndSettle();
    final laying = cubitIn<LayingCubit>(tester);

    // A room with a corner cut away, because the cut is inset from its own two
    // walls as well: a gap of nothing is the one that insets nothing anywhere.
    await fill(tester, ['4000', '3000']);
    await tester.tap(find.byKey(const ValueKey(RoomKind.lShaped)));
    await tester.pumpAndSettle();
    await fill(tester, ['4000', '3000', '1500', '1000']);
    await next(tester);

    await fill(tester, ['1200', '190', '8', '0', '300']);
    expect(find.textContaining('Minimum'), findsNothing);
    expect(find.textContaining('Incorrect'), findsNothing);
    expect(nextEnabled(tester), isTrue);
    expect(laying.state.indentFromWall, 0, reason: 'zero is stored, not dropped');

    // Through the review, which reads the gap back, and on to a layout: the
    // engine insets the floor by the gap and the drawing takes the inset
    // outline, so a zero there has to come out as the room itself.
    await next(tester);
    expect(find.text('0 mm'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Calculate'));
    await tester.pumpAndSettle();
    expect(find.text('Laying variants:'), findsOneWidget,
        reason: 'the engine found a layout rather than refusing the room');
    expect(find.textContaining('not possible'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a quarter of the shortest plank is still a legal offset',
      (tester) async {
    // The fraction buttons work the offset out from the plank and hand it over
    // without a range check, so the floor under the typed offset has to be at
    // or below what they can produce — otherwise the form is stricter than the
    // button beside it.
    expect(MIN_PLANK_LENGTH ~/ 4, greaterThanOrEqualTo(MIN_ROW_OFFSET));
    // And half the shortest plank, which is the ceiling the offset field shows,
    // has to leave a range to type in at all.
    expect(MIN_PLANK_LENGTH ~/ 2, greaterThan(MIN_ROW_OFFSET));
  });
}

/// One of the cubits the app runs on, fetched out of the tree the providers in
/// `main.dart` put them in.
T cubitIn<T extends BlocBase<Object?>>(WidgetTester tester) =>
    BlocProvider.of<T>(tester.element(find.byType(MaterialApp)));
