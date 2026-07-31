// The row geometry, checked against a numeric oracle rather than against the
// closed form it was derived from. The closed form is three cases glued at two
// independent breakpoints, and a sign error on the plateau reproduces almost
// every symptom of a correct layout, so it needs an independent witness: for
// each strip the oracle integrates the real chord across the room rectangle and
// compares area / plank width with the centreline length the plan claims.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/row_plan.dart';

// Chord of the room rectangle on the 45° line at perpendicular coordinate tau,
// straight from the rectangle's definition and with no rounding anywhere.
double _chord(double tau, int a, int b) {
  final d = math.sqrt2 * tau - b;
  final from = math.max(0.0, d);
  final to = math.min(a.toDouble(), b + d);
  return to <= from ? 0.0 : math.sqrt2 * (to - from);
}

// Area of strip i. This is what the material actually costs; a row's centreline
// length times its width is only a model of it.
double _stripArea(int i, int w, int a, int b) {
  const samples = 4000;
  var sum = 0.0;
  for (var s = 0; s < samples; s++) {
    sum += _chord((i + (s + 0.5) / samples) * w, a, b);
  }
  return sum / samples * w;
}

// Centreline of row i as the plan measures it: the middle of the part of the
// strip that is inside the room.
double _centreline(int i, int w, int a, int b) {
  final extent = (a + b) / math.sqrt2;
  return (i * w + math.min((i + 1) * w, extent)) / 2;
}

// Where the chord function bends: each end turning its corner, and the far
// corner of the room where the chord reaches zero. A strip containing one of
// these is the only place the centreline may legitimately disagree with the
// area, and only ever by overstating it, because the chord is concave there.
List<double> _kinks(int a, int b) =>
    [b / math.sqrt2, a / math.sqrt2, (a + b) / math.sqrt2]..sort();

int _kinksInStrip(int i, int w, int a, int b) =>
    _kinks(a, b).where((k) => k > i * w && k < (i + 1) * w).length;

void main() {
  const rooms = [
    [3000, 6000], // a < b, plateau after the starting corner
    [6000, 3000], // a > b, plateau before it
    [4000, 4000], // a == b, no plateau at all
    [2400, 2410], // the two breakpoints one strip apart
    [12000, 2100],
    [2000, 2000],
    [5230, 3170],
  ];
  const widths = [190, 192, 128, 1000];

  group('diagonal row lengths', () {
    test('every row matches the area the oracle integrates for its strip', () {
      for (final room in rooms) {
        for (final w in widths) {
          final a = room[0], b = room[1];
          final plan = diagonalPlan(a: a, b: b, laminateLength: 1380, laminateWidth: w);
          for (var i = 0; i < plan.numberOfRows; i++) {
            final oracle = _stripArea(i, w, a, b);
            final laid = (plan.lengths[i] * plan.widths[i]).toDouble();
            final kinks = _kinksInStrip(i, w, a, b);
            // A bend costs at most w/4 of overstatement per bend; 3 mm covers
            // the single rounding of each side by diagonalExtentMm.
            final slack = (kinks * w / 4 + 3) * w;
            expect(
              laid,
              closeTo(oracle, slack),
              reason: 'room $a x $b, plank width $w, row $i, $kinks bend(s) in the strip',
            );
            expect(laid, greaterThanOrEqualTo(oracle - 3 * w),
                reason: 'room $a x $b, width $w, row $i: the model must never '
                    'understate the material');
          }
        }
      }
    });

    test('the rows cover the room', () {
      for (final room in rooms) {
        for (final w in widths) {
          final a = room[0], b = room[1];
          final plan = diagonalPlan(a: a, b: b, laminateLength: 1380, laminateWidth: w);
          var laid = 0;
          for (var i = 0; i < plan.numberOfRows; i++) {
            laid += plan.lengths[i] * plan.widths[i];
          }
          final bends = List.generate(plan.numberOfRows, (i) => _kinksInStrip(i, w, a, b))
              .fold<int>(0, (s, k) => s + k);
          final slack = bends * w / 4 * w + plan.numberOfRows * 3 * w;
          expect(laid.toDouble(), closeTo(a * b, slack), reason: 'room $a x $b, plank width $w');
        }
      }
    });

    test('lengths rise, hold and fall, changing only where the geometry bends', () {
      for (final room in rooms) {
        for (final w in widths) {
          final a = room[0], b = room[1];
          final plan = diagonalPlan(a: a, b: b, laminateLength: 1380, laminateWidth: w);
          var falling = false;
          for (var i = 1; i < plan.numberOfRows; i++) {
            final step = plan.lengths[i] - plan.lengths[i - 1];
            if (step < 0) falling = true;
            expect(falling && step > 0, isFalse,
                reason: 'room $a x $b, width $w: lengths rise again after row $i');
            // Between two bends the chord is a straight line of slope +2, 0 or
            // -2, so consecutive rows differ by exactly twice their spacing.
            final from = _centreline(i - 1, w, a, b);
            final to = _centreline(i, w, a, b);
            final bent = _kinks(a, b).any((k) => k > from && k < to);
            if (bent) continue;
            final spacing = 2 * (to - from);
            expect([spacing, 0.0, -spacing].map((s) => (step - s).abs() < 2).contains(true), isTrue,
                reason: 'room $a x $b, width $w, row $i: step $step is not '
                    '0 or ${spacing.round()}');
          }
        }
      }
    });
  });

  group('where the rows start', () {
    test('the start walks one plank width a row and turns the corner once', () {
      for (final room in rooms) {
        for (final w in widths) {
          final a = room[0], b = room[1];
          final plan = diagonalPlan(a: a, b: b, laminateLength: 1380, laminateWidth: w);
          // The starting end walks towards the corner at b/sqrt2 and away from
          // it afterwards, so the drift is +w, then -w. Two rows step by less:
          // the one that straddles the corner, and the last one, which is only
          // a part of a strip wide.
          var irregular = 0;
          var turned = false;
          for (var i = 0; i < plan.numberOfRows - 1; i++) {
            final s = plan.shift[i];
            expect(s.abs(), lessThanOrEqualTo(w),
                reason: 'room $a x $b, width $w, row $i: drift $s exceeds a plank width');
            if (i == plan.numberOfRows - 2) continue;
            if (s.abs() != w) {
              irregular++;
              turned = true;
              continue;
            }
            if (s < 0) turned = true;
            expect(s, turned ? -w : w,
                reason: 'room $a x $b, width $w, row $i: drift $s on the '
                    '${turned ? "far" : "near"} side of the corner');
          }
          expect(irregular, lessThanOrEqualTo(1),
              reason: 'room $a x $b, width $w: the start may turn the corner only once');
        }
      }
    });

    test('the start bevel flips with the drift, the end bevel independently', () {
      for (final room in rooms) {
        for (final w in widths) {
          final a = room[0], b = room[1];
          final plan = diagonalPlan(a: a, b: b, laminateLength: 1380, laminateWidth: w);
          int flips(List<Bevel> bevels) {
            var n = 0;
            for (var i = 1; i < bevels.length; i++) {
              if (bevels[i] != bevels[i - 1]) n++;
            }
            return n;
          }

          expect(flips(plan.startBevel), lessThanOrEqualTo(1), reason: 'room $a x $b, width $w');
          expect(flips(plan.endBevel), lessThanOrEqualTo(1), reason: 'room $a x $b, width $w');
          expect(plan.startBevel.contains(Bevel.square), isFalse,
              reason: 'a 45° row never meets a wall head on');
          expect(plan.endBevel.contains(Bevel.square), isFalse);
          // While one end has turned the corner and the other has not, the row
          // gains at one end exactly what it loses at the other: the plateau.
          for (var i = 0; i < plan.numberOfRows; i++) {
            final constant = plan.startBevel[i] != plan.endBevel[i];
            final plateau = 2 * math.min(diagonalExtentMm(a), diagonalExtentMm(b));
            if (constant) {
              expect(plan.lengths[i], plateau,
                  reason: 'room $a x $b, width $w, row $i: opposite bevels outside the plateau');
            }
          }
        }
      }
    });
  });

  group('how much a bevelled plank can reach', () {
    test('a bevel costs half a width, two bevels a whole one', () {
      final plan = diagonalPlan(a: 3000, b: 6000, laminateLength: 1380, laminateWidth: 190);
      expect(plan.capFirst.first, 1380 - 95);
      expect(plan.capLast.first, 1380 - 95);
      expect(plan.capWhole.first, 1380 - 190);
    });

    test('an odd plank width rounds the bevel cost against the plank', () {
      final plan = diagonalPlan(a: 3000, b: 6000, laminateLength: 1380, laminateWidth: 191);
      expect(plan.capFirst.first, 1380 - 96, reason: 'claiming 95.5 mm of reach would overrun');
    });

    // Why the engine may keep charging a cut as `laminateLength - laid`: a 45°
    // cut splits the material into two trapezoids whose centrelines still add
    // up to the plank it came from, because a centreline is area over width and
    // area is additive.
    test('the two halves of a slanted cut still add up to the plank', () {
      final random = math.Random(20260731);
      for (var t = 0; t < 2000; t++) {
        final w = 50 + random.nextInt(400);
        final l = w + random.nextInt(2000);
        final c = w ~/ 2 + random.nextInt(l - w + 1);
        double area(double shortSide, double longSide) => w * (shortSide + longSide) / 2;
        final left = area(c - w / 2, c + w / 2);
        final right = area(l - c - w / 2, l - c + w / 2);
        expect(left + right, closeTo(w * l.toDouble(), 1e-6), reason: 'L=$l c=$c w=$w');
      }
    });
  });

  group('the sliver against the far corner', () {
    // Every row is a full plank wide but the last, which takes what is left of
    // the diagonal extent. Under 50 mm that strip is not a row a fitter can
    // lay, so it is dropped and the corner is left to the skirting board.
    test('a last row under 50 mm is dropped, one over it is kept', () {
      // Chosen so the leftover lands either side of the limit: the extent is
      // the two sides over root two, added.
      int leftover(int a, int b, int w) {
        final extent = diagonalExtentMm(a) + diagonalExtentMm(b);
        return extent - ((extent / w).ceil() - 1) * w;
      }

      var dropped = 0, kept = 0;
      for (var a = 2000; a < 6000; a += 37) {
        final plan = diagonalPlan(a: a, b: 4000, laminateLength: 1380, laminateWidth: 190);
        final over = leftover(a, 4000, 190);
        if (over < minRowWidthMm) {
          dropped++;
          expect(plan.widths.last, 190, reason: 'room $a: a $over mm sliver was laid');
        } else {
          kept++;
          expect(plan.widths.last, over, reason: 'room $a: a $over mm row was dropped');
        }
      }
      expect(dropped, greaterThan(10), reason: 'the fixture must exercise both sides');
      expect(kept, greaterThan(10));
    });

    // The two must never disagree: a row the engine lays and the validator does
    // not know about is a green form with no laying variants behind it.
    test('the validator counts the rows the plan builds', () {
      for (var a = 2000; a < 6000; a += 37) {
        for (final w in [190, 128, 192]) {
          final plan = diagonalPlan(a: a, b: 4000, laminateLength: 1380, laminateWidth: w);
          expect(
            numberOfRowsMm(
              roomLength: a + 20,
              roomWidth: 4020,
              indentFromWall: 10,
              laminateWidth: w,
              direction: Direction.diagonal,
            ),
            plan.numberOfRows,
            reason: 'room $a, plank width $w',
          );
        }
      }
    });
  });

  group('straight laying is the same class with the corners taken out', () {
    test('one length, no drift, no bevels, full reach', () {
      final plan = straightPlan(
          rowLength: 2980, numberOfRows: 16, laminateLength: 1380, laminateWidth: 190);
      expect(plan.numberOfRows, 16);
      expect(plan.isUniform, isTrue);
      expect(plan.lengths.toSet(), {2980});
      expect(plan.startU.toSet(), {0});
      expect(plan.shift.toSet(), {0});
      expect(plan.capFirst.toSet(), {1380});
      expect(plan.capWhole.toSet(), {1380});
      expect(plan.startBevel.toSet(), {Bevel.square});
      expect(plan.endBevel.toSet(), {Bevel.square});
    });

    test('a diagonal plan is not uniform', () {
      final plan = diagonalPlan(a: 3000, b: 6000, laminateLength: 1380, laminateWidth: 190);
      expect(plan.isUniform, isFalse);
    });
  });
}
