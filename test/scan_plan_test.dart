// The general strip walk against the two closed forms it has to subsume.
//
// [scanPlan] is what a room of any shape is laid out by, and a rectangle is the
// one shape whose answer is already known: [straightPlan] and [diagonalPlan]
// have been laying rectangles out correctly all along, and every golden image
// in this suite is drawn from them. So they are the oracle here — the walk has
// to reproduce them, and where it cannot reproduce them exactly the difference
// has to be a rounding one and no larger.
//
// The two do round differently, and deliberately: [diagonalPlan] rounds each
// side of the room to millimetres once and derives everything else in integers,
// while the walk turns the outline and measures it. Neither is wrong. What
// would be wrong is a difference that is not rounding — a row too many, a bevel
// leaning the wrong way, the drift running backwards — and that is what these
// tests are for.
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/row_plan.dart';

const _rooms = [
  [3000, 1200],
  [3000, 3000],
  [4200, 2600],
  [6000, 3000],
  [5010, 2000],
  [12000, 4000],
  [1000, 900],
];
const _widths = [190, 191, 128, 245];
const _gaps = [0, 10, 12];

/// The floor of a rectangular room, ready for the walk.
List<Point<double>> _floor(int length, int width, int gap) =>
    RoomShape.rectangle(length, width).floor(gap);

/// The chord a 45° row of strip [i] really has, with no rounding anywhere: the
/// closed form of a rectangle's diagonal section, read off the rectangle itself.
///
/// This is the truth both [diagonalPlan] and the walk are approximations of,
/// and the only witness that can say which of the two is drifting.
double _trueChord(int i, int w, int a, int b) {
  final extent = (a + b) / math.sqrt2;
  final tau = (i * w + math.min((i + 1) * w, extent)) / 2;
  return math.max(
      0.0, math.min(2 * tau, math.min(2 * math.min(a, b) / math.sqrt2, 2 * (extent - tau))));
}

void main() {
  group('a rectangle laid parallel to a wall', () {
    test('the walk finds the rows straightPlan fills in', () {
      for (final room in _rooms) {
        for (final w in _widths) {
          for (final gap in _gaps) {
            final a = room[0] - gap * 2;
            final b = room[1] - gap * 2;
            final scan = scanPlan(
              floor: _floor(room[0], room[1], gap),
              angle: 0,
              laminateLength: 1380,
              laminateWidth: w,
            );
            final where = 'room ${room[0]}x${room[1]}, width $w, gap $gap';

            // Rows all of one length, all starting together, all square ended:
            // the whole of what straightPlan says, said by the walk instead.
            expect(scan.lengths.toSet(), {a}, reason: where);
            expect(scan.startU.toSet(), {0}, reason: where);
            expect(scan.startBevel.toSet(), {Bevel.square}, reason: where);
            expect(scan.endBevel.toSet(), {Bevel.square}, reason: where);
            expect(scan.isUniform, isTrue, reason: where);
            expect(scan.capFirst.toSet(), {1380}, reason: where);
            expect(scan.capWhole.toSet(), {1380}, reason: where);

            // The row count is straightPlan's, except that the walk drops a
            // last row too narrow to lay — straight laying evens that shortfall
            // out between the first row and the last instead, which it can only
            // do because those two walls are parallel.
            final full = (b / w).ceil();
            final sliver = b - (full - 1) * w;
            final dropped = full > 1 && sliver < minRowWidthMm;
            expect(scan.numberOfRows, dropped ? full - 1 : full, reason: where);
            // The rows cover the floor, less the sliver that was dropped — the
            // one strip too narrow to lay, which straight laying evens out and
            // the walk leaves bare.
            expect(scan.widths.fold<int>(0, (sum, x) => sum + x), dropped ? b - sliver : b,
                reason: where);
          }
        }
      }
    });
  });

  group('a rectangle laid at 45°', () {
    test('the walk finds the same rows diagonalPlan derives', () {
      var worstLength = 0;
      var worstStart = 0;
      var worstWidth = 0;
      for (final room in _rooms) {
        for (final w in _widths) {
          for (final gap in _gaps) {
            final a = room[0] - gap * 2;
            final b = room[1] - gap * 2;
            final scan = scanPlan(
              floor: _floor(room[0], room[1], gap),
              angle: -math.pi / 4,
              laminateLength: 1380,
              laminateWidth: w,
            );
            final oracle =
                diagonalPlan(a: a, b: b, laminateLength: 1380, laminateWidth: w);
            final where = 'room ${room[0]}x${room[1]}, width $w, gap $gap';

            expect(scan.numberOfRows, oracle.numberOfRows, reason: where);
            for (var i = 0; i < oracle.numberOfRows; i++) {
              // Which way each end leans is geometry, not rounding, and has to
              // agree exactly: get it wrong and a piece cut for one row is
              // silently accepted into another it cannot fit.
              expect(scan.startBevel[i], oracle.startBevel[i], reason: '$where, row $i');
              expect(scan.endBevel[i], oracle.endBevel[i], reason: '$where, row $i');
              worstLength =
                  math.max(worstLength, (scan.lengths[i] - oracle.lengths[i]).abs());
              worstStart = math.max(worstStart, (scan.startU[i] - oracle.startU[i]).abs());
              worstWidth = math.max(worstWidth, (scan.widths[i] - oracle.widths[i]).abs());
            }
            // Every row but the sliver against the far corner is a full plank
            // wide in both, and that one is where the two ways of measuring the
            // room's reach across the diagonal part company.
            for (var i = 0; i < oracle.numberOfRows - 1; i++) {
              expect(scan.widths[i], oracle.widths[i], reason: '$where, row $i');
            }
          }
        }
      }
      // Two millimetres, and every one of them accounted for: [diagonalPlan]
      // rounds each side of the room to millimetres once and adds, so its idea
      // of how far the room reaches across the diagonal can sit a millimetre
      // off the walk's, and on the falling branch of the chord that millimetre
      // is doubled. The next test is the one that says which of the two is
      // nearer the room.
      expect(worstLength, lessThanOrEqualTo(2),
          reason: 'row lengths must agree to the millimetres the roundings differ by');
      expect(worstStart, lessThanOrEqualTo(1),
          reason: 'row starts must agree to the millimetre the roundings differ by');
      expect(worstWidth, lessThanOrEqualTo(1),
          reason: 'row widths must agree to the millimetre the roundings differ by');
    });

    test('the walk measures the room, to the millimetre it is rounded to', () {
      for (final room in _rooms) {
        for (final w in _widths) {
          for (final gap in _gaps) {
            final a = room[0] - gap * 2;
            final b = room[1] - gap * 2;
            final scan = scanPlan(
              floor: _floor(room[0], room[1], gap),
              angle: -math.pi / 4,
              laminateLength: 1380,
              laminateWidth: w,
            );
            for (var i = 0; i < scan.numberOfRows; i++) {
              expect((scan.lengths[i] - _trueChord(i, w, a, b)).abs(), lessThanOrEqualTo(1.0),
                  reason: 'room ${room[0]}x${room[1]}, width $w, gap $gap, row $i');
            }
          }
        }
      }
    });

    test('the drift turns the corner once, as it does in the closed form', () {
      for (final room in _rooms) {
        for (final w in _widths) {
          final scan = scanPlan(
            floor: _floor(room[0], room[1], 10),
            angle: -math.pi / 4,
            laminateLength: 1380,
            laminateWidth: w,
          );
          var turns = 0;
          for (var i = 1; i < scan.numberOfRows; i++) {
            if (scan.shift[i - 1].sign != scan.shift[i].sign &&
                scan.shift[i - 1] != 0 &&
                scan.shift[i] != 0) {
              turns++;
            }
          }
          expect(turns, lessThanOrEqualTo(1),
              reason: 'room ${room[0]}x${room[1]}, width $w');
        }
      }
    });
  });
}
