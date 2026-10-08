// The rows of a room with a corner cut away.
//
// Two oracles, and between them they pin the whole builder. A rectangle is the
// first: [rectilinearPlan] has to reproduce [straightPlan] on one exactly —
// not within a rounding crumb, exactly — because a rectangle is what every
// room was and every golden image in this suite is still drawn from one. The
// second is the floor's own area, counted a square millimetre at a time: the
// rows must cover all of it, and overshoot it by no more than the one row that
// steps across the cut can account for.
//
// That pair of bounds is the real content here. Covering less than the floor
// means a ribbon of bare boards in the corner, which the user finds on site;
// covering more means material bought and binned. The first is forbidden
// outright and the second is allowed exactly as far as the arithmetic says it
// must be, and no further.
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/row_plan.dart';

const _rooms = [
  [4000, 3000],
  [3000, 1200],
  [6000, 3000],
  [5010, 2000],
  [12000, 4000],
];
const _widths = [190, 191, 128, 245];
const _gaps = [0, 10, 12];

LRoomShape _cut(int length, int width, int a, int b, RoomCorner corner) => LRoomShape(
      length: length,
      width: width,
      notchLength: a,
      notchWidth: b,
      corner: corner,
    );

/// Every length the floor takes across the rows, and how much of the room is
/// at each — the two cross-sections of a room with one corner cut away.
Set<int> _reaches(List<Point<double>> floor) {
  final out = <int>{};
  final vs = floor.map((p) => p.y).toSet().toList()..sort();
  for (var i = 0; i + 1 < vs.length; i++) {
    final span = spanAt(floor, (vs[i] + vs[i + 1]) / 2);
    if (span != null) out.add(span.length.round());
  }
  return out;
}

double _area(List<Point<double>> polygon) {
  var sum = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final from = polygon[i];
    final to = polygon[(i + 1) % polygon.length];
    sum += from.x * to.y - to.x * from.y;
  }
  return (sum / 2).abs();
}

void main() {
  group('a rectangle comes out exactly as it always did', () {
    test('row for row, number for number, against straightPlan', () {
      for (final room in _rooms) {
        for (final w in _widths) {
          for (final gap in _gaps) {
            final a = room[0] - gap * 2;
            final b = room[1] - gap * 2;
            final walked = rectilinearPlan(
              floor: RoomShape.rectangle(room[0], room[1]).floor(gap),
              laminateLength: 1380,
              laminateWidth: w,
            );
            final closed = straightPlan(
              rowLength: a,
              across: b,
              laminateLength: 1380,
              laminateWidth: w,
            );
            final why = '$room gap $gap plank $w';
            expect(walked.lengths, closed.lengths, reason: '$why: lengths');
            expect(walked.widths, closed.widths, reason: '$why: widths');
            expect(walked.startU, closed.startU, reason: '$why: starts');
            expect(walked.shift, closed.shift, reason: '$why: drift');
            expect(walked.capFirst, closed.capFirst, reason: '$why: caps');
            expect(walked.startBevel, closed.startBevel, reason: '$why: start ends');
            expect(walked.endBevel, closed.endBevel, reason: '$why: finish ends');
            expect(walked.isUniform, isTrue, reason: why);
          }
        }
      }
    });

    test('the width rule is the one straightPlan has always used', () {
      for (final room in _rooms) {
        for (final w in _widths) {
          final across = room[1];
          final widths = rowWidths(across: across, laminateWidth: w);
          final why = '$room plank $w';
          // Within a millimetre, and always short rather than over. When the
          // last row comes out too narrow to lay, the first row gives up half
          // of its own width, and half of an odd number of millimetres is not
          // a whole one — so the floor can end one millimetre inside the wall.
          // It has done since the rule was written; the skirting board covers
          // it, and the point here is that extracting the rule did not change
          // it.
          final total = widths.reduce((a, b) => a + b);
          expect(total, lessThanOrEqualTo(across), reason: why);
          expect(total, greaterThanOrEqualTo(across - 1), reason: why);
          expect(widths.length, (across / w).ceil(), reason: why);
          for (final width in widths) {
            expect(width, lessThanOrEqualTo(w), reason: why);
            expect(width, greaterThan(0), reason: why);
          }
        }
      }
    });
  });

  group('a room with a corner cut away', () {
    test('it keeps the row widths of the rectangle it was cut from', () {
      // The point of sharing the shortfall rather than dropping it where it
      // falls: a user who adds a small notch to a room they already costed
      // must not find that every row in it has been re-ripped.
      for (final room in _rooms) {
        for (final w in _widths) {
          for (final corner in RoomCorner.values) {
            final gap = 10;
            final shape = _cut(room[0], room[1], 800, 400, corner);
            final rectangle = straightPlan(
              rowLength: room[0] - gap * 2,
              across: room[1] - gap * 2,
              laminateLength: 1380,
              laminateWidth: w,
            );
            final plan = rectilinearPlan(
              floor: shape.floor(gap),
              laminateLength: 1380,
              laminateWidth: w,
            );
            expect(plan.widths, rectangle.widths, reason: '$room $corner plank $w');
            expect(plan.numberOfRows, rectangle.numberOfRows,
                reason: '$room $corner plank $w');
          }
        }
      }
    });

    test('every row is one of the two lengths the floor actually has', () {
      for (final room in _rooms) {
        for (final corner in RoomCorner.values) {
          for (final direction in [Direction.length, Direction.width]) {
            final shape = _cut(room[0], room[1], 800, 400, corner);
            final floor = shape.floor(10);
            final laid = direction == Direction.width ? shape.turned(floor) : floor;
            final plan = rectilinearPlan(
              floor: laid,
              laminateLength: 1380,
              laminateWidth: 190,
            );
            final reaches = _reaches(laid);
            final why = '$room $corner $direction';
            expect(reaches.length, 2, reason: '$why: the floor has two reaches');
            for (final length in plan.lengths) {
              expect(reaches, contains(length), reason: '$why: row length $length');
            }
            // Both of them are used: the cut is deeper than a row, so there
            // are rows on each side of the step.
            expect(plan.lengths.toSet().length, 2, reason: why);
            // And every end is square — every wall of this room is square to
            // the rows, so there is nothing to cut on the slant.
            for (var i = 0; i < plan.numberOfRows; i++) {
              expect(plan.startBevel[i], Bevel.square, reason: '$why: row $i');
              expect(plan.endBevel[i], Bevel.square, reason: '$why: row $i');
              expect(plan.capWhole[i], 1380, reason: '$why: row $i');
            }
          }
        }
      }
    });

    test('the rows cover the floor, and overshoot it by one step at most', () {
      // The two-sided bound. Below the floor's area is bare boards; above it
      // by more than the one row that crosses the step is arithmetic drifting.
      for (final room in _rooms) {
        for (final w in _widths) {
          for (final corner in RoomCorner.values) {
            for (final direction in [Direction.length, Direction.width]) {
              final shape = _cut(room[0], room[1], 800, 400, corner);
              final floor = shape.floor(10);
              final laid = direction == Direction.width ? shape.turned(floor) : floor;
              final plan = rectilinearPlan(
                floor: laid,
                laminateLength: 1380,
                laminateWidth: w,
              );
              var laidArea = 0;
              for (var i = 0; i < plan.numberOfRows; i++) {
                laidArea += plan.lengths[i] * plan.widths[i];
              }
              final reaches = _reaches(laid).toList()..sort();
              final step = reaches.last - reaches.first;
              final why = '$room $corner $direction plank $w';
              expect(laidArea, greaterThanOrEqualTo(_area(laid).round() - plan.numberOfRows),
                  reason: '$why: a row stopped short of the floor');
              expect(laidArea,
                  lessThanOrEqualTo(_area(laid).round() + step * w + plan.numberOfRows),
                  reason: '$why: more than one row overshot the cut');
            }
          }
        }
      }
    });

    test('the row that crosses the step is laid long, not short', () {
      // 4000 x 3000 with 1500 x 1000 out of the far right corner, a 10 mm gap
      // and a 190 mm plank. The floor steps at v = 1990, which falls inside
      // the eleventh strip (1910..2100). Measured at that strip's centre line
      // the row would come out short and leave 80 mm of floor bare along the
      // step; measured across the strip it comes out long.
      final plan = rectilinearPlan(
        floor: _cut(4000, 3000, 1500, 1000, RoomCorner.farRight).floor(10),
        laminateLength: 1380,
        laminateWidth: 190,
      );
      expect(plan.numberOfRows, 16);
      expect(plan.widths, [...List.filled(15, 190), 130]);
      expect(plan.lengths, [...List.filled(11, 3980), ...List.filled(5, 2480)]);
      expect(plan.startU, List.filled(16, 0));
      expect(plan.isUniform, isFalse);

      // And what the row is laid long *over*. The strip runs 1910..2100 and the
      // floor steps at 1990, so past the cut at u = 2480 there is 80 mm of
      // floor under a 190 mm row. That is the number the cut list prints
      // against the planks out there, and the only place it exists.
      expect(plan.steps,
          [const RowStep(row: 10, fromMm: 2480, toMm: 3980, width: 80)]);
    });

    test('a row the walls run straight through has no step in it', () {
      // The predicate under the whole feature. Every room here is cut, so every
      // plan has a step somewhere — but in one row only, and the fifteen others
      // must come out as plain as a rectangle's or the cut list will tell a
      // fitter to rip boards that need no ripping.
      for (final room in _rooms) {
        for (final w in _widths) {
          for (final corner in RoomCorner.values) {
            for (final direction in [Direction.length, Direction.width]) {
              final shape = _cut(room[0], room[1], 800, 400, corner);
              final floor = shape.floor(10);
              final laid = direction == Direction.width ? shape.turned(floor) : floor;
              final plan =
                  rectilinearPlan(floor: laid, laminateLength: 1380, laminateWidth: w);
              final why = '$room $corner $direction plank $w';
              expect(plan.steps.map((s) => s.row).toSet(), hasLength(1),
                  reason: '$why: one cut, one row stepped');
              for (final step in plan.steps) {
                expect(step.width, lessThan(plan.widths[step.row]),
                    reason: '$why: a step no narrower than the row it is in');
                expect(step.width, greaterThan(0), reason: why);
                expect(step.fromMm, lessThan(step.toMm), reason: why);
                // Inside the row, and measured from the row's own start, which
                // is what lets the cut list walk planks and steps together.
                expect(step.toMm, lessThanOrEqualTo(plan.lengths[step.row]), reason: why);
                expect(step.fromMm, greaterThanOrEqualTo(0), reason: why);
              }
            }
          }
        }
      }
    });

    test('a rectangle has no steps at all', () {
      for (final room in _rooms) {
        final plan = rectilinearPlan(
          floor: RoomShape.rectangle(room[0], room[1]).floor(10),
          laminateLength: 1380,
          laminateWidth: 190,
        );
        expect(plan.steps, isEmpty, reason: '$room');
      }
    });

    test('a cut on the starting side moves the rows instead of shortening them', () {
      // The same room cut at the near left instead. Now every row is as long
      // as the floor it crosses but the ones beside the cut start further
      // along, which is the drift the joint rule has to work with.
      final plan = rectilinearPlan(
        floor: _cut(4000, 3000, 1500, 1000, RoomCorner.nearLeft).floor(10),
        laminateLength: 1380,
        laminateWidth: 190,
      );
      expect(plan.startU.first, 1500, reason: 'the first row runs beside the cut');
      expect(plan.startU.last, 0, reason: 'the last row is clear of it');
      expect(plan.startU.toSet(), {0, 1500});
      expect(plan.lengths.toSet(), {3980, 2480});
      expect(plan.shift.any((s) => s != 0), isTrue);
    });

    test('a row with a step at each end is laid across both of them', () {
      // The one row a second cut adds that a single cut never produced, and the
      // reason the stress test no longer insists a row be one of the lengths the
      // floor has: a Z whose two inside corners land in the same strip.
      //
      // 4000 x 3000, a 10 mm gap, a 190 mm plank. 800 x 1990 out of the near
      // left corner and 1200 x 1000 out of the far right, which puts the right
      // edge's step at v = 1990 and the left edge's at v = 2000 — ten
      // millimetres apart, and both inside the eleventh strip (1910..2100).
      //
      // The floor is 3180 mm across below that strip and 2780 above it, and
      // 1980 in the sliver between the steps. The row is 3980: it starts at the
      // left wall the floor has above the step and ends at the right wall it has
      // below it, and no single height in the strip is that wide. Laid to either
      // of those lengths it would leave a ribbon of real floor bare against one
      // wall or the other; laid to 3980 the board is notched at both ends, which
      // is what a fitter already does at one.
      final floor = CutCornersRoomShape(
        length: 4000,
        width: 3000,
        cut: CornerCut.notch,
        cuts: const {
          RoomCorner.nearLeft: CornerSize(along: 800, across: 1990),
          RoomCorner.farRight: CornerSize(along: 1200, across: 1000),
        },
      ).floor(10);
      final plan = rectilinearPlan(
        floor: floor,
        laminateLength: 1380,
        laminateWidth: 190,
      );
      expect(plan.numberOfRows, 16);
      expect(plan.lengths,
          [...List.filled(10, 3180), 3980, ...List.filled(5, 2780)]);
      expect(plan.startU, [...List.filled(10, 800), ...List.filled(6, 0)]);
      expect(_reaches(floor), {3180, 1980, 2780},
          reason: 'no height in the room is 3980 mm across');
      expect(plan.lengths[10], greaterThan(_reaches(floor).reduce(math.max)),
          reason: 'the row that holds both steps is longer than the floor ever is');
    });

    test('a cut shallower than the last row changes nothing but the drawing', () {
      // The rule that keeps a small notch from moving a layout. With the step
      // inside the last strip every row reaches the full length, the plan is
      // the bounding rectangle's row for row, and the user who typed a 120 mm
      // riser is not told to buy differently because of it.
      final plan = rectilinearPlan(
        floor: _cut(4000, 3000, 600, 120, RoomCorner.farRight).floor(10),
        laminateLength: 1380,
        laminateWidth: 190,
      );
      final rectangle = straightPlan(
        rowLength: 3980,
        across: 2980,
        laminateLength: 1380,
        laminateWidth: 190,
      );
      expect(plan.lengths, rectangle.lengths);
      expect(plan.widths, rectangle.widths);
      expect(plan.startU, rectangle.startU);
      expect(plan.isUniform, isTrue);
    });
  });

  group('a notch in the middle of a wall', () {
    // 4000 x 3000, a notch 1000 wide and 700 deep in the middle of the near
    // wall, a 10 mm gap and a 190 mm plank.
    const room = WallNotchRoomShape(
      length: 4000,
      width: 3000,
      wall: RoomWall.near,
      offsetFirst: 1500,
      offsetSecond: 1500,
      depth: 700,
    );

    test('laid across the notched wall it is rows of two lengths, nothing new',
        () {
      // The claim the whole shape rests on: across the notch the engine needs
      // nothing it does not already do. The quarter turn puts the notched wall
      // at the far end of the rows, so the rows against the notch simply run
      // short — two reaches, like a room with one corner cut away, and the
      // same builder produces them.
      final plan = planFor(
        shape: room,
        indentFromWall: 10,
        laminateLength: 1380,
        laminateWidth: 190,
        direction: Direction.width,
      );
      expect(plan.numberOfRows, 21);
      expect(plan.lengths,
          [...List.filled(8, 2980), ...List.filled(5, 2280), ...List.filled(8, 2980)]);
      expect(plan.startU, List.filled(21, 0),
          reason: 'the notch takes off the far end of a row, not its start');
      expect(plan.widths, [...List.filled(20, 190), 180]);
      expect(plan.isUniform, isFalse);

      // The rows that hold a step are laid to the longer reach and notched
      // round the corner, which is what a fitter does — rows 7 and 13 here.
      expect(plan.lengths[7], 2980);
      expect(plan.lengths[13], 2980);
    });

    test('the rows cover the floor and overshoot by the two steps at most', () {
      final plan = planFor(
        shape: room,
        indentFromWall: 10,
        laminateLength: 1380,
        laminateWidth: 190,
        direction: Direction.width,
      );
      var covered = 0;
      for (var i = 0; i < plan.numberOfRows; i++) {
        covered += plan.lengths[i] * plan.widths[i];
      }
      final floor = _area(room.floor(10));
      expect(covered, greaterThanOrEqualTo(floor.round() - plan.numberOfRows),
          reason: 'no ribbon of floor is left bare');
      // Two rows hold a step, and each may run the step's own depth past it.
      expect(covered, lessThanOrEqualTo((floor + 2 * 700 * 190).round() + plan.numberOfRows));
    });
  });

  group('planFor sends a room with a cut down the right path', () {
    test('along the length and across the width, but never at 45°', () {
      final shape = _cut(4000, 3000, 1500, 1000, RoomCorner.farRight);
      for (final direction in [Direction.length, Direction.width]) {
        final plan = planFor(
          shape: shape,
          indentFromWall: 10,
          laminateLength: 1380,
          laminateWidth: 190,
          direction: direction,
        );
        final floor = shape.floor(10);
        final laid = direction == Direction.width ? shape.turned(floor) : floor;
        final direct = rectilinearPlan(
          floor: laid,
          laminateLength: 1380,
          laminateWidth: 190,
        );
        expect(plan.lengths, direct.lengths, reason: '$direction');
        expect(plan.widths, direct.widths, reason: '$direction');
        expect(plan.startU, direct.startU, reason: '$direction');
      }
    });

    test('a 45° row would cross the cut twice, and spanAt would not notice', () {
      // Why the direction is refused rather than approximated.
      //
      // Laid along a wall, the cut takes material off the *end* of a row, and
      // the leftmost and rightmost crossings [spanAt] returns are the row.
      // Turn the floor 45° and the cut lands in the middle of a row instead:
      // the floor there is two runs with a hole between them, [spanAt]
      // reports the hole as floor, and the drawing would lay boards across
      // thin air. A row that is two rows is not something [RowPlan] can say,
      // which is the whole reason the direction is refused rather than
      // approximated.
      final floor = _cut(4000, 3000, 1500, 1000, RoomCorner.farRight).floor(10);
      final turned = rowFrame(floor, -math.pi / 4);
      final vLo = turned.map((p) => p.y).reduce(math.min);
      final vHi = turned.map((p) => p.y).reduce(math.max);
      var worst = 0.0;
      for (var i = 1; i < 200; i++) {
        final v = vLo + (vHi - vLo) * i / 200;
        final span = spanAt(turned, v);
        if (span == null) continue;
        worst = math.max(worst, span.length - _sliceLength(turned, v));
      }
      // The cut is 1500 by 1000; held across the diagonal it opens a hole in
      // the row of most of a metre. Nothing to round away.
      expect(worst, greaterThan(900),
          reason: 'the span has to overstate the floor, or there is nothing to refuse');

      // Laid along either wall, the same floor has no hole in any row at all.
      for (final direction in [Direction.length, Direction.width]) {
        final shape = _cut(4000, 3000, 1500, 1000, RoomCorner.farRight);
        final laid = direction == Direction.width ? shape.turned(floor) : floor;
        final low = laid.map((p) => p.y).reduce(math.min);
        final high = laid.map((p) => p.y).reduce(math.max);
        for (var i = 1; i < 200; i++) {
          final v = low + (high - low) * i / 200;
          final span = spanAt(laid, v);
          if (span == null) continue;
          expect(span.length, closeTo(_sliceLength(laid, v), 1e-6), reason: '$direction at $v');
        }
      }
    });
  });
}

/// How much floor the line at [v] really crosses, counted run by run rather
/// than end to end. The witness that [spanAt] overstates a 45° row.
double _sliceLength(List<Point<double>> polygon, double v) {
  final crossings = <double>[];
  for (var i = 0; i < polygon.length; i++) {
    final from = polygon[i];
    final to = polygon[(i + 1) % polygon.length];
    if (from.y == to.y) continue;
    final t = (v - from.y) / (to.y - from.y);
    if (t < 0 || t > 1) continue;
    crossings.add(from.x + (to.x - from.x) * t);
  }
  crossings.sort();
  var total = 0.0;
  for (var i = 0; i + 1 < crossings.length; i += 2) {
    total += crossings[i + 1] - crossings[i];
  }
  return total;
}
