// The invariants of a 45° layout, over many rooms.
//
// Straight laying has an oracle — every row is the same length, so a closed
// form says whether the offset pattern fits at all (see stress_test.dart).
// Diagonal laying has none: the rows differ in length, and whether a joint
// pattern exists is a search, not a formula. So this test says nothing about
// which rooms must produce a layout; it says that whatever comes out is a
// layout a floor fitter could actually cut and lay.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/row_plan.dart';

final violations = <String>[];

void checkResult(String cfg, Calculation c, Result r, RowPlan plan) {
  void bad(String message) => violations.add('$message  [$cfg]');

  if (r.lines.length != plan.numberOfRows) {
    bad('rows: laid ${r.lines.length} != planned ${plan.numberOfRows}');
    return;
  }
  for (var i = 0; i < r.lines.length; i++) {
    final line = r.lines[i];
    final planks = line.planks;
    final rowLength = plan.lengths[i];

    if (line.startOffsetMm != plan.startU[i]) {
      bad('row $i: start ${line.startOffsetMm} != planned ${plan.startU[i]}');
    }
    final sum = planks.fold<int>(0, (s, p) => s + p.length);
    if (sum != rowLength) bad('row $i: planks sum $sum != row length $rowLength');

    for (var j = 0; j < planks.length; j++) {
      final p = planks[j];
      // A plank bevelled at one end loses half a width of reach, at both ends
      // a whole width — the cut runs across the plank, not square to it.
      final cap = planks.length == 1
          ? plan.capWhole[i]
          : j == 0
              ? plan.capFirst[i]
              : j == planks.length - 1
                  ? plan.capLast[i]
                  : c.laminateLength;
      if (p.length > cap) bad('row $i plank $j: ${p.length} exceeds its cap $cap');
      if (p.length <= 0) bad('row $i plank $j: length ${p.length}');
      // A row shorter than the minimum is a sliver against a corner: it is one
      // plank, and there is nothing to lay in it but that.
      if (p.length < c.minimumLaminateLength && p.length != rowLength) {
        bad('row $i plank $j: ${p.length} below the minimum ${c.minimumLaminateLength}');
      }
      if (p.width != plan.widths[i]) {
        bad('row $i plank $j: width ${p.width} != planned ${plan.widths[i]}');
      }

      // Only the ends of a row meet a wall, so only they are cut on the slant.
      final left = j == 0 ? plan.startBevel[i] : Bevel.square;
      final right = j == planks.length - 1 ? plan.endBevel[i] : Bevel.square;
      if (p.leftBevel != left || p.rightBevel != right) {
        bad('row $i plank $j: bevels ${p.leftBevel}/${p.rightBevel} != $left/$right');
      }
    }
  }

  // Neighbouring rows must not have their joints on top of each other. Rows a
  // single plank spans have no joint and are stepped over.
  for (var i = 1; i < r.lines.length; i++) {
    if (r.lines[i - 1].planks.length == 1 || r.lines[i].planks.length == 1) continue;
    final prev = plan.startU[i - 1] + r.lines[i - 1].planks.first.length;
    final cur = plan.startU[i] + r.lines[i].planks.first.length;
    if ((prev - cur).abs() < c.rowOffset) {
      bad('rows ${i - 1}/$i: joints $prev and $cur are closer than the offset ${c.rowOffset}');
    }
  }

  // A 45° cut splits a plank into two trapezoids whose centrelines add up to
  // the plank, so the material still balances by length alone.
  final used = r.lines.fold<int>(0, (s, l) => s + l.planks.fold<int>(0, (t, p) => t + p.length));
  final left = r.pieces.fold<int>(0, (s, p) => s + p.length);
  final waste = r.trash.fold<int>(0, (s, p) => s + p.length);
  final bought = r.totalPlanks * c.laminateLength;
  if (used + left + waste != bought) {
    bad('balance: laid $used + pieces $left + waste $waste != bought $bought');
  }
}

int run(int roomLength, int roomWidth, int lamLength, int lamWidth, int indent, int minLen,
    int offset) {
  final cfg = 'room=${roomLength}x$roomWidth, laminate=${lamLength}x$lamWidth, '
      'min=$minLen, offset=$offset, indent=$indent';
  final c = Calculation(
    roomLength: roomLength,
    roomWidth: roomWidth,
    laminateLength: lamLength,
    laminateWidth: lamWidth,
    planksInPack: 8,
    indentFromWall: indent,
    minimumLaminateLength: minLen,
    rowOffset: offset,
    direction: Direction.diagonal,
  );
  final plan = planFor(
    roomLength: roomLength,
    roomWidth: roomWidth,
    indentFromWall: indent,
    laminateLength: lamLength,
    laminateWidth: lamWidth,
    direction: Direction.diagonal,
  );
  try {
    final results = c.calculate();
    for (final r in results) {
      checkResult(cfg, c, r, plan);
    }
    return results.isEmpty ? 0 : 1;
  } catch (e) {
    violations.add('CRASH: $e  [$cfg]');
    return 0;
  }
}

String report() {
  final out = StringBuffer('${violations.length} violations');
  for (final v in violations.take(10)) {
    out.writeln('\n  $v');
  }
  return out.toString();
}

void main() {
  setUp(violations.clear);

  test('typical rooms hold the diagonal invariants', () {
    run(5000, 4000, 1380, 190, 10, 300, 300);
    run(4100, 3200, 1380, 190, 10, 300, 300);
    run(3000, 2500, 1285, 192, 10, 300, 300);
    run(6000, 4500, 1380, 190, 10, 400, 300);
    run(2800, 2000, 1380, 190, 10, 300, 300);
    // A square room: both ends turn their corner at once and no row is
    // constant-length, the case the plateau degenerates in.
    run(4000, 4000, 1380, 190, 10, 300, 300);
    expect(violations, isEmpty, reason: report());
  });

  test('random rooms hold the diagonal invariants', () {
    final rnd = Random(20260731);
    var laid = 0;
    const runs = 600;
    for (var i = 0; i < runs; i++) {
      final roomLength = rnd.nextInt(10001) + 2000;
      final roomWidth = rnd.nextInt(8001) + 2000;
      final lamLength = 600 + rnd.nextInt(25) * 50;
      final lamWidth = 100 + rnd.nextInt(10) * 15;
      final minLen = 200 + rnd.nextInt(5) * 50;
      final int offset;
      switch (rnd.nextInt(4)) {
        case 0:
          offset = (lamLength / 2).round();
          break;
        case 1:
          offset = (lamLength / 3).round();
          break;
        case 2:
          offset = (lamLength / 4).round();
          break;
        default:
          offset = 200 + rnd.nextInt(5) * 50;
      }
      laid += run(roomLength, roomWidth, lamLength, lamWidth, rnd.nextInt(3) * 5, minLen, offset);
    }
    expect(violations, isEmpty, reason: report());
    // Not a specification, a tripwire: the engine used to lay a handful of
    // rooms and stop, and every invariant above still passed. If this fails
    // upwards, raise it; if it fails downwards, the search lost its reach.
    expect(laid, greaterThan(runs ~/ 5), reason: 'only $laid of $runs rooms produced a layout');
  });

  // Every 45° row ends in a wedge, and a wedge cannot be reused as the square
  // end of another row. So the same floor laid on the diagonal must cost more
  // planks than laid along a wall — if it ever costs fewer, the bevels are not
  // being charged for.
  test('the diagonal costs more material than laying along a wall', () {
    int cheapest(Direction direction) {
      final results = Calculation(
        roomLength: 5000,
        roomWidth: 4000,
        laminateLength: 1380,
        laminateWidth: 190,
        planksInPack: 8,
        indentFromWall: 10,
        minimumLaminateLength: 300,
        rowOffset: 300,
        direction: direction,
      ).calculate();
      expect(results, isNotEmpty, reason: '$direction must be layable');
      return results.map((r) => r.totalPlanks).reduce(min);
    }

    expect(cheapest(Direction.diagonal), greaterThan(cheapest(Direction.length)));
  });
}
