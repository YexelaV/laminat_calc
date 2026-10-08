// The room as five measurements, and the outline they close into.
//
// The load-bearing claim is that nothing is assumed: the five numbers go in,
// and measuring the outline that comes out gives the same five numbers back.
// Everything else here guards the one case that must not move — a rectangle,
// which is what every room was before this existed and what every golden image
// in the suite is still drawn from.
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/room_shape.dart';

double _side(List<Point<double>> corners, int from, int to) =>
    corners[from].distanceTo(corners[to]);

void main() {
  group('the outline the measurements close into', () {
    test('measuring it gives back the numbers it was built from', () {
      const shapes = [
        // A room a tape measure would actually produce: nearly square, off by
        // a centimetre or two in each direction.
        [5010, 4980, 3000, 3025, 5840],
        // The same room measured across the other way, so the diagonal leans
        // the other way too.
        [5010, 4980, 3000, 3025, 5800],
        // Rooms no one would call nearly rectangular, to show the closure is
        // not a small-angle approximation.
        [6000, 4000, 3000, 3500, 6800],
        [3000, 3000, 2000, 2000, 3400],
        [2400, 2600, 5000, 4800, 5300],
      ];
      for (final m in shapes) {
        final shape = RoomShape(
          lengthNear: m[0],
          lengthFar: m[1],
          widthLeft: m[2],
          widthRight: m[3],
          diagonal: m[4],
        );
        expect(shape.problem, isNull, reason: '$m');
        final corners = shape.corners();
        expect(_side(corners, 0, 1), closeTo(m[0], 0.001), reason: '$m: near wall');
        expect(_side(corners, 2, 3), closeTo(m[1], 0.001), reason: '$m: far wall');
        expect(_side(corners, 3, 0), closeTo(m[2], 0.001), reason: '$m: left wall');
        expect(_side(corners, 1, 2), closeTo(m[3], 0.001), reason: '$m: right wall');
        expect(_side(corners, 0, 2), closeTo(m[4], 0.001), reason: '$m: diagonal');
      }
    });

    test('the far corners land on the far side, never folded back', () {
      final shape = RoomShape(
        lengthNear: 5010,
        lengthFar: 4980,
        widthLeft: 3000,
        widthRight: 3025,
        diagonal: 5840,
      );
      final corners = shape.corners();
      // P1 is on the axis and P2, P3 are across the room from it, or the
      // outline has been built inside out.
      expect(corners[0], const Point<double>(0, 0));
      expect(corners[1].y, 0);
      expect(corners[2].y, greaterThan(0));
      expect(corners[3].y, greaterThan(0));
      // P3 is the corner the left wall reaches, so it is the one near the
      // origin; P2 is diagonally opposite.
      expect(corners[3].x, lessThan(corners[2].x));
    });
  });

  group('a rectangle stays exactly a rectangle', () {
    test('its corners are written out, not solved for', () {
      final shape = RoomShape.rectangle(3000, 1200);
      expect(shape.isRectangular, isTrue);
      expect(shape.corners(), [
        const Point<double>(0, 0),
        const Point<double>(3000, 0),
        const Point<double>(3000, 1200),
        const Point<double>(0, 1200),
      ]);
    });

    test('its floor is the rectangle the drawing has always inset to', () {
      for (final room in [
        [3000, 1200],
        [6000, 3000],
        [4200, 2600]
      ]) {
        for (final gap in [0, 10, 12, 50]) {
          final floor = RoomShape.rectangle(room[0], room[1]).floor(gap);
          // Exactly `Rect.fromLTWH(gap, gap, length - 2gap, width - 2gap)`,
          // corner for corner: that rectangle is what the drawing has inset to
          // since before rooms could be anything else, and the general inset
          // has to land on it to the bit.
          final near = gap.toDouble();
          final far = Point<double>((room[0] - gap).toDouble(), (room[1] - gap).toDouble());
          expect(floor, [
            Point<double>(near, near),
            Point<double>(far.x, near),
            far,
            Point<double>(near, far.y),
          ], reason: 'room $room, gap $gap');
        }
      }
    });

    test('the filled-in diagonal is the one that keeps it a rectangle', () {
      // What the form puts in the field when the user has not measured across.
      expect(RoomShape.rectangle(3000, 1200).diagonal,
          RoomShape.rectangleDiagonal(3000, 1200));
      expect(
        RoomShape(
          lengthNear: 3000,
          lengthFar: 3000,
          widthLeft: 1200,
          widthRight: 1200,
          diagonal: RoomShape.rectangleDiagonal(3000, 1200),
        ).isRectangular,
        isTrue,
      );
      // One millimetre out and it is a shape in its own right, laid out by the
      // walk rather than the closed form.
      expect(
        RoomShape(
          lengthNear: 3000,
          lengthFar: 3000,
          widthLeft: 1200,
          widthRight: 1200,
          diagonal: RoomShape.rectangleDiagonal(3000, 1200) + 1,
        ).isRectangular,
        isFalse,
      );
    });
  });

  group('measurements that do not describe a room', () {
    test('a diagonal the walls cannot reach round is rejected', () {
      final low = RoomShape.minDiagonal(
          lengthNear: 5010, lengthFar: 4980, widthLeft: 3000, widthRight: 3025);
      final high = RoomShape.maxDiagonal(
          lengthNear: 5010, lengthFar: 4980, widthLeft: 3000, widthRight: 3025);
      RoomShape at(int d) => RoomShape(
          lengthNear: 5010, lengthFar: 4980, widthLeft: 3000, widthRight: 3025, diagonal: d);

      expect(at(low - 1).problem, RoomProblem.diagonalDoesNotClose);
      expect(at(high + 1).problem, RoomProblem.diagonalDoesNotClose);
      // The bounds themselves are measurements a room can have.
      expect(at(low).problem, isNot(RoomProblem.diagonalDoesNotClose));
      expect(at(high).problem, isNot(RoomProblem.diagonalDoesNotClose));
    });

    test('the bounds are the triangle inequality on both halves of the room', () {
      // The near wall and the right wall meet the diagonal in one triangle, the
      // left and far walls in the other, and the tighter pair wins.
      expect(
        RoomShape.minDiagonal(
            lengthNear: 6000, lengthFar: 3000, widthLeft: 1000, widthRight: 1000),
        math.max((6000 - 1000).abs(), (1000 - 3000).abs()) + 1,
      );
      expect(
        RoomShape.maxDiagonal(
            lengthNear: 6000, lengthFar: 3000, widthLeft: 1000, widthRight: 1000),
        math.min(6000 + 1000, 1000 + 3000) - 1,
      );
    });

    test('a room with a corner folded inwards is rejected', () {
      // The walls close, but the far wall has to bend back past the diagonal
      // to reach: a shape a mistyped digit produces and a tape measure cannot.
      final folded = RoomShape(
        lengthNear: 6000,
        lengthFar: 800,
        widthLeft: 3000,
        widthRight: 3000,
        diagonal: 3300,
      );
      expect(folded.problem, RoomProblem.notConvex);
    });
  });

  group('a room with a corner cut away', () {
    // The room every other test in this group is cut from, and the piece taken
    // out of it. A notch deeper than one plank and wider than one, so that the
    // rows above it, the rows below it and the row across the step are all
    // real rows rather than edge cases.
    const length = 4000;
    const width = 3000;
    const notchLength = 1500;
    const notchWidth = 1000;

    LRoomShape cut(RoomCorner corner) => LRoomShape(
          length: length,
          width: width,
          notchLength: notchLength,
          notchWidth: notchWidth,
          corner: corner,
        );

    test('it has six corners, filling its bounding box but for the cut', () {
      for (final corner in RoomCorner.values) {
        final corners = cut(corner).corners();
        expect(corners.length, 6, reason: '$corner');
        expect(corners.map((p) => p.x).reduce(math.min), 0, reason: '$corner');
        expect(corners.map((p) => p.x).reduce(math.max), length, reason: '$corner');
        expect(corners.map((p) => p.y).reduce(math.min), 0, reason: '$corner');
        expect(corners.map((p) => p.y).reduce(math.max), width, reason: '$corner');
        // Area of the rectangle less the piece taken out of it, read off the
        // outline rather than off the four numbers it was built from.
        expect(_area(corners), length * width - notchLength * notchWidth,
            reason: '$corner');
      }
    });

    test('exactly one corner turns the wrong way, and it is the cut one', () {
      for (final corner in RoomCorner.values) {
        final corners = cut(corner).corners();
        final reflex = reflexCorners(corners);
        expect(reflex.length, 1, reason: '$corner');
        expect(isConvexPolygon(corners), isFalse, reason: '$corner');
      }
    });

    test('each wall is written down at the length the outline gives it', () {
      for (final corner in RoomCorner.values) {
        final shape = cut(corner);
        final corners = shape.corners();
        final walls = shape.wallLengths();
        expect(walls.length, 6, reason: '$corner');
        for (var i = 0; i < 6; i++) {
          expect(_side(corners, i, (i + 1) % 6), closeTo(walls[i], 0.001),
              reason: '$corner: wall $i');
        }
        // The two walls each side of the cut add up to the wall they replace.
        expect(walls.where((w) => w == length - notchLength).length, 1, reason: '$corner');
        expect(walls.where((w) => w == width - notchWidth).length, 1, reason: '$corner');
      }
    });

    test('the cut keeps its size when the floor steps in from the walls', () {
      // An inward offset normally shrinks everything. Here it does not: both
      // walls of the cut move away from it by the gap and both walls opposite
      // move towards it, so the piece missing from the floor is the same piece
      // that is missing from the room, sitting in the corner of the floor's
      // own bounding box. [floor] arrives there the long way round, through
      // [insetPolygon], and has to land on the room one gap smaller — or the
      // drawing cuts planks against a different floor than the one laid.
      for (final corner in RoomCorner.values) {
        for (final gap in [0, 10, 12, 50]) {
          final shape = cut(corner);
          final floor = shape.floor(gap);
          final smaller = LRoomShape(
            length: length - gap * 2,
            width: width - gap * 2,
            notchLength: notchLength,
            notchWidth: notchWidth,
            corner: corner,
          ).corners();
          for (var i = 0; i < 6; i++) {
            expect(floor[i].x, closeTo(smaller[i].x + gap, 1e-9),
                reason: '$corner gap $gap: corner $i');
            expect(floor[i].y, closeTo(smaller[i].y + gap, 1e-9),
                reason: '$corner gap $gap: corner $i');
          }
          // And the piece missing from the floor is the piece missing from the
          // room, undiminished by the offset.
          expect(_area(floor),
              closeTo((length - gap * 2) * (width - gap * 2) - notchLength * notchWidth, 1e-6),
              reason: '$corner gap $gap');
        }
      }
    });

    test('a worked floor, corner for corner', () {
      // The fixture the row and drawing tests are built on, written out so a
      // change to the arithmetic has to be looked at rather than absorbed.
      expect(cut(RoomCorner.farRight).floor(10), [
        const Point<double>(10, 10),
        const Point<double>(3990, 10),
        const Point<double>(3990, 1990),
        const Point<double>(2490, 1990),
        const Point<double>(2490, 2990),
        const Point<double>(10, 2990),
      ]);
    });

    test('a quarter turn leaves it square to the axes, the other way round', () {
      for (final corner in RoomCorner.values) {
        final shape = cut(corner);
        final turned = shape.turned(shape.floor(10));
        for (var i = 0; i < 6; i++) {
          final from = turned[i];
          final to = turned[(i + 1) % 6];
          expect(from.x == to.x || from.y == to.y, isTrue, reason: '$corner: wall $i');
        }
        expect(turned.map((p) => p.x).reduce(math.max) - turned.map((p) => p.x).reduce(math.min),
            closeTo(width - 20, 1e-9),
            reason: '$corner');
        expect(turned.map((p) => p.y).reduce(math.max) - turned.map((p) => p.y).reduce(math.min),
            closeTo(length - 20, 1e-9),
            reason: '$corner');
      }
    });

    test('it is never the rectangle it was cut from', () {
      // [isRectangular] is the gate on every closed form downstream. A room
      // whose four walls read like a rectangle's still is not one.
      expect(cut(RoomCorner.farRight).isRectangular, isFalse);
    });

    test('two rooms that differ anywhere are told apart by their key', () {
      final keys = <String>{};
      for (final corner in RoomCorner.values) {
        keys.add(cut(corner).key);
      }
      keys.add(LRoomShape(
        length: length,
        width: width,
        notchLength: notchLength + 1,
        notchWidth: notchWidth,
        corner: RoomCorner.farRight,
      ).key);
      keys.add(RoomShape.rectangle(length, width).key);
      expect(keys.length, 6);
    });

    test('a cut that is no cut, or leaves no room, is rejected', () {
      LRoomShape sized(int a, int b) => LRoomShape(
            length: length,
            width: width,
            notchLength: a,
            notchWidth: b,
            corner: RoomCorner.farRight,
          );
      expect(sized(0, notchWidth).problem, RoomProblem.notchNotCut);
      expect(sized(notchLength, 0).problem, RoomProblem.notchNotCut);
      expect(sized(MIN_NOTCH_MM - 1, notchWidth).problem, RoomProblem.notchNotCut);
      expect(sized(length, notchWidth).problem, RoomProblem.notchLeavesNoRoom);
      expect(sized(length - LRoomShape.minArmMm + 1, notchWidth).problem,
          RoomProblem.notchLeavesNoRoom);
      expect(sized(notchLength, width).problem, RoomProblem.notchLeavesNoRoom);
      // And the bounds themselves are rooms.
      expect(sized(MIN_NOTCH_MM, MIN_NOTCH_MM).problem, isNull);
      expect(sized(length - LRoomShape.minArmMm, width - LRoomShape.minArmMm).problem, isNull);
    });
  });

  group('a room with several corners cut away', () {
    const length = 4000;
    const width = 3000;

    CutCornersRoomShape shaped(CornerCut cut, Map<RoomCorner, CornerSize> cuts) =>
        CutCornersRoomShape(length: length, width: width, cut: cut, cuts: cuts);

    CornerSize size(int a, int b) => CornerSize(along: a, across: b);

    test('one notch is the L it always was, corner for corner', () {
      // The oracle. [LRoomShape] used to write its six corners and its six
      // walls out by hand, one table per corner; the walk that replaced them
      // has to arrive at the same numbers in the same order, or every golden
      // in the suite is drawing a different room. The old tables are copied
      // here rather than referred to, so that this keeps checking the walk
      // even after nothing else remembers what they said.
      const a = 1500;
      const b = 1000;
      const l = length;
      const w = width;
      const wasCorners = {
        RoomCorner.nearLeft: [[a, 0], [l, 0], [l, w], [0, w], [0, b], [a, b]],
        RoomCorner.nearRight: [[0, 0], [l - a, 0], [l - a, b], [l, b], [l, w], [0, w]],
        RoomCorner.farRight: [[0, 0], [l, 0], [l, w - b], [l - a, w - b], [l - a, w], [0, w]],
        RoomCorner.farLeft: [[0, 0], [l, 0], [l, w], [a, w], [a, w - b], [0, w - b]],
      };
      const wasWalls = {
        RoomCorner.nearLeft: [l - a, w, l, w - b, a, b],
        RoomCorner.nearRight: [l - a, b, a, w - b, l, w],
        RoomCorner.farRight: [l, w - b, a, b, l - a, w],
        RoomCorner.farLeft: [l, w, l - a, b, a, w - b],
      };
      for (final corner in RoomCorner.values) {
        final now = shaped(CornerCut.notch, {corner: size(a, b)});
        expect(now.corners().map((p) => [p.x.round(), p.y.round()]).toList(),
            wasCorners[corner], reason: '$corner');
        expect(now.wallLengths(), wasWalls[corner], reason: '$corner');
      }
    });

    test('a chamfer leaves five corners, and the cut wall is their hypotenuse',
        () {
      final shape = shaped(CornerCut.chamfer, {RoomCorner.farRight: size(900, 1200)});
      expect(shape.corners().length, 5);
      expect(shape.wallLengths().length, 5);
      expect(isConvexPolygon(shape.corners()), isTrue);
      expect(reflexCorners(shape.corners()), isEmpty);
      // 900 by 1200 is a 3-4-5 triangle, so the cut wall is exactly 1500 and
      // the rounding cannot hide a mistake in it.
      expect(shape.wallLengths(), contains(1500));
      expect(_area(shape.corners()),
          closeTo(length * width - 900 * 1200 / 2, 1e-9));
    });

    test('every arrangement of cuts fills its box but for the cuts', () {
      for (final cut in CornerCut.values) {
        // The whole power set, so that nothing passes by being the only case
        // tried. A cut corner is worth one rectangle or half of one.
        for (var mask = 0; mask < 16; mask++) {
          final cuts = <RoomCorner, CornerSize>{};
          var gone = 0.0;
          for (var i = 0; i < 4; i++) {
            if (mask & (1 << i) == 0) continue;
            final a = 600 + i * 100;
            final b = 500 + i * 50;
            cuts[RoomCorner.values[i]] = size(a, b);
            gone += cut == CornerCut.notch ? a * b : a * b / 2;
          }
          final shape = shaped(cut, cuts);
          final corners = shape.corners();
          expect(corners.length, 4 + cuts.length * (cut == CornerCut.notch ? 2 : 1),
              reason: '$cut mask $mask');
          expect(shape.wallLengths().length, corners.length,
              reason: '$cut mask $mask: a wall per corner');
          expect(_area(corners), closeTo(length * width - gone, 1e-9),
              reason: '$cut mask $mask');
          expect(reflexCorners(corners).length,
              cut == CornerCut.notch ? cuts.length : 0,
              reason: '$cut mask $mask: one inside corner per notch');
          expect(shape.problem, isNull, reason: '$cut mask $mask');
        }
      }
    });

    test('every row is one unbroken run, whatever is cut away', () {
      // The load-bearing claim, and the only reason any of these rooms can be
      // laid at all: a cut corner eats into one *end* of a row and never into
      // its middle. Checked against the floor worked out a second way — each
      // cut taken off the bounding box by arithmetic, at every height, with no
      // appeal to [spanAt] — and the two have to agree on a single interval.
      for (final cut in CornerCut.values) {
        for (var mask = 1; mask < 16; mask++) {
          final cuts = <RoomCorner, CornerSize>{};
          for (var i = 0; i < 4; i++) {
            if (mask & (1 << i) == 0) continue;
            cuts[RoomCorner.values[i]] = size(600 + i * 100, 500 + i * 50);
          }
          final polygon = shaped(cut, cuts).corners();
          for (var v = 1.0; v < width; v += 7.3) {
            var lo = 0.0;
            var hi = length.toDouble();
            cuts.forEach((corner, s) {
              // How far this cut reaches in at height v: the whole leg for a
              // notch, and a leg tapering to nothing for a chamfer.
              final near = corner == RoomCorner.nearLeft || corner == RoomCorner.nearRight;
              final depth = near ? v : width - v;
              if (depth >= s.across) return;
              final double reach = cut == CornerCut.notch
                  ? s.along.toDouble()
                  : s.along * (1 - depth / s.across);
              final left = corner == RoomCorner.nearLeft || corner == RoomCorner.farLeft;
              if (left) {
                lo = math.max(lo, reach);
              } else {
                hi = math.min(hi, length - reach);
              }
            });
            final span = spanAt(polygon, v);
            expect(span, isNotNull, reason: '$cut mask $mask at $v');
            expect(span!.lo, closeTo(lo, 1e-9), reason: '$cut mask $mask at $v');
            expect(span.hi, closeTo(hi, 1e-9), reason: '$cut mask $mask at $v');
          }
        }
      }
    });

    test('two cuts on one wall may not eat it between them', () {
      // Each bound is the one a single cut has always had, with the other end
      // of the wall contributing nothing — so the arithmetic the form shows
      // the user does not change when a second cut appears, it only tightens.
      const arm = CutCornersRoomShape.minArmMm;
      CutCornersRoomShape pair(int first, int second) =>
          shaped(CornerCut.notch, {
            RoomCorner.nearLeft: size(first, 800),
            RoomCorner.nearRight: size(second, 800),
          });
      expect(pair(1000, 1000).problem, isNull);
      expect(pair(length - arm, MIN_NOTCH_MM).problem, RoomProblem.notchLeavesNoRoom);
      expect(pair((length - arm) ~/ 2, (length - arm) ~/ 2).problem, isNull);
      expect(pair((length - arm) ~/ 2 + 1, (length - arm) ~/ 2 + 1).problem,
          RoomProblem.notchLeavesNoRoom);
      // The same wall read the other way: two cuts down the left wall.
      expect(
          shaped(CornerCut.notch, {
            RoomCorner.nearLeft: size(800, width - arm),
            RoomCorner.farLeft: size(800, MIN_NOTCH_MM),
          }).problem,
          RoomProblem.notchLeavesNoRoom);
    });

    test('two cuts across the room may not reach each other', () {
      // The pair that shares no wall, and so nothing on either wall bounds it.
      // Each cut is held off the far side of the room exactly as a lone cut is,
      // and two of those reach past one another — but reaching past is not
      // meeting. They take the same floor twice only when they overlap along
      // the length *and* across the width, and that is the only arrangement
      // refused, because any other one is a Z somebody is standing in.
      const arm = CutCornersRoomShape.minArmMm;
      CutCornersRoomShape diagonal(int a1, int b1, int a2, int b2) =>
          shaped(CornerCut.notch, {
            RoomCorner.nearLeft: size(a1, b1),
            RoomCorner.farRight: size(a2, b2),
          });

      expect(diagonal(1000, 800, 1200, 900).problem, isNull);
      // Both pairs of numbers over: the two rectangles share floor.
      expect(diagonal(1800, 1300, 1800, 1300).problem, RoomProblem.cutsOverlap);
      // One pair over and the other exactly at the bound, each way round.
      expect(diagonal(1800, 1250, 1800, 1250).problem, isNull);
      expect(diagonal(1750, 1300, 1750, 1300).problem, isNull);
      // The other diagonal is bounded the same way.
      expect(
          shaped(CornerCut.notch, {
            RoomCorner.nearRight: size(1800, 1300),
            RoomCorner.farLeft: size(1800, 1300),
          }).problem,
          RoomProblem.cutsOverlap);

      // And the far end of what is allowed: two cuts as deep along the room as
      // a lone cut may be, passing each other across it. A long thin Z, and
      // still one unbroken run in every row — which is the whole of why the
      // bound is the pair of sums together rather than either on its own.
      final thin = diagonal(length - arm, 1000, length - arm, 1000);
      expect(thin.problem, isNull);
      expect(thin.corners().length, 8);
      expect(reflexCorners(thin.corners()).length, 2);
      expect(_area(thin.corners()),
          closeTo(length * width - 2 * (length - arm) * 1000, 1e-9));
      for (var v = 1.0; v < width; v += 7.3) {
        final span = spanAt(thin.corners(), v);
        expect(span, isNotNull, reason: 'at $v');
        expect(span!.length, greaterThan(0), reason: 'at $v');
      }
    });

    test('a notch in the middle of a wall is laid one way and not the other',
        () {
      // The whole argument for the shape, and the reason it is offered in one
      // direction only. A piece taken out of a corner eats into one *end* of
      // every row it meets, so the row stays one unbroken run whichever way the
      // rows go. A notch in the middle of a wall eats into the middle of the
      // rows that run along that wall — those come back in two pieces with a
      // hole between them, and a row in two is a thing [RowPlan] cannot hold.
      //
      // 4000 by 3000, a notch 1000 wide and 700 deep in the middle of the near
      // wall, with 1500 of floor to its left and 1500 to its right.
      const room = WallNotchRoomShape(
        length: 4000,
        width: 3000,
        wall: RoomWall.near,
        offsetFirst: 1500,
        offsetSecond: 1500,
        depth: 700,
      );
      expect(room.problem, isNull);
      expect(room.notchWidth, 1000);
      expect(room.corners().length, 8);
      expect(reflexCorners(room.corners()).length, 2);
      expect(room.wallLengths(), [1500, 700, 1000, 700, 1500, 3000, 4000, 3000]);
      expect(_area(room.corners()), closeTo(4000 * 3000 - 1000 * 700, 1e-9));

      // Along the room: at the height of the notch the floor is two runs, and
      // [spanAt] hands back the pair of them with the hole included.
      final along = room.corners();
      final cut = spanAt(along, 300)!;
      expect(cut.lo, 0);
      expect(cut.hi, 4000, reason: 'leftmost to rightmost, notch and all');
      expect(spansOver(along, 200, 400).length, 1,
          reason: 'and nothing in this file can say it is really two');

      // Across the room: every row is one unbroken run, every time. The quarter
      // turn puts the near wall at the far end of the rows, so the rows against
      // the notch run 700 short of the others rather than starting 700 late —
      // which is the same thing a corner cut already does to the rows beside
      // it, and needs nothing of the engine it does not already do.
      final across = room.turned(room.corners());
      final reaches = <double>{};
      for (var v = 1.0; v < 4000; v += 7.3) {
        final span = spanAt(across, v);
        expect(span, isNotNull, reason: 'at $v');
        expect(span!.lo, 0, reason: 'at $v');
        reaches.add(span.hi);
      }
      expect(reaches, {2300.0, 3000.0},
          reason: 'two reaches and no third: a row is whole or it is short');
      expect(room.takesAlongLength, isFalse);
      expect(room.takesAcrossWidth, isTrue);
      expect(room.takesDiagonal, isFalse);
      expect(room.isRectilinear, isTrue);
      expect(room.isRectangular, isFalse);
    });

    test('the notch turns with the wall it is cut into', () {
      // Four walls, four rooms, and the direction follows the wall round: the
      // rows always cross the notch rather than run into it.
      for (final wall in RoomWall.values) {
        final room = WallNotchRoomShape(
          length: 4000,
          width: 3000,
          wall: wall,
          offsetFirst: 900,
          offsetSecond: 1100,
          depth: 600,
        );
        final along = wall.runsAlongLength ? 4000 : 3000;
        expect(room.problem, isNull, reason: '$wall');
        expect(room.notchWidth, along - 2000, reason: '$wall');
        expect(room.corners().length, 8, reason: '$wall');
        expect(reflexCorners(room.corners()).length, 2, reason: '$wall');
        expect(_area(room.corners()),
            closeTo(4000 * 3000 - (along - 2000) * 600, 1e-9),
            reason: '$wall');
        expect(room.takesAlongLength, !wall.runsAlongLength, reason: '$wall');
        expect(room.takesAcrossWidth, wall.runsAlongLength, reason: '$wall');
        // Every wall carries a measurement that is a typed number or a
        // difference of two, and they add up to the way round twice.
        expect(room.wallLengths().reduce((a, b) => a + b),
            2 * (4000 + 3000) + 2 * 600, reason: '$wall');
      }
    });

    test('a notch that is no notch, or leaves no room, is rejected', () {
      WallNotchRoomShape sized(int first, int second, int depth) =>
          WallNotchRoomShape(
            length: 4000,
            width: 3000,
            wall: RoomWall.near,
            offsetFirst: first,
            offsetSecond: second,
            depth: depth,
          );
      expect(sized(1500, 1500, 700).problem, isNull);
      // The two offsets leave less than the smallest cut there is between them.
      expect(sized(2000, 1950, 700).problem, RoomProblem.notchNotCut);
      expect(sized(2000, 1900, 700).problem, isNull, reason: 'and exactly 100 is a notch');
      expect(sized(1500, 1500, MIN_NOTCH_MM - 1).problem, RoomProblem.notchNotCut);
      // Deeper than the room less the narrowest room there is.
      expect(sized(1500, 1500, 3000 - MIN_ROOM_MM).problem, isNull);
      expect(sized(1500, 1500, 3000 - MIN_ROOM_MM + 1).problem,
          RoomProblem.notchLeavesNoRoom);
      // An end narrower than the smallest cut is not an end: the notch has
      // reached the corner, and that room is the Г-shaped one.
      expect(sized(MIN_NOTCH_MM - 1, 1500, 700).problem, RoomProblem.notchLeavesNoRoom);
      expect(sized(1500, MIN_NOTCH_MM - 1, 700).problem, RoomProblem.notchLeavesNoRoom);
    });

    test('a notch gives up the 45° layout and a chamfer keeps it', () {
      final notched = shaped(CornerCut.notch, {RoomCorner.farRight: size(900, 800)});
      final chamfered = shaped(CornerCut.chamfer, {RoomCorner.farRight: size(900, 800)});
      expect(notched.takesDiagonal, isFalse);
      expect(notched.isRectilinear, isTrue);
      expect(chamfered.takesDiagonal, isTrue,
          reason: 'it is convex, so a 45° strip crosses it once');
      expect(chamfered.isRectilinear, isFalse, reason: 'the cut wall is not square');
      // Neither is ever the rectangle it was cut from: [Calculation.rowLength]
      // casts on the strength of that answer.
      expect(notched.isRectangular, isFalse);
      expect(chamfered.isRectangular, isFalse);
    });

    test('rooms that differ anywhere are told apart by their key', () {
      final keys = <String>{
        shaped(CornerCut.notch, {RoomCorner.farRight: size(900, 800)}).key,
        shaped(CornerCut.chamfer, {RoomCorner.farRight: size(900, 800)}).key,
        shaped(CornerCut.notch, {RoomCorner.farLeft: size(900, 800)}).key,
        shaped(CornerCut.notch, {RoomCorner.farRight: size(901, 800)}).key,
        shaped(CornerCut.notch, {RoomCorner.farRight: size(900, 801)}).key,
        shaped(CornerCut.notch, {
          RoomCorner.farRight: size(900, 800),
          RoomCorner.nearLeft: size(900, 800),
        }).key,
        RoomShape.rectangle(length, width).key,
      };
      expect(keys.length, 7);
    });
  });
}

/// The area the outline encloses, by the shoelace formula.
double _area(List<Point<double>> polygon) {
  var sum = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final from = polygon[i];
    final to = polygon[(i + 1) % polygon.length];
    sum += from.x * to.y - to.x * from.y;
  }
  return (sum / 2).abs();
}
