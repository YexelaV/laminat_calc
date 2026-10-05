// The shapes a room can be cut into, from the form's side.
//
// test/l_shape_form_test.dart covers the one with a single square cut, which
// came first and whose boxes the rest are modelled on. What is new here is a
// cut that is not square and a pair of cuts that is not a corner:
//
//   * a chamfer is offered at 45° and nothing else, so it is one number and
//     not two, and the shape it makes is convex — which is why it is the one
//     cut shape that keeps the 45° laying direction;
//   * a pair stands on a *wall*, so what the sketch asks for is a wall and the
//     form asks for two shoulders and a depth.
//
// These are fixed shapes rather than a starting point: tapping moves the cuts
// about, it never adds or removes one, and the name on the tile is always the
// shape on the sketch.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/widgets/room_sketch.dart';

late CalculateCubit cubit;

CalculateCubit cubitIn(WidgetTester tester) =>
    BlocProvider.of<CalculateCubit>(tester.element(find.byType(MaterialApp)));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpForm(WidgetTester tester,
      {MeasurementSystem system = MeasurementSystem.metric}) async {
    tester.view.physicalSize = const Size(560, 2600);
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

  Future<void> pickShape(WidgetTester tester, RoomKind kind) async {
    await tester.tap(find.byKey(ValueKey('shape-${kind.name}')));
    await tester.pumpAndSettle();
  }

  bool nextEnabled(WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Next')).onPressed != null;

  CutCornersRoomShape shapeOf() => cubit.state.shape! as CutCornersRoomShape;

  testWidgets('every shape is on screen at once, and picking one is one tap',
      (tester) async {
    await pumpForm(tester);
    // The whole reason the dropdown went: a user looking for their own room has
    // to be able to see it without opening anything or scrolling anywhere.
    for (final kind in RoomKind.values) {
      expect(find.byKey(ValueKey('shape-${kind.name}')), findsOneWidget,
          reason: '$kind has no tile');
    }
    await fill(tester, ['4000', '3000']);
    for (final kind in RoomKind.values) {
      await pickShape(tester, kind);
      expect(cubit.state.roomKind, kind);
    }
  });

  testWidgets('a chamfer is one number, and it is cut at 45°', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.chamfer);

    // Three boxes, not four: the two overall sizes and the one leg.
    expect(find.byType(TextField), findsNWidgets(3));

    await fill(tester, ['900'], from: 2);
    final shape = shapeOf();
    expect(shape.cut, CornerCut.chamfer);
    expect(shape.cuts.length, 1);
    final only = shape.cuts.values.single;
    // The number typed is the wall the cut leaves, not the bite it takes out
    // of each side: once the corner is gone there is no corner to measure the
    // legs from. The legs are that wall over root two, and equal, which is
    // what 45° means.
    expect(only.measuredWall, 900);
    expect(only.along, 636);
    expect(only.across, 636);
    // And the drawing says back exactly what was typed. Squaring the rounded
    // legs up again would answer 899 here, and a drawing that disagrees with
    // the box above it by a millimetre is a drawing nobody trusts.
    expect(shape.wallLengths(), contains(900));
    expect(shape.corners().length, 5);
    expect(isConvexPolygon(shape.corners()), isTrue);
    expect(shape.problem, isNull);

    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('a chamfered room keeps the 45° layout and a notched one does not',
      (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);

    await pickShape(tester, RoomKind.chamfer);
    expect(shapeOf().takesDiagonal, isTrue,
        reason: 'it is convex, so a 45° strip crosses it once');

    // Turning the diagonal on and then picking a notched shape has to turn it
    // back off, or the row plan, the validators and the drawing are left
    // holding a direction the room cannot be laid in.
    cubit.setDirection(Direction.diagonal);
    await tester.pumpAndSettle();
    await pickShape(tester, RoomKind.tShaped);
    expect(cubit.state.direction, isNot(Direction.diagonal));
    expect(cubit.state.shape!.takesDiagonal, isFalse);

    // And back to a chamfer leaves the direction alone: the user who had it
    // turned off turns it back on, which is the quieter of the two surprises.
    await pickShape(tester, RoomKind.chamfer);
    expect(cubit.state.direction, Direction.length);
  });

  testWidgets('a T stands on a wall, and the wall is picked on the sketch',
      (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.tShaped);

    // Two shoulders and a depth on top of the overall size: five boxes.
    expect(find.byType(TextField), findsNWidgets(5));
    expect(cubit.state.cutWall, RoomWall.near);

    await fill(tester, ['900', '1100', '800'], from: 2);
    final shape = shapeOf();
    expect(shape.cut, CornerCut.notch);
    expect(shape.cuts.keys.toSet(), {RoomCorner.nearLeft, RoomCorner.nearRight});
    expect(shape.cuts[RoomCorner.nearLeft], isNotNull);
    expect(shape.cuts[RoomCorner.nearLeft]!.along, 900);
    expect(shape.cuts[RoomCorner.nearRight]!.along, 1100,
        reason: 'the two shoulders are their own numbers — a stem is rarely centred');
    expect(shape.cuts[RoomCorner.nearLeft]!.across, 800);
    expect(shape.cuts[RoomCorner.nearRight]!.across, 800,
        reason: 'one depth: both cuts stop at the same shoulder line');
    expect(shape.corners().length, 8);
    expect(reflexCorners(shape.corners()).length, 2);
    expect(shape.problem, isNull);

    // Every wall can carry the stem, and the shoulders follow it round: on a
    // side wall they are measured down the width instead of along the length.
    for (final wall in RoomWall.values) {
      await tester.tap(find.byKey(ValueKey('cut-wall-${wall.name}')));
      await tester.pumpAndSettle();
      expect(cubit.state.cutWall, wall);
      final moved = shapeOf();
      expect(moved.cuts.keys.toSet(), wall.corners.toSet(),
          reason: 'the cuts are at the two ends of the wall that was tapped');
      final shoulders = wall.runsAlongLength
          ? moved.cuts.values.map((c) => c.along)
          : moved.cuts.values.map((c) => c.across);
      expect(shoulders.toSet(), {900, 1100}, reason: '$wall');
      expect(moved.problem, isNull, reason: '$wall');
    }

    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('two cuts may not eat the wall they share', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.tShaped);
    await fill(tester, ['1200', '1200', '800'], from: 2);
    expect(nextEnabled(tester), isTrue);

    // 4000 less the 500 mm that is the smallest room there is leaves 3500 for
    // the two shoulders between them. One of 2400 beside one of 1200 is 100 too
    // much, and the field says so rather than the result screen coming back
    // empty.
    await fill(tester, ['2400'], from: 2);
    expect(nextEnabled(tester), isFalse);
    await fill(tester, ['2300'], from: 2);
    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('a pair of chamfers is two numbers and stays convex', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.chamferPair);

    // Two legs and no depth: a 45° cut's depth is its leg.
    expect(find.byType(TextField), findsNWidgets(4));
    await fill(tester, ['800', '1000'], from: 2);
    final shape = shapeOf();
    expect(shape.cut, CornerCut.chamfer);
    expect(shape.cuts.length, 2);
    expect(shape.cuts[RoomCorner.nearLeft]!.measuredWall, 800);
    expect(shape.cuts[RoomCorner.nearLeft]!.along, 566);
    expect(shape.cuts[RoomCorner.nearLeft]!.across, 566);
    expect(shape.cuts[RoomCorner.nearRight]!.measuredWall, 1000);
    expect(shape.cuts[RoomCorner.nearRight]!.along, 707);
    expect(shape.cuts[RoomCorner.nearRight]!.across, 707);
    expect(shape.wallLengths(), containsAll([800, 1000]));
    expect(shape.corners().length, 6);
    expect(isConvexPolygon(shape.corners()), isTrue);
    expect(shape.takesDiagonal, isTrue);
  });

  testWidgets('a wall a cut shortened is a question mark until the cut is typed',
      (tester) async {
    // The cut's own wall is the obvious guess, but not the only one: the two
    // walls it was taken out of are shorter by it, and until it is typed their
    // numbers are the calculator's arithmetic on its own assumption.
    await pumpForm(tester);
    // The shape first, so nothing is prefilled.
    await pickShape(tester, RoomKind.chamfer);
    await fill(tester, ['2000', '3000']);

    RoomSketch sketch() => tester.widget<RoomSketch>(find.byType(RoomSketch));
    final walls = shapeOf().wallLengths();
    // Three of the five: the cut, and the two walls it shortened. The other
    // two are the sizes that were typed.
    expect(sketch().unknownWalls.length, 3);
    final known = [
      for (var i = 0; i < walls.length; i++)
        if (!sketch().unknownWalls.contains(i)) walls[i]
    ];
    expect(known..sort(), [2000, 3000]);

    await fill(tester, ['700'], from: 2);
    expect(sketch().unknownWalls, isEmpty,
        reason: 'once the cut is typed nothing on the drawing is a guess');
  });

  testWidgets('an overall size lights the wall that is that size, and no other',
      (tester) async {
    // A cut shortens the wall opposite the one it leaves whole. That shortened
    // wall is a number the room worked out, not one anybody typed, so the box
    // above it owns the full wall and only the full wall.
    await pumpForm(tester);
    await fill(tester, ['10000', '3000']);
    await pickShape(tester, RoomKind.chamfer);
    await fill(tester, ['1000'], from: 2);

    RoomSketch sketch() => tester.widget<RoomSketch>(find.byType(RoomSketch));
    final walls = shapeOf().wallLengths();

    Future<void> cursorInto(int box) async {
      await tester.tap(find.byType(TextField).at(box));
      await tester.pumpAndSettle();
    }

    await cursorInto(0);
    expect(sketch().litWalls.length, 1, reason: 'one wall is the overall length');
    expect(walls[sketch().litWalls.single], 10000);

    await cursorInto(1);
    expect(sketch().litWalls.length, 1, reason: 'one wall is the overall width');
    expect(walls[sketch().litWalls.single], 3000);

    await cursorInto(2);
    expect(sketch().litWalls.length, 1, reason: 'the cut leaves one wall');
    expect(walls[sketch().litWalls.single], 1000,
        reason: 'and it is the length that was typed, not its legs squared up');
  });

  testWidgets('each shape keeps its own numbers while the others are tried',
      (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);

    await pickShape(tester, RoomKind.lShaped);
    await fill(tester, ['1500', '1000'], from: 2);
    await pickShape(tester, RoomKind.chamfer);
    await fill(tester, ['700'], from: 2);
    await pickShape(tester, RoomKind.rectangle);
    expect(cubit.state.shape!.isRectangular, isTrue,
        reason: 'the cuts are off screen and out of the room');

    // And the overall size is the one room every shape shares, so it never has
    // to be typed twice.
    await pickShape(tester, RoomKind.tShaped);
    final shape = shapeOf();
    expect(shape.length, 4000);
    expect(shape.width, 3000);
  });

  testWidgets('a cut left unmeasured is still unmeasured on the way back',
      (tester) async {
    // Picking the shape never fills a box; nor does picking it a second time.
    // The form used to hand over a cut a third of the room deep on the way in,
    // and it came back on every return trip over a box left blank.
    await pumpForm(tester);
    await pickShape(tester, RoomKind.lShaped);
    await fill(tester, ['4000', '3000']);
    expect(cubit.state.notchLength, isNull);
    expect(nextEnabled(tester), isFalse);

    await pickShape(tester, RoomKind.rectangle);
    await pickShape(tester, RoomKind.lShaped);

    expect(cubit.state.notchLength, isNull);
    expect(cubit.state.notchWidth, isNull);
    for (final i in [2, 3]) {
      expect(tester.widget<TextField>(find.byType(TextField).at(i)).controller!.text, isEmpty,
          reason: 'box $i was filled in by the round trip');
    }
    expect(nextEnabled(tester), isFalse,
        reason: 'the cut is still a measurement nobody has taken');
  });

  testWidgets('in feet and inches a cut keeps its own pair of boxes',
      (tester) async {
    await pumpForm(tester, system: MeasurementSystem.imperial);
    // Feet and inches for the length and the width, so four boxes before the
    // shape is even chosen.
    await fill(tester, ['13', '0', '9', '0']);
    await pickShape(tester, RoomKind.chamfer);

    // The one measurement adds a pair of boxes rather than one.
    await fill(tester, ['2', '11.5'], from: 4);
    final shape = shapeOf();
    final cut = shape.cuts.values.single;
    expect(cut.measuredWall, feetInchesToMm(2, 11.5));
    expect(cut.along, cut.across, reason: '45° either way');
    expect(shape.wallLengths(), contains(feetInchesToMm(2, 11.5)));
    expect(shape.problem, isNull);
  });
}
