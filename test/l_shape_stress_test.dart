// The invariants of a room with a corner cut away, over many rooms, both
// laying directions and all four corners.
//
// Nothing here says which rooms must produce a layout: the rows differ in
// length, so whether a joint pattern exists is a search rather than a formula.
// What it says is that whatever comes out is a floor a fitter could cut and
// lay — the planks add up to the rows, the rows cover the floor and overshoot
// it only where the cut says they must, every plank is inside the walls, the
// joints keep their distance, and the material balances.
//
// The two-sided coverage bound is the one worth reading twice. A room with a
// cut has one row that steps across the inside corner, and that row is laid to
// the longer of the two reaches: covering less would leave a ribbon of bare
// floor along the step, which the user finds on site. So the rows must cover
// at least the floor, and at most the floor plus that one step — never short,
// and over by a bounded amount rather than by whatever the arithmetic drifts
// to.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'polygon.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/row_plan.dart';
import 'package:floor_calculator/scheme_geometry.dart';
import 'package:floor_calculator/utils/units.dart';

final violations = <String>[];

/// Every length the floor takes across the rows: two for a room with one
/// corner cut away, and their difference is the step.
List<double> _reaches(List<Point<double>> floor) {
  final out = <double>{};
  final vs = floor.map((p) => p.y).toSet().toList()..sort();
  for (var i = 0; i + 1 < vs.length; i++) {
    final span = spanAt(floor, (vs[i] + vs[i + 1]) / 2);
    if (span != null) out.add(span.length);
  }
  final list = out.toList()..sort();
  return list;
}

void checkResult(String cfg, Calculation c, Result r, RowPlan plan) {
  void bad(String message) => violations.add('$message  [$cfg]');

  if (r.lines.length != plan.numberOfRows) {
    bad('rows: laid ${r.lines.length} != planned ${plan.numberOfRows}');
    return;
  }
  for (var i = 0; i < r.lines.length; i++) {
    final planks = r.lines[i].planks;
    final rowLength = plan.lengths[i];

    if (r.lines[i].startOffsetMm != plan.startU[i]) {
      bad('row $i: start ${r.lines[i].startOffsetMm} != planned ${plan.startU[i]}');
    }
    final sum = planks.fold<int>(0, (s, p) => s + p.length);
    if (sum != rowLength) bad('row $i: planks sum $sum != row length $rowLength');

    // Every wall of this room is square to the rows, so nothing is cut on the
    // slant and a plank's full length is its reach.
    if (!plan.startBevel[i].isSquare || !plan.endBevel[i].isSquare) {
      bad('row $i: ends ${plan.startBevel[i]}/${plan.endBevel[i]} are not square');
    }
    if (plan.capWhole[i] != c.laminateLength) {
      bad('row $i: a square-ended row lost reach, cap ${plan.capWhole[i]}');
    }

    for (var j = 0; j < planks.length; j++) {
      final p = planks[j];
      if (p.length > c.laminateLength) {
        bad('row $i plank $j: ${p.length} is longer than a plank');
      }
      if (p.length <= 0) bad('row $i plank $j: length ${p.length}');
      if (p.length < c.minimumLaminateLength && p.length != rowLength) {
        bad('row $i plank $j: ${p.length} below the minimum ${c.minimumLaminateLength}');
      }
      if (p.width != plan.widths[i]) {
        bad('row $i plank $j: width ${p.width} != planned ${plan.widths[i]}');
      }
      if (!p.leftBevel.isSquare || !p.rightBevel.isSquare) {
        bad('row $i plank $j: bevels ${p.leftBevel}/${p.rightBevel} are not square');
      }
    }
  }

  for (var i = 1; i < r.lines.length; i++) {
    if (r.lines[i - 1].planks.length == 1 || r.lines[i].planks.length == 1) continue;
    final prev = plan.startU[i - 1] + r.lines[i - 1].planks.first.length;
    final cur = plan.startU[i] + r.lines[i].planks.first.length;
    if ((prev - cur).abs() < c.rowOffset) {
      bad('rows ${i - 1}/$i: joints $prev and $cur are closer than the offset ${c.rowOffset}');
    }
  }

  final used = r.lines.fold<int>(0, (s, l) => s + l.planks.fold<int>(0, (t, p) => t + p.length));
  final left = r.pieces.fold<int>(0, (s, p) => s + p.length);
  final waste = r.trash.fold<int>(0, (s, p) => s + p.length);
  final bought = r.totalPlanks * c.laminateLength;
  if (used + left + waste != bought) {
    bad('balance: laid $used + pieces $left + waste $waste != bought $bought');
  }

  // The drawing is where a wrong outline shows. A plank reaching into the cut
  // is invisible in the lengths and obvious here, and so is the older failure
  // this room nearly had: cutting against each wall's line in turn rather than
  // against the room, which left every plank in either arm empty.
  final scheme = buildScheme(r, system: MeasurementSystem.metric, minTextMm: 3);
  final walls = LaidFloor(scheme.room);
  var drawn = 0.0;
  for (final shape in scheme.planks) {
    if (shape.outline.isEmpty) {
      bad('plank ${shape.plank.number}: cut away to nothing');
      continue;
    }
    if (shape.outline.length > 6) {
      bad('plank ${shape.plank.number}: ${shape.outline.length} corners, more than an L has');
    }
    drawn += polygonArea(shape.outline);
    for (final point in shape.outline) {
      final depth = walls.insideDepth(point);
      if (depth < -0.5) {
        bad('plank ${shape.plank.number}: a corner is ${(-depth).toStringAsFixed(1)} mm '
            'outside the walls');
        break;
      }
    }
  }

  final floorPolygon = drawnFloor(r);
  final floor = polygonArea(floorPolygon);
  final rotated = [for (final p in floorPolygon) Point(p.dx, p.dy)];
  final reaches = _reaches(rotated);
  if (reaches.length != 2) {
    bad('the floor has ${reaches.length} reaches, not the two a single cut gives');
    return;
  }

  // What the drawing may leave uncovered: a strip one millimetre deep along
  // the far wall, the width of the room.
  //
  // [rowWidths] halves the shortfall between the first row and the last, and
  // half of an odd number of millimetres is not a whole one, so the rows can
  // add up to one millimetre less than the room is across. That is how
  // [straightPlan] has settled it since it was written — a rectangle ends the
  // same millimetre short — and the skirting board covers it. It is allowed
  // for here rather than rounded away, because what this test is actually
  // watching for is a *row* missing, which is three orders of magnitude
  // bigger.
  final millimetre = reaches.last;
  if (drawn > floor + 1 || drawn < floor - millimetre - 1) {
    bad('drawing: planks cover ${drawn.round()} mm² of a ${floor.round()} mm² floor');
  }

  for (var i = 0; i < plan.numberOfRows; i++) {
    final length = plan.lengths[i].toDouble();
    if ((length - reaches.first).abs() > 1 && (length - reaches.last).abs() > 1) {
      bad('row $i: ${plan.lengths[i]} mm is neither reach the floor has '
          '(${reaches.first.round()} / ${reaches.last.round()})');
    }
  }
  var covered = 0;
  for (var i = 0; i < plan.numberOfRows; i++) {
    covered += plan.lengths[i] * plan.widths[i];
  }
  final step = reaches.last - reaches.first;
  if (covered < floor - millimetre - plan.numberOfRows) {
    bad('coverage: rows reach ${covered.round()} mm² of a ${floor.round()} mm² floor, '
        'so some of it is left bare');
  }
  if (covered > floor + step * c.laminateWidth + plan.numberOfRows) {
    bad('coverage: rows reach ${covered.round()} mm² of a ${floor.round()} mm² floor, '
        'more than the one row across the cut can account for');
  }
}

int run(LRoomShape shape, Direction direction, int lamLength, int lamWidth, int indent,
    int minLen, int offset) {
  final cfg = 'room=${shape.length}x${shape.width} '
      'cut=${shape.notchLength}x${shape.notchWidth}@${shape.corner.name}, $direction, '
      'laminate=${lamLength}x$lamWidth, min=$minLen, offset=$offset, indent=$indent';
  final c = Calculation(
    shape: shape,
    laminateLength: lamLength,
    laminateWidth: lamWidth,
    planksInPack: 8,
    indentFromWall: indent,
    minimumLaminateLength: minLen,
    rowOffset: offset,
    direction: direction,
  );
  final plan = planFor(
    shape: shape,
    indentFromWall: indent,
    laminateLength: lamLength,
    laminateWidth: lamWidth,
    direction: direction,
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

  test('the rooms this feature exists for hold the invariants', () {
    // A living room with a boxed-in riser, a kitchen with a chimney breast,
    // and a studio with the hall cut out of one end.
    const rooms = [
      [4000, 3000, 1500, 1000],
      [5200, 3400, 900, 700],
      [6000, 4000, 2500, 1500],
      [3000, 2400, 1200, 800],
    ];
    for (final room in rooms) {
      for (final corner in RoomCorner.values) {
        for (final direction in [Direction.length, Direction.width]) {
          run(
            LRoomShape(
              length: room[0],
              width: room[1],
              notchLength: room[2],
              notchWidth: room[3],
              corner: corner,
            ),
            direction,
            1380,
            190,
            10,
            300,
            300,
          );
        }
      }
    }
    expect(violations, isEmpty, reason: report());
  });

  test('a cut smaller than one row still draws, and still balances', () {
    // The cut that changes nothing but the picture. The rows come out the
    // rectangle's, and the drawing has to clip the one row that reaches over
    // the cut without losing a plank or leaving a gap.
    for (final corner in RoomCorner.values) {
      for (final direction in [Direction.length, Direction.width]) {
        run(
          LRoomShape(
            length: 4000,
            width: 3000,
            notchLength: 600,
            notchWidth: 120,
            corner: corner,
          ),
          direction,
          1380,
          190,
          10,
          300,
          300,
        );
      }
    }
    expect(violations, isEmpty, reason: report());
  });

  test('a cut that leaves a corridor holds the invariants', () {
    // The other end of the range: almost all of the room taken out, leaving
    // two arms barely wider than the minimum room.
    for (final corner in RoomCorner.values) {
      run(
        LRoomShape(
          length: 6000,
          width: 4000,
          notchLength: 6000 - LRoomShape.minArmMm,
          notchWidth: 4000 - LRoomShape.minArmMm,
          corner: corner,
        ),
        Direction.length,
        1380,
        190,
        10,
        300,
        300,
      );
    }
    expect(violations, isEmpty, reason: report());
  });

  test('random rooms hold the invariants', () {
    final rnd = Random(20261002);
    var laid = 0;
    const runs = 400;
    for (var i = 0; i < runs; i++) {
      final length = rnd.nextInt(8001) + 2000;
      final width = rnd.nextInt(6001) + 2000;
      final shape = LRoomShape(
        length: length,
        width: width,
        notchLength: MIN_NOTCH_MM + rnd.nextInt(length - LRoomShape.minArmMm - MIN_NOTCH_MM),
        notchWidth: MIN_NOTCH_MM + rnd.nextInt(width - LRoomShape.minArmMm - MIN_NOTCH_MM),
        corner: RoomCorner.values[rnd.nextInt(4)],
      );
      if (shape.problem != null) continue;
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
      laid += run(
        shape,
        rnd.nextBool() ? Direction.length : Direction.width,
        lamLength,
        lamWidth,
        rnd.nextInt(3) * 5,
        minLen,
        offset,
      );
    }
    expect(violations, isEmpty, reason: report());
    // Not a specification, a tripwire: if the engine stops finding layouts for
    // rooms it used to lay, the search has lost its reach.
    expect(laid, greaterThan(runs ~/ 5), reason: 'only $laid of $runs rooms produced a layout');
  });
}
