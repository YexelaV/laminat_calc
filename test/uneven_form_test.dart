// Measuring a room wall by wall, from the form's side.
//
// The engine is checked elsewhere; what matters here is that the five numbers a
// user types reach it as the room they measured, that turning the walls on
// costs nothing to a user who did not measure across, and that measurements
// which close into no room stop at the Next button rather than at an empty
// result screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/widgets/room_sketch.dart';

CalculateCubit get cubit => getIt.get<CalculateCubit>();

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<CalculateCubit>(CalculateCubit());
  });
  tearDown(getIt.reset);

  Future<void> pumpForm(WidgetTester tester,
      {MeasurementSystem system = MeasurementSystem.metric}) async {
    tester.view.physicalSize = const Size(560, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // The system is answered on its own screen before the form opens and lives
    // in the cubit; MyApp's savedSystem only says which screen comes first.
    cubit.setMeasurementSystem(system);
    await tester.pumpWidget(MyApp(savedLocaleCode: 'en', savedSystem: system.name));
    await tester.pumpAndSettle();
  }

  // Fields are filled by position: metric rooms are one box each, in the order
  // they read.
  Future<void> fill(WidgetTester tester, List<String> values, {int from = 0}) async {
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextField).at(from + i), values[i]);
      await tester.pumpAndSettle();
    }
  }

  Future<void> turnOnUnevenWalls(WidgetTester tester) async {
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
  }

  bool nextEnabled(WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Next')).onPressed != null;

  testWidgets('the walls typed reach the calculation as the room measured', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['5010', '3000']);
    await turnOnUnevenWalls(tester);
    // The second pair and the diagonal arrive already filled with the rectangle
    // the user had, so only what was actually measured needs changing.
    expect(cubit.state.roomLength2, 5010);
    expect(cubit.state.roomWidth2, 3000);
    expect(cubit.state.roomDiagonal, RoomShape.rectangleDiagonal(5010, 3000));
    expect(cubit.state.shape!.isRectangular, isTrue,
        reason: 'turning the switch on must not change the room on its own');

    await fill(tester, ['4980', '3025', '5840'], from: 2);
    final shape = cubit.state.shape!;
    expect(shape.lengthNear, 5010);
    expect(shape.widthLeft, 3000);
    expect(shape.lengthFar, 4980);
    expect(shape.widthRight, 3025);
    expect(shape.diagonal, 5840);
    expect(shape.problem, isNull);
    expect(shape.isRectangular, isFalse);

    await fill(tester, ['1200', '190', '8'], from: 5);
    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('turning the walls back off leaves the rectangle behind', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['5010', '3000']);
    await turnOnUnevenWalls(tester);
    await fill(tester, ['4980', '3025', '5840'], from: 2);
    expect(cubit.state.shape!.isRectangular, isFalse);

    await turnOnUnevenWalls(tester);
    expect(cubit.state.unevenWalls, isFalse);
    // The extra measurements are still in the state, but they are off screen
    // and out of the room: the shape is the rectangle it was before.
    final shape = cubit.state.shape!;
    expect(shape.isRectangular, isTrue);
    expect(shape.lengthNear, 5010);
    expect(shape.lengthFar, 5010);
    expect(shape.widthRight, 3000);
  });

  testWidgets('a diagonal the walls cannot reach round is refused by its own field',
      (tester) async {
    await pumpForm(tester);
    await fill(tester, ['5010', '3000']);
    await turnOnUnevenWalls(tester);
    await fill(tester, ['4980', '3025'], from: 2);
    await fill(tester, ['1200', '190', '8'], from: 5);
    expect(nextEnabled(tester), isTrue);

    // Longer than the two walls it has to reach across put together. The field
    // knows its own bound — worked out from the walls, not fixed — so the user
    // is told the number rather than just refused.
    await fill(tester, ['9000'], from: 4);
    expect(find.textContaining('Maximum'), findsOneWidget);
    expect(nextEnabled(tester), isFalse);
    expect(cubit.state.roomDiagonal, isNot(9000), reason: 'a rejected value is not stored');

    await fill(tester, ['5840'], from: 4);
    expect(nextEnabled(tester), isTrue, reason: 'and it recovers');
  });

  testWidgets('walls that close into a folded room stop at the button', (tester) async {
    await pumpForm(tester);
    // A far wall far too short for the room the other three describe. Every
    // field is inside its own bounds, the diagonal included — only the outline
    // they make between them is impossible, and nothing but the outline can
    // say so.
    await fill(tester, ['6000', '3000']);
    await turnOnUnevenWalls(tester);
    await fill(tester, ['800', '3000', '3300'], from: 2);
    await fill(tester, ['1200', '190', '8'], from: 5);
    expect(cubit.state.shape!.problem, RoomProblem.notConvex);
    expect(find.text('The walls do not close'), findsOneWidget,
        reason: 'a disabled button on its own does not say what is wrong');
    expect(nextEnabled(tester), isFalse);
  });

  testWidgets('the sketch is on screen to say which wall is which', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['5010', '3000']);
    expect(find.byType(RoomSketch), findsNothing);
    await turnOnUnevenWalls(tester);
    expect(find.byType(RoomSketch), findsOneWidget);
    // Every measurement is written on the wall it belongs to.
    await fill(tester, ['4980', '3025', '5840'], from: 2);
    expect(find.byType(RoomSketch), findsOneWidget);
  });

  testWidgets('in feet and inches every wall keeps its own pair of boxes', (tester) async {
    await pumpForm(tester, system: MeasurementSystem.imperial);
    // Feet, inches, feet, inches: length then width, as before.
    await fill(tester, ['16', '5', '9', '10']);
    await turnOnUnevenWalls(tester);
    expect(cubit.state.roomLength, feetInchesToMm(16, 5));
    expect(cubit.state.roomWidth, feetInchesToMm(9, 10));
    expect(cubit.state.shape!.isRectangular, isTrue);

    // The second pair and the diagonal follow in the same shape.
    await fill(tester, ['16', '4', '9', '11'], from: 4);
    final shape = cubit.state.shape!;
    expect(shape.lengthFar, feetInchesToMm(16, 4));
    expect(shape.widthRight, feetInchesToMm(9, 11));
    expect(shape.problem, isNull);
  });
}
