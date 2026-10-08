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

import 'package:floor_calculator/cubit/laying_cubit.dart';
import 'package:floor_calculator/cubit/room_cubit.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/pages/room_parameters_screen.dart';
import 'package:floor_calculator/room_kind.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/widgets/room_sketch.dart';

late RoomCubit cubit;

RoomCubit cubitIn(WidgetTester tester) =>
    BlocProvider.of<RoomCubit>(tester.element(find.byType(MaterialApp)));

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
    await tester.tap(find.byKey(ValueKey(kind)));
    await tester.pumpAndSettle();
  }

  /// A T is measured by the stem it leaves until it is told otherwise. The
  /// tests below that are about the two cuts themselves ask for them back.
  Future<void> cutByCut(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('symmetric-cut')));
    await tester.pumpAndSettle();
  }

  bool nextEnabled(WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Next')).onPressed != null;

  CutCornersRoomShape shapeOf() => cubit.state.shape! as CutCornersRoomShape;

  /// Which way the rows may run, read off the radios the laying section draws.
  ///
  /// The direction was a [SegmentedButton] and is a row of radios now; what the
  /// tests ask of it has not changed — which choices are live, and which one is
  /// filled in.
  bool directionEnabled(WidgetTester tester, Direction direction) =>
      tester
          .widget<Radio<Direction>>(find.byWidgetPredicate(
              (w) => w is Radio<Direction> && w.value == direction))
          .enabled ??
      true;

  Direction? directionChosen(WidgetTester tester) => tester
      .widget<RadioGroup<Direction>>(find.byType(RadioGroup<Direction>))
      .groupValue;

  /// Each shape's own measurements, after the overall 4000 by 3000 — a cut
  /// each, in the order the boxes ask for them.
  const cutsFor = <RoomKind, List<String>>{
    RoomKind.rectangle: [],
    RoomKind.uneven: ['4000', '3000', '5000'],
    RoomKind.chamfer: ['900'],
    RoomKind.chamferPair: ['800', '1000'],
    RoomKind.lShaped: ['1500', '1000'],
    // Measured by the stem it leaves, which is how the T asks until it is told
    // otherwise: how far it runs along the wall, and how far it stands out.
    RoomKind.tShaped: ['1600', '700'],
    RoomKind.zShaped: ['1500', '1200', '1000', '900'],
    // The notch itself: how far it runs along the wall, and how deep.
    RoomKind.uShaped: ['1000', '700'],
  };

  /// Back to the room form from wherever the walk below has got to. The room
  /// screen is the one screen with nowhere to go back to, so the arrow running
  /// out is how the walk knows it has arrived.
  Future<void> backToRoom(WidgetTester tester) async {
    while (find.byType(BackButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
  }

  /// A whole room typed in, through the laminate, as far as the direction
  /// buttons on the laying screen. Starts wherever the form is and ends on the
  /// laying screen.
  Future<void> walkToLaying(WidgetTester tester, RoomKind kind) async {
    await backToRoom(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, kind);
    await fill(tester, cutsFor[kind]!, from: 2);
    expect(nextEnabled(tester), isTrue, reason: '$kind: the room must be valid');
    await tester.tap(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();
    await fill(tester, ['1200', '190', '8']);
    await tester.tap(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();
  }

  testWidgets('every shape is on screen at once, and picking one is one tap',
      (tester) async {
    await pumpForm(tester);
    // The whole reason the dropdown went: a user looking for their own room has
    // to be able to see it without opening anything or scrolling anywhere.
    for (final kind in RoomKind.values) {
      expect(find.byKey(ValueKey(kind)), findsOneWidget,
          reason: '$kind has no tile');
    }
    await fill(tester, ['4000', '3000']);
    for (final kind in RoomKind.values) {
      await pickShape(tester, kind);
      expect(cubit.state.roomKind, kind);
    }
  });

  testWidgets('every shape has a name and an outline of its own', (tester) async {
    // What the compiler used to do. While the shapes were an enum, a switch
    // that missed one was an error; they are classes now, and a 2.18 switch
    // over those proves nothing — so the screen names them down a chain of ifs
    // and draws them out of a table, and neither says a word when a seventh
    // shape is added and forgotten. A forgotten name would be the T's, read
    // out under somebody else's tile; a forgotten outline would fail the
    // lookup where the row is built. Both are caught here.
    await pumpForm(tester);
    final names = <String>{};
    final outlines = <String>{};
    for (final kind in RoomKind.values) {
      final tile = find.byKey(ValueKey(kind));
      names.add(tester
          .widget<Semantics>(
              find.descendant(of: tile, matching: find.byType(Semantics)))
          .properties
          .label!);
      final icon = tester
          .widget<CustomPaint>(
              find.descendant(of: tile, matching: find.byType(CustomPaint)))
          .painter! as RoomKindIcon;
      outlines.add(icon.corners.toString());
    }
    expect(names, hasLength(RoomKind.values.length),
        reason: 'two shapes answer to the same name: $names');
    expect(outlines, hasLength(RoomKind.values.length),
        reason: 'two shapes are drawn as the same room');
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

    // Picking a notched shape does not reach across the form and rewrite the
    // direction, which is an answer given on a screen two pushes away. It used
    // to, while one cubit held the whole form and could; what it bought was
    // that the row plan, the validators and the drawing were never left holding
    // a direction the room cannot be laid in.
    //
    // They still are not, and now by construction rather than by repair: the
    // laying screen reads the direction *through* the room, so a notched one
    // can only ever be laid along or across. See `LayingInputs.direction`, and
    // the laying-screen test that holds 45° out of reach in all three notched
    // rooms. All this screen owes is the room itself.
    final laying = BlocProvider.of<LayingCubit>(
        tester.element(find.byType(MaterialApp)));
    laying.setDirection(Direction.diagonal);
    await tester.pumpAndSettle();
    await pickShape(tester, RoomKind.tShaped);
    expect(cubit.state.shape!.takesDiagonal, isFalse);
    expect(laying.state.direction, Direction.diagonal,
        reason: 'the answer is kept, so unnotching the room gives it back');

    await pickShape(tester, RoomKind.chamfer);
    expect(cubit.state.shape!.takesDiagonal, isTrue,
        reason: 'and a convex room has it back without being asked twice');
  });

  testWidgets('45° is offered in every room that can take it, and in no other',
      (tester) async {
    // Which rooms those are is the outline's answer, not the tile's. The screen
    // used to ask whether the room was specifically an L — true while the L was
    // the only shape with a square cut, and still being asked after the T and
    // the Z arrived. In those two the segment stayed live, and pressing it took
    // the user to a calculation that came back with no variants and no reason
    // given, while the same press in an L was refused on the spot with words.
    //
    // Every shape is walked, so the next one added cannot quietly land on the
    // wrong side of this.
    await pumpForm(tester);
    for (final kind in RoomKind.values) {
      await walkToLaying(tester, kind);
      final notched = kind.cutKind == CornerCut.notch;
      expect(directionEnabled(tester, Direction.diagonal), !notched, reason: '$kind');
      // A greyed button on a phone has no tooltip to explain itself, so it says
      // why on the screen or not at all — and says it once. The room with a
      // notch in a wall takes one straight direction and so no diagonal either,
      // and the line that says the first has already said the second.
      expect(find.textContaining('Diagonal laying is not supported'),
          notched && !kind.isWallNotch ? findsOneWidget : findsNothing,
          reason: '$kind');
      expect(find.textContaining('only be laid across that wall'),
          kind.isWallNotch ? findsOneWidget : findsNothing, reason: '$kind');
    }
  });

  testWidgets('a T stands on a wall, and the wall is picked on the sketch',
      (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.tShaped);
    await cutByCut(tester);

    // Two shoulders and a depth each on top of the overall size: six boxes.
    expect(find.byType(TextField), findsNWidgets(6));
    expect(cubit.state.cutWall, RoomWall.near);

    await fill(tester, ['900', '1100', '800', '600'], from: 2);
    final shape = shapeOf();
    expect(shape.cut, CornerCut.notch);
    expect(shape.cuts.keys.toSet(), {RoomCorner.nearLeft, RoomCorner.nearRight});
    expect(shape.cuts[RoomCorner.nearLeft], isNotNull);
    expect(shape.cuts[RoomCorner.nearLeft]!.along, 900);
    expect(shape.cuts[RoomCorner.nearRight]!.along, 1100,
        reason: 'the two shoulders are their own numbers — a stem is rarely centred');
    expect(shape.cuts[RoomCorner.nearLeft]!.across, 800);
    expect(shape.cuts[RoomCorner.nearRight]!.across, 600,
        reason: 'a depth each: a riser and a cupboard on one wall are not the '
            'same depth, and the form used to make the user pick which to get wrong');
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
      final depths = wall.runsAlongLength
          ? moved.cuts.values.map((c) => c.across)
          : moved.cuts.values.map((c) => c.along);
      expect(shoulders.toSet(), {900, 1100}, reason: '$wall');
      expect(depths.toSet(), {800, 600},
          reason: 'the depths turn with the wall too: $wall');
      expect(moved.problem, isNull, reason: '$wall');
    }

    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('a T is measured by the stem it leaves until it is told otherwise',
      (tester) async {
    // A room with an alcove comes off a tape as the alcove: the stem is a thing
    // in the room and the two cuts either side of it are what is not. Asked for
    // that way the T is two numbers rather than four, and the cuts are worked
    // out — which is also the symmetry most of these rooms actually have, a
    // chimney breast or a doorway recess being centred on its wall.
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.tShaped);
    expect(cubit.state.symmetricCut, isTrue, reason: 'on until it is turned off');
    expect(find.byType(TextField), findsNWidgets(4),
        reason: 'the overall size and the stem, and nothing else');
    expect(find.text('Stem length (mm)'), findsOneWidget);
    expect(find.text('Stem width (mm)'), findsOneWidget);

    await fill(tester, ['1600', '700'], from: 2);
    final shape = shapeOf();
    expect(shape.cuts.keys.toSet(), {RoomCorner.nearLeft, RoomCorner.nearRight});
    // 4000 less the 1600 the stem takes, halved.
    expect(shape.cuts.values.map((c) => c.along).toSet(), {1200});
    expect(shape.cuts.values.map((c) => c.across).toSet(), {700});
    expect(shape.problem, isNull);
    expect(nextEnabled(tester), isTrue);

    // The stem turns with the wall, and so do the two words for it: what runs
    // along a side wall is the room's width.
    await tester.tap(find.byKey(const ValueKey('cut-wall-left')));
    await tester.pumpAndSettle();
    expect(find.text('Stem width (mm)'), findsOneWidget);
    expect(find.text('Stem length (mm)'), findsOneWidget);
    final turned = shapeOf();
    expect(turned.cuts.keys.toSet(), {RoomCorner.nearLeft, RoomCorner.farLeft});
    // 3000 across now, less the same 1600.
    expect(turned.cuts.values.map((c) => c.across).toSet(), {700});
    expect(turned.cuts.values.map((c) => c.along).toSet(), {700});

    // And turning it off hands back the four boxes with what was in them.
    await cutByCut(tester);
    expect(find.byType(TextField), findsNWidgets(6));
    expect(cubit.state.midSpan, 1600,
        reason: 'the stem is kept, so turning the symmetry back on finds it');
  });

  testWidgets('a T left with one depth is the symmetrical T it always was',
      (tester) async {
    // The second depth is a box of its own, so a user who had a symmetrical T
    // has a box they did not have before. Until they fill it the sketch must
    // still draw the room they typed rather than nothing — which is what the
    // fallback in the shape is for, and why a half-filled form is still a room.
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.tShaped);
    await cutByCut(tester);
    await fill(tester, ['900', '1100', '800'], from: 2);

    final shape = shapeOf();
    expect(shape.cuts[RoomCorner.nearLeft]!.across, 800);
    expect(shape.cuts[RoomCorner.nearRight]!.across, 800,
        reason: 'the second depth left blank is the first one again');
    expect(shape.problem, isNull);
    expect(nextEnabled(tester), isFalse,
        reason: 'a box nobody has typed into is a measurement nobody has taken');
  });

  testWidgets('two cuts may not eat the wall they share', (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.tShaped);
    await cutByCut(tester);
    await fill(tester, ['1200', '1200', '800', '800'], from: 2);
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

  testWidgets('a Z is two cuts across the room, picked by either of them',
      (tester) async {
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.zShaped);

    // Two cuts measured in their own right — a length and a width each — on top
    // of the overall size: six boxes. No shoulders, because the two share no
    // wall to be measured off.
    expect(find.byType(TextField), findsNWidgets(6));
    await fill(tester, ['1500', '1200', '1000', '900'], from: 2);

    final shape = shapeOf();
    expect(shape.cut, CornerCut.notch);
    // The corner the sketch points at, and the one across the room from it.
    expect(shape.cuts.keys.toSet(), {RoomCorner.farRight, RoomCorner.nearLeft});
    // Cut 1 is the left-hand one on the drawing and cut 2 the right-hand one.
    // The sketch points at the far right here, so the first pair of boxes
    // describes the cut across the room from it: the numbering follows the
    // drawing and not which of the two was tapped.
    expect(shape.cuts[RoomCorner.nearLeft]!.along, 1500);
    expect(shape.cuts[RoomCorner.nearLeft]!.across, 1000);
    expect(shape.cuts[RoomCorner.farRight]!.along, 1200);
    expect(shape.cuts[RoomCorner.farRight]!.across, 900);
    expect(shape.corners().length, 8);
    expect(reflexCorners(shape.corners()).length, 2);
    expect(shape.problem, isNull);
    expect(shape.takesDiagonal, isFalse,
        reason: 'a 45° strip crosses an outline that turns back on itself twice');
    expect(nextEnabled(tester), isTrue);

    // Tapping a corner moves the whole pair: the tapped corner is cut and the
    // other follows across the room. Four taps, two rooms — which is what a
    // diagonal pair is.
    //
    // And through all four, cut 1 stays the left one and keeps its numbers. The
    // pair straddles the room, so one of its two corners is always on the left;
    // the boxes are read down the screen beside the drawing, and a "cut 1" that
    // changed sides when the pair was moved would have the user typing into the
    // box for the other end of the floor.
    for (final corner in RoomCorner.values) {
      await tester.tap(find.byKey(ValueKey('cut-corner-${corner.name}')));
      await tester.pumpAndSettle();
      final moved = shapeOf();
      expect(moved.cuts.keys.toSet(), {corner, corner.opposite}, reason: '$corner');
      final left = corner.leftOfPair;
      expect(left.isRight, isFalse, reason: '$corner');
      expect(moved.cuts[left]!.along, 1500, reason: '$corner');
      expect(moved.cuts[left]!.across, 1000, reason: '$corner');
      expect(moved.cuts[left.opposite]!.along, 1200, reason: '$corner');
      expect(moved.cuts[left.opposite]!.across, 900, reason: '$corner');
      expect(moved.problem, isNull, reason: '$corner');
    }

    // So the two taps that name one pair name one room. Tapping the far end of
    // a pair already in place used to swap its two cuts over; now it is the
    // no-op it looks like.
    await tester.tap(find.byKey(const ValueKey('cut-corner-nearLeft')));
    await tester.pumpAndSettle();
    final fromLeft = shapeOf().corners();
    await tester.tap(find.byKey(const ValueKey('cut-corner-farRight')));
    await tester.pumpAndSettle();
    expect(shapeOf().corners(), fromLeft);
  });

  testWidgets('the caption says what tapping the sketch will do, shape by shape',
      (tester) async {
    // What the tap does is not the same in all six: a lone cut names the corner
    // it is in, a pair across the room is named by either of its two, a pair on
    // a wall is named by the wall. One line for all of them told two thirds of
    // the users to do something the drawing would not let them.
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    const captions = {
      RoomKind.chamfer: 'Tap the corner that is cut away',
      RoomKind.lShaped: 'Tap the corner that is notched',
      RoomKind.zShaped: 'Tap a corner to move the notches',
      RoomKind.chamferPair: 'Tap a wall to move the cuts',
      RoomKind.tShaped: 'Tap the wall the stem stands on',
      RoomKind.uShaped: 'Tap the wall the notch is in',
    };
    for (final entry in captions.entries) {
      await pickShape(tester, entry.key);
      expect(find.text(entry.value), findsOneWidget, reason: '${entry.key}');
      // And no other shape's line is on the card beside it.
      for (final other in captions.values) {
        if (other == entry.value) continue;
        expect(find.text(other), findsNothing, reason: '${entry.key} also says "$other"');
      }
    }
    // A rectangle has nothing to tap and says nothing.
    await pickShape(tester, RoomKind.rectangle);
    for (final line in captions.values) {
      expect(find.text(line), findsNothing);
    }
  });

  testWidgets('a chamfer pair is named by which leg is which on the drawing',
      (tester) async {
    // "Cut 1" and "Cut 2" named nothing a user could point at: the wall the
    // pair stands on is chosen by tapping, so turning it onto another wall left
    // the numbers naming the legs the other way round without saying so.
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.chamferPair);
    // Measured, because a leg nobody has typed lights no wall: the sketch draws
    // it as a guess and has no number to point at.
    await fill(tester, ['800', '500'], from: 2);

    Future<Set<int>> litBy(String label) async {
      await tester.tap(
          find.ancestor(of: find.text(label), matching: find.byType(TextField)));
      await tester.pumpAndSettle();
      return tester.widget<RoomSketch>(find.byType(RoomSketch)).litWalls;
    }

    // On the near wall the pair runs left to right.
    expect(await litBy('Left cut (mm)'), isNotEmpty);
    expect(await litBy('Right cut (mm)'), isNotEmpty);
    expect(find.text('Top cut (mm)'), findsNothing);

    // Turned onto a side wall, where left and right mean nothing, the same two
    // boxes say which end of it they are instead.
    await tester.tap(find.byKey(const ValueKey('cut-wall-left')));
    await tester.pumpAndSettle();
    expect(find.text('Left cut (mm)'), findsNothing);
    expect(await litBy('Top cut (mm)'), isNotEmpty);
    expect(await litBy('Bottom cut (mm)'), isNotEmpty);

    // The lone chamfer has one leg and so says only what it is.
    await pickShape(tester, RoomKind.chamfer);
    expect(find.text('Cut length (mm)'), findsOneWidget);
  });

  testWidgets('a T and a Z ask for the same two measurements by the same names',
      (tester) async {
    // A cut has a reach along the wall and a depth into the room whether its
    // pair stands on one wall or straddles the room, and the screen used to
    // have two sets of words for them — "Notch 1" against "Notch 1 length",
    // "Notch 1 depth" against "Notch 1 width" — which left the user working out
    // whether the two shapes were being asked different questions.
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);

    const asked = [
      'Notch 1 length (mm)',
      'Notch 2 length (mm)',
      'Notch 1 width (mm)',
      'Notch 2 width (mm)',
    ];
    for (final kind in [RoomKind.tShaped, RoomKind.zShaped]) {
      await pickShape(tester, kind);
      if (kind == RoomKind.tShaped) await cutByCut(tester);
      for (final label in asked) {
        expect(find.text(label), findsOneWidget, reason: '$kind: $label');
      }
    }
  });

  testWidgets('a notch called a length is the measurement drawn along the room',
      (tester) async {
    // The pair's reach runs along the wall it stands on, and that wall turns.
    // Called "length" whatever the wall, it named the room's length on the near
    // and far walls and its width on the other two — a box saying "length" next
    // to a number drawn up and down the page.
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.tShaped);
    await cutByCut(tester);
    await fill(tester, ['900', '1100', '800', '600'], from: 2);

    Future<void> cursorInto(String label) async {
      await tester.tap(
          find.ancestor(of: find.text(label), matching: find.byType(TextField)));
      await tester.pumpAndSettle();
    }

    /// Which way the walls this box lights up run on the drawing.
    Future<Set<bool>> drawnAcross(String label) async {
      await cursorInto(label);
      final corners = cubit.state.shape!.corners();
      final lit = tester.widget<RoomSketch>(find.byType(RoomSketch)).litWalls;
      expect(lit, isNotEmpty, reason: '"$label" lights no wall');
      return {
        for (final wall in lit)
          (corners[wall].x - corners[(wall + 1) % corners.length].x).abs() < 0.5
      };
    }

    for (final wall in RoomWall.values) {
      await tester.tap(find.byKey(ValueKey('cut-wall-${wall.name}')));
      await tester.pumpAndSettle();
      for (var i = 1; i <= 2; i++) {
        expect(await drawnAcross('Notch $i length (mm)'), {false},
            reason: '$wall: notch $i\'s length is drawn across the page');
        expect(await drawnAcross('Notch $i width (mm)'), {true},
            reason: '$wall: notch $i\'s width is drawn up and down it');
      }
    }
  });

  testWidgets('two cuts across the room may not reach each other', (tester) async {
    // Neither box bounds the other, because either one of them may be the deep
    // one — 4000 less the smallest room there is leaves 3500 for a cut, and both
    // cuts are allowed all of it as long as the other one gets out of the way
    // along the *other* axis. They only actually meet when both pairs of numbers
    // overlap at once, and that is the only thing refused.
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.zShaped);

    await fill(tester, ['3400', '3400', '1000', '1000'], from: 2);
    expect(cubit.state.shape!.problem, isNull,
        reason: 'past each other along the length, clear of each other across it');
    expect(nextEnabled(tester), isTrue);

    await fill(tester, ['1800', '1800', '1300', '1300'], from: 2);
    expect(cubit.state.shape!.problem, RoomProblem.cutsOverlap);
    expect(find.text('The notches overlap each other'), findsOneWidget);
    expect(nextEnabled(tester), isFalse);

    // 3000 less the 500 mm that is the smallest room there is leaves 2500 across
    // for the two of them, and 1300 beside 1100 is inside it again.
    await fill(tester, ['1100'], from: 5);
    expect(cubit.state.shape!.problem, isNull);
    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('a notch in a wall is the notch itself, until it is told otherwise',
      (tester) async {
    // The same reading a T gets: the riser is a thing in the room and the wall
    // beside it is what is left, so that is what the tape measures. Two boxes
    // rather than three, and the notch is centred.
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.uShaped);
    expect(cubit.state.symmetricCut, isTrue);
    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.text('Notch length (mm)'), findsOneWidget);
    expect(find.text('Notch width (mm)'), findsOneWidget);

    await fill(tester, ['1000', '700'], from: 2);
    final notch = cubit.state.shape! as WallNotchRoomShape;
    expect(notch.notchWidth, 1000, reason: 'the notch is what was typed');
    expect(notch.offsetFirst, 1500, reason: '4000 less the notch, halved');
    expect(notch.offsetSecond, 1500);
    expect(notch.depth, 700);
    expect(notch.problem, isNull);
    expect(nextEnabled(tester), isTrue);

    // And the two words turn with the wall, as they do everywhere else: what
    // runs along a side wall is the room's width.
    await tester.tap(find.byKey(const ValueKey('cut-wall-left')));
    await tester.pumpAndSettle();
    expect(find.text('Notch width (mm)'), findsOneWidget);
    expect(find.text('Notch length (mm)'), findsOneWidget);
    final turned = cubit.state.shape! as WallNotchRoomShape;
    expect(turned.notchWidth, 1000);
    expect(turned.offsetFirst, 1000, reason: '3000 across now, less the notch, halved');
  });

  testWidgets('a notch off the middle of its wall is measured by its two legs',
      (tester) async {
    // The П is a crossbar and two legs, and off centre the legs are what a tape
    // reads: one is longer than the other and that is the whole of what makes
    // the notch off centre. The notch between them is what is left.
    //
    // One width for the pair and not one each, which is the shape itself
    // talking: both legs stand on the one crossbar, so how far they come out is
    // how deep the notch is, and there is only one of it.
    await pumpForm(tester);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.uShaped);
    await cutByCut(tester);

    expect(find.byType(TextField), findsNWidgets(5));
    expect(find.text('Stem length 1 (mm)'), findsOneWidget);
    expect(find.text('Stem length 2 (mm)'), findsOneWidget);
    expect(find.text('Stem width (mm)'), findsOneWidget);
    expect(find.text('Stem width 1 (mm)'), findsNothing,
        reason: 'two legs on one crossbar come out the same far');

    WallNotchRoomShape shapeOf() => cubit.state.shape! as WallNotchRoomShape;
    await fill(tester, ['1200', '1800', '700'], from: 2);
    expect(shapeOf().wall, RoomWall.near);
    expect(shapeOf().offsetFirst, 1200);
    expect(shapeOf().offsetSecond, 1800);
    expect(shapeOf().notchWidth, 1000, reason: '4000 less the two legs');
    expect(shapeOf().depth, 700);
    expect(shapeOf().corners().length, 8);
    expect(reflexCorners(shapeOf().corners()).length, 2);
    expect(shapeOf().problem, isNull);
    expect(nextEnabled(tester), isTrue);
    expect(find.text('Tap the wall the notch is in'), findsOneWidget);

    // The legs follow the wall round, and so do the words for them: what runs
    // along a side wall is the room's width.
    await tester.tap(find.byKey(const ValueKey('cut-wall-left')));
    await tester.pumpAndSettle();
    expect(find.text('Stem width 1 (mm)'), findsOneWidget);
    expect(find.text('Stem length (mm)'), findsOneWidget);
    expect(cubit.state.cutWall, RoomWall.left);
    expect(shapeOf().offsetFirst, 1200);
    expect(shapeOf().notchWidth, 0, reason: '3000 of width does not hold 1200 and 1800');
    expect(shapeOf().problem, isNotNull);
  });

  testWidgets('a notch in a wall is laid across it and no other way',
      (tester) async {
    // The one room offered in a single direction. A row running along the
    // notched wall is parted in two by the notch, and a row in two is a thing
    // the engine has no way to say — so that direction is out of reach rather
    // than wrong, and which one it is follows the wall the notch is in.
    await pumpForm(tester);
    for (final wall in [RoomWall.near, RoomWall.left]) {
      await backToRoom(tester);
      await fill(tester, ['4000', '3000']);
      await pickShape(tester, RoomKind.uShaped);
      if (cubit.state.cutWall != wall) {
        await tester.tap(find.byKey(ValueKey('cut-wall-${wall.name}')));
        await tester.pumpAndSettle();
      }
      // The notch itself and its depth: the room asks that way round by default.
      await fill(tester, ['1000', '600'], from: 2);
      expect(nextEnabled(tester), isTrue, reason: '$wall');
      await tester.tap(find.widgetWithText(TextButton, 'Next'));
      await tester.pumpAndSettle();
      await fill(tester, ['1200', '190', '8']);
      await tester.tap(find.widgetWithText(TextButton, 'Next'));
      await tester.pumpAndSettle();

      // Across the notched wall, never along it, and never at 45°.
      expect(directionEnabled(tester, Direction.length), !wall.runsAlongLength,
          reason: '$wall');
      expect(directionEnabled(tester, Direction.width), wall.runsAlongLength,
          reason: '$wall');
      expect(directionEnabled(tester, Direction.diagonal), isFalse, reason: '$wall');
      expect(directionChosen(tester),
          wall.runsAlongLength ? Direction.width : Direction.length,
          reason: '$wall: the one direction there is, already chosen');
      expect(find.textContaining('only be laid across that wall'), findsOneWidget,
          reason: '$wall: a greyed button says why');
      expect(find.textContaining('Diagonal laying is not supported'), findsNothing,
          reason: '$wall: and says it once — the line above has already ruled '
              'out the diagonal along with everything but the one direction');
    }
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

  testWidgets('a room too small for any cut says so instead of falling over',
      (tester) async {
    // The smallest room the form takes is 500 mm across, and a cut needs 100 mm
    // of its own plus 500 mm of floor beside it — so there are rooms it accepts
    // that no cut fits into, and in those the ceiling on a cut lands below its
    // floor. The drawing still has to be drawn while the user works that out.
    await pumpForm(tester);
    await fill(tester, ['500', '500']);
    for (final kind in RoomKind.values.where((k) => k.isCut)) {
      await pickShape(tester, kind);
      expect(cubit.state.shape!.problem, isNotNull, reason: '$kind');
      expect(find.text('The notch leaves no room'), findsOneWidget, reason: '$kind');
      expect(nextEnabled(tester), isFalse, reason: '$kind');
    }

    // And the other way round: the shape first, the room typed down to nothing
    // after it.
    await pickShape(tester, RoomKind.rectangle);
    await fill(tester, ['4000', '3000']);
    await pickShape(tester, RoomKind.lShaped);
    await fill(tester, ['1500', '1000'], from: 2);
    expect(nextEnabled(tester), isTrue);
    await fill(tester, ['500', '500']);
    expect(cubit.state.shape!.problem, isNotNull);
    expect(nextEnabled(tester), isFalse);
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
