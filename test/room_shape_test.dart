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
}
