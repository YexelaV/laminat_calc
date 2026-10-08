// Measuring a room wall by wall, from the form's side.
//
// The engine is checked elsewhere; what matters here is that the five numbers a
// user types reach it as the room they measured, that turning the walls on
// costs nothing to a user who did not measure across, and that measurements
// which close into no room stop at the Next button rather than at an empty
// result screen.
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/cubit/room_cubit.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/room_kind.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/widgets/room_sketch.dart';

late RoomCubit cubit;


/// The one cubit the app runs on, fetched out of the tree the provider in
/// `main.dart` put it in. The test used to reach for a global; now it asks
/// the widget that owns it, which is also what every screen does.
RoomCubit cubitIn(WidgetTester tester) =>
    BlocProvider.of<RoomCubit>(tester.element(find.byType(MaterialApp)));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpForm(WidgetTester tester,
      {MeasurementSystem system = MeasurementSystem.metric}) async {
    tester.view.physicalSize = const Size(560, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // The system is answered on its own screen before the form opens and lives
    // in the cubit; MyApp's savedSystem only says which screen comes first.
    await tester.pumpWidget(MyApp(savedLocaleCode: 'en', savedSystem: system.name));
    await tester.pumpAndSettle();
    cubit = cubitIn(tester);
  }

  // Fields are filled by position: metric rooms are one box each, in the order
  // they read.
  Future<void> fill(WidgetTester tester, List<String> values, {int from = 0}) async {
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextField).at(from + i), values[i]);
      await tester.pumpAndSettle();
    }
  }

  // The shape is a choice of three now, so turning the walls on means picking
  // them out of the list rather than ticking a box.
  /// The shape is a tile in a row of them now, not a line in a menu, so one tap
  /// does it. Found by key rather than by the name under it: the names are
  /// translated and the keys are not.
  Future<void> pickShape(WidgetTester tester, RoomKind kind) async {
    await tester.tap(find.byKey(ValueKey(kind)));
    await tester.pumpAndSettle();
  }

  Future<void> turnOnUnevenWalls(WidgetTester tester) =>
      pickShape(tester, RoomKind.uneven);

  Future<void> turnOffUnevenWalls(WidgetTester tester) =>
      pickShape(tester, RoomKind.rectangle);

  bool nextEnabled(WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Next')).onPressed != null;

  testWidgets('the walls typed reach the calculation as the room measured', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['5010', '3000']);
    await turnOnUnevenWalls(tester);
    // The second pair and the diagonal arrive empty: saying the walls differ
    // is not the same as having measured them, and a box filled in with the
    // wall opposite would be the form telling the user what they measured.
    expect(cubit.state.roomLength2, isNull);
    expect(cubit.state.roomWidth2, isNull);
    expect(cubit.state.roomDiagonal, isNull);
    expect(nextEnabled(tester), isFalse);
    // The drawing has a room to show all the same — a wall left blank is the
    // one opposite it, and it is drawn with a question mark beside it.
    expect(cubit.state.shape!.isRectangular, isTrue,
        reason: 'turning the switch on must not change the room on its own');

    await fill(tester, ['4980', '3025', '5840'], from: 2);
    final shape = cubit.state.shape! as RoomShape;
    expect(shape.lengthNear, 5010);
    expect(shape.widthLeft, 3000);
    expect(shape.lengthFar, 4980);
    expect(shape.widthRight, 3025);
    expect(shape.diagonal, 5840);
    expect(shape.problem, isNull);
    expect(shape.isRectangular, isFalse);

    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('turning the walls back off leaves the rectangle behind', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['5010', '3000']);
    await turnOnUnevenWalls(tester);
    await fill(tester, ['4980', '3025', '5840'], from: 2);
    expect(cubit.state.shape!.isRectangular, isFalse);

    await turnOffUnevenWalls(tester);
    expect(cubit.state.unevenWalls, isFalse);
    // The extra measurements are still in the state, but they are off screen
    // and out of the room: the shape is the rectangle it was before.
    final shape = cubit.state.shape! as RoomShape;
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
    await fill(tester, ['4980', '3025', '5840'], from: 2);
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
    expect(cubit.state.shape!.problem, RoomProblem.notConvex);
    expect(find.text('The walls do not close'), findsOneWidget,
        reason: 'a disabled button on its own does not say what is wrong');
    expect(nextEnabled(tester), isFalse);
  });

  testWidgets('a wall nobody has measured is drawn as a question mark', (tester) async {
    // The outline needs a number for every wall or it is not an outline, so an
    // empty box is filled in with the wall opposite. Writing that number on the
    // wall would be the drawing telling the user what they measured.
    await pumpForm(tester);
    // The shape first and the sizes after, which is the order that leaves the
    // other three boxes empty — picking the shape with the sizes already typed
    // fills them in.
    await pickShape(tester, RoomKind.uneven);
    await fill(tester, ['12000', '3000']);

    RoomSketch sketch() => tester.widget<RoomSketch>(find.byType(RoomSketch));
    // [RoomShape.wallLengths] is near, right, far, left: the right wall is the
    // second width and the far wall is the second length.
    expect(sketch().unknownWalls, {1, 2});
    expect(sketch().unknownDiagonal, isTrue);

    await fill(tester, ['11900'], from: 2);
    expect(sketch().unknownWalls, {1});
    await fill(tester, ['3050'], from: 3);
    expect(sketch().unknownWalls, isEmpty);
    expect(sketch().unknownDiagonal, isTrue, reason: 'the diagonal is still blank');
    await fill(tester, ['12300'], from: 4);
    expect(sketch().unknownDiagonal, isFalse);
  });

  testWidgets('a shape tried on in between does not fill in what was left blank',
      (tester) async {
    // Picking the shape never fills a box; nor does picking it a second time.
    // The form used to hand over a rectangle on the way in, and the way that
    // showed itself was here: three boxes the user had left blank came back
    // full after a look at another shape.
    await pumpForm(tester);
    await pickShape(tester, RoomKind.uneven);
    await fill(tester, ['5010', '3000']);
    expect(cubit.state.roomLength2, isNull);
    expect(nextEnabled(tester), isFalse);

    await pickShape(tester, RoomKind.rectangle);
    await pickShape(tester, RoomKind.uneven);

    expect(cubit.state.roomLength2, isNull);
    expect(cubit.state.roomWidth2, isNull);
    expect(cubit.state.roomDiagonal, isNull);
    // And the boxes say the same as the state: three measurements still to take.
    for (final i in [2, 3, 4]) {
      expect(tester.widget<TextField>(find.byType(TextField).at(i)).controller!.text, isEmpty,
          reason: 'box $i was filled in by the round trip');
    }
    expect(nextEnabled(tester), isFalse,
        reason: 'a room three measurements short cannot be calculated');
  });

  testWidgets('the measurement being typed is picked out on the sketch', (tester) async {
    // Four walls and a diagonal is a crowded little drawing, and which of five
    // numbers belongs to the box under the cursor is otherwise a puzzle.
    await pumpForm(tester);
    await fill(tester, ['5010', '3000']);
    await pickShape(tester, RoomKind.uneven);
    await fill(tester, ['4980', '3025', '5840'], from: 2);

    RoomSketch sketch() => tester.widget<RoomSketch>(find.byType(RoomSketch));
    expect(sketch().litWalls, isEmpty, reason: 'nothing has the cursor yet');

    Future<void> cursorInto(int box) async {
      await tester.tap(find.byType(TextField).at(box));
      await tester.pumpAndSettle();
    }

    await cursorInto(0);
    expect(sketch().litWalls, {0}, reason: 'the near wall');
    await cursorInto(1);
    expect(sketch().litWalls, {3}, reason: 'the left wall');
    await cursorInto(2);
    expect(sketch().litWalls, {2}, reason: 'the far wall');
    await cursorInto(3);
    expect(sketch().litWalls, {1}, reason: 'the right wall');
    await cursorInto(4);
    expect(sketch().litWalls, isEmpty, reason: 'the diagonal is no wall');
    expect(sketch().litDiagonal, isTrue);
  });

  testWidgets('each wall box is named for the side of the drawing it lights up',
      (tester) async {
    // The boxes used to be "Length 1", "Width 1", "Length 2", "Width 2", which
    // left the user matching four numbers to four walls by trying them. Now
    // each says which side of the sketch it is, and the two have to agree —
    // what follows is both halves of that: the label, and the wall it lights.
    await pumpForm(tester);
    await fill(tester, ['5010', '3000']);
    await pickShape(tester, RoomKind.uneven);
    await fill(tester, ['4980', '3025', '5840'], from: 2);

    RoomSketch sketch() => tester.widget<RoomSketch>(find.byType(RoomSketch));
    Future<Set<int>> litBy(String label) async {
      await tester.tap(find.ancestor(
          of: find.text(label), matching: find.byType(TextField)));
      await tester.pumpAndSettle();
      return sketch().litWalls;
    }

    // Corner `i` of the outline runs to corner `i + 1`, so wall 0 is the near
    // one and the rest follow round: right, far, left.
    expect(await litBy('Length (top) mm'), {0});
    expect(await litBy('Width (right) mm'), {1});
    expect(await litBy('Length (bottom) mm'), {2});
    expect(await litBy('Width (left) mm'), {3});

    // And the sketch really is drawn that way round, which is the half the
    // labels now depend on and nothing used to check. Compared by where each
    // wall sits rather than by a coordinate: the walls of this room lean, so
    // the left one does not stand at a single x — it is simply the leftmost of
    // the four, which is what calling it "left" claims.
    final corners = cubit.state.shape!.corners();
    Point<double> middleOf(int wall) {
      final from = corners[wall];
      final to = corners[(wall + 1) % corners.length];
      return Point((from.x + to.x) / 2, (from.y + to.y) / 2);
    }

    final middles = [for (var i = 0; i < 4; i++) middleOf(i)];
    expect(middles.map((m) => m.y).reduce(math.min), middles[0].y,
        reason: 'wall 0 — "top" — is the highest of the four');
    expect(middles.map((m) => m.y).reduce(math.max), middles[2].y,
        reason: 'wall 2 — "bottom" — is the lowest');
    expect(middles.map((m) => m.x).reduce(math.min), middles[3].x,
        reason: 'wall 3 — "left" — is the leftmost');
    expect(middles.map((m) => m.x).reduce(math.max), middles[1].x,
        reason: 'wall 1 — "right" — is the rightmost');
  });

  testWidgets('the sketch is on screen to say which wall is which', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['5010', '3000']);

    // A rectangle is drawn as soon as it has two sizes, and drawn without a
    // diagonal: it has one, and nobody measured it. The number is the
    // hypotenuse the form worked out so that the outline is an outline, and a
    // drawing that hands it back dashed across the room is the calculator
    // telling the user what they measured.
    RoomSketch sketch() => tester.widget<RoomSketch>(find.byType(RoomSketch));
    expect(find.byType(RoomSketch), findsOneWidget);
    expect(sketch().withDiagonal, isFalse);

    // Measured wall by wall it is the one measurement the four walls cannot
    // carry, so it is asked for and it is drawn.
    await turnOnUnevenWalls(tester);
    expect(find.byType(RoomSketch), findsOneWidget);
    expect(sketch().withDiagonal, isTrue);
    // Every measurement is written on the wall it belongs to.
    await fill(tester, ['4980', '3025', '5840'], from: 2);
    expect(find.byType(RoomSketch), findsOneWidget);
    expect(sketch().withDiagonal, isTrue);
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
    final shape = cubit.state.shape! as RoomShape;
    expect(shape.lengthFar, feetInchesToMm(16, 4));
    expect(shape.widthRight, feetInchesToMm(9, 11));
    expect(shape.problem, isNull);
  });
}
