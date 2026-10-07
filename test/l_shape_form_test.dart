// A room with a corner cut away, from the form's side.
//
// The geometry is checked elsewhere; what matters here is that the four
// numbers and the corner a user picks reach the engine as the room they
// measured, that choosing the shape costs nothing to someone who then changes
// their mind, that a cut which leaves no room stops at the Next button rather
// than at an empty result screen, and that the one direction this room cannot
// be laid in is out of reach rather than merely wrong.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_kind.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/widgets/room_sketch.dart';

late CalculateCubit cubit;


/// The one cubit the app runs on, fetched out of the tree the provider in
/// `main.dart` put it in. The test used to reach for a global; now it asks
/// the widget that owns it, which is also what every screen does.
CalculateCubit cubitIn(WidgetTester tester) =>
    BlocProvider.of<CalculateCubit>(tester.element(find.byType(MaterialApp)));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpForm(WidgetTester tester,
      {MeasurementSystem system = MeasurementSystem.metric}) async {
    tester.view.physicalSize = const Size(560, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MyApp(savedLocaleCode: 'en', savedSystem: system.name));
    await tester.pumpAndSettle();
    cubit = cubitIn(tester);
  }

  Future<void> fill(WidgetTester tester, List<String> values, {int from = 0}) async {
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextField).at(from + i), values[i]);
      await tester.pumpAndSettle();
    }
  }

  /// The shape is a tile in a row of them now, not a line in a menu, so one tap
  /// does it. Found by key rather than by the name under it: the names are
  /// translated and the keys are not.
  Future<void> pickShape(WidgetTester tester, RoomKind kind) async {
    await tester.tap(find.byKey(ValueKey(kind)));
    await tester.pumpAndSettle();
  }

  bool nextEnabled(WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Next')).onPressed != null;

  testWidgets('the cut typed reaches the calculation as the room measured', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.lShaped);
    // The cut arrives empty and the button stays grey: the shape is something
    // the user says about the room, not two measurements the form takes for
    // them. The sketch has an L to draw all the same — see [CalculateState
    // .shape], where a cut nobody has typed is a third of the room — so the
    // boxes below it are the only place that admits to a guess.
    expect(cubit.state.notchLength, isNull);
    expect(cubit.state.notchWidth, isNull);
    expect(nextEnabled(tester), isFalse);

    await fill(tester, ['1500', '1000'], from: 2);
    final shape = cubit.state.shape! as LRoomShape;
    expect(shape.length, 4000);
    expect(shape.width, 3000);
    expect(shape.notchLength, 1500);
    expect(shape.notchWidth, 1000);
    expect(shape.corner, RoomCorner.farRight);
    expect(shape.problem, isNull);
    expect(shape.isRectangular, isFalse);
    expect(shape.corners().length, 6);

    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('the corner is picked on the sketch', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.lShaped);
    expect(cubit.state.notchCorner, RoomCorner.farRight);

    for (final corner in RoomCorner.values) {
      await tester.tap(find.byKey(ValueKey('cut-corner-${corner.name}')));
      await tester.pumpAndSettle();
      expect(cubit.state.notchCorner, corner);
      expect((cubit.state.shape! as LRoomShape).corner, corner,
          reason: 'the room the engine gets has the corner that was tapped');
    }
  });

  testWidgets('changing the shape back leaves the rectangle behind', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.lShaped);
    await fill(tester, ['1500', '1000'], from: 2);
    expect(cubit.state.shape!.isRectangular, isFalse);

    await pickShape(tester, RoomKind.rectangle);
    expect(cubit.state.lShaped, isFalse);
    // The cut is still in the state, but it is off screen and out of the room.
    final shape = cubit.state.shape! as RoomShape;
    expect(shape.isRectangular, isTrue);
    expect(shape.lengthNear, 4000);
    expect(shape.widthLeft, 3000);
    expect(cubit.state.notchLength, 1500, reason: 'and it comes back if they change their mind');
  });

  testWidgets('the two shapes keep their own numbers', (tester) async {
    // They are alternatives, not one control reused, so a user who tries both
    // finds each as they left it.
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.uneven);
    await fill(tester, ['3980', '3010', '5010'], from: 2);
    await pickShape(tester, RoomKind.lShaped);
    await fill(tester, ['1500', '1000'], from: 2);
    await pickShape(tester, RoomKind.uneven);
    expect(cubit.state.roomLength2, 3980);
    expect(cubit.state.roomWidth2, 3010);
    expect(cubit.state.roomDiagonal, 5010);
    expect(cubit.state.notchLength, 1500);
    expect(cubit.state.notchWidth, 1000);
  });

  testWidgets('a cut that leaves no room is refused by its own field', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.lShaped);
    await fill(tester, ['1500', '1000'], from: 2);
    expect(nextEnabled(tester), isTrue);

    // Longer than the room less the narrowest room there is. The field knows
    // its own bound — worked out from the overall size, not fixed — so the
    // user is told the number rather than just refused.
    await fill(tester, ['3900'], from: 2);
    expect(find.textContaining('Maximum'), findsOneWidget);
    expect(nextEnabled(tester), isFalse);
    expect(cubit.state.notchLength, isNot(3900), reason: 'a rejected value is not stored');

    await fill(tester, ['1500'], from: 2);
    expect(nextEnabled(tester), isTrue, reason: 'and it recovers');
  });

  testWidgets('the sketch is on screen to say which corner is cut', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    expect(find.byType(RoomSketch), findsNothing);
    await pickShape(tester, RoomKind.lShaped);
    expect(find.byType(RoomSketch), findsOneWidget);
    expect(find.text('Tap the corner that is cut away'), findsOneWidget);
  });

  testWidgets('in feet and inches the cut keeps its own pair of boxes', (tester) async {
    // The fraction picker beside each inch box holds its value, so a test that
    // only types the whole inches measures whatever fraction was left there.
    Future<void> pickFraction(WidgetTester tester, int index, String label) async {
      await tester.tap(find.byType(DropdownButton<int>).at(index));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await pumpForm(tester, system: MeasurementSystem.imperial);
    // Feet, inches, feet, inches: length then width, as before.
    await fill(tester, ['13', '1', '9', '10']);
    await pickShape(tester, RoomKind.lShaped);
    expect(cubit.state.roomLength, feetInchesToMm(13, 1));
    expect(cubit.state.roomWidth, feetInchesToMm(9, 10));

    // And the cut follows in the same shape, in boxes that accept less than a
    // foot — a boxed-in riser usually is.
    await fill(tester, ['0', '8', '1', '4'], from: 4);
    await pickFraction(tester, 2, '1/2');
    await pickFraction(tester, 3, '1/4');
    final shape = cubit.state.shape! as LRoomShape;
    expect(shape.notchLength, feetInchesToMm(0, 8.5));
    expect(shape.notchWidth, feetInchesToMm(1, 4.25));
    expect(shape.problem, isNull);
  });

  testWidgets('a 45° layout is out of reach in such a room', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);

    // Chosen while the room was still a rectangle...
    cubit.setDirection(Direction.diagonal);
    expect(cubit.state.direction, Direction.diagonal);

    // ...and un-chosen by the room, not merely greyed out on the next screen:
    // the direction is read by the row plan and the validators too.
    await pickShape(tester, RoomKind.lShaped);
    expect(cubit.state.direction, Direction.length);

    // The cut itself, which nothing fills in for the user.
    await fill(tester, ['1500', '1000'], from: 2);

    // The laminate sits between the room and the laying now, so the walk to
    // the direction buttons goes through it.
    await tester.tap(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();
    await fill(tester, ['1200', '190', '8']);
    await tester.tap(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();
    final segments = tester
        .widget<SegmentedButton<Direction>>(find.byType(SegmentedButton<Direction>))
        .segments;
    expect(segments.firstWhere((s) => s.value == Direction.diagonal).enabled, isFalse);
    expect(segments.firstWhere((s) => s.value == Direction.length).enabled, isTrue);
    expect(find.textContaining('Diagonal laying is not supported'), findsOneWidget);
  });
}
