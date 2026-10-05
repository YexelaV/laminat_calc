// The invariants of a room with more than one corner taken off it, over many
// rooms, both laying directions and every arrangement of cuts.
//
// test/l_shape_stress_test.dart says the same things about a single notch, and
// says them more tightly: with one cut the floor has exactly two reaches and
// exactly one row steps between them, so the coverage bound can name the one
// row that is allowed to overshoot. With several cuts there are several steps,
// and the bound widens to the sum of them — still a bound, still far smaller
// than a missing row, but no longer a single named row.
//
// The chamfered rooms are here for a different reason. They go down [scanPlan],
// the path a room with four unequal walls has always taken, so what is new
// about them is the outline and not the arithmetic. They are checked for the
// things an outline can get wrong — planks outside the walls, floor left bare,
// material that does not balance — and not for reaches, which a slanted wall
// makes continuous.
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

/// Every length the floor takes across the rows, and so every length a row may
/// come out. One per band between corners; a room with n notches has at most
/// n + 1 of them.
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

void checkResult(String cfg, Calculation c, Result r, RowPlan plan, bool square) {
  void bad(String message) => violations.add('$message  [$cfg]');

  if (r.lines.length != plan.numberOfRows) {
    bad('rows: laid ${r.lines.length} != planned ${plan.numberOfRows}');
    return;
  }
  for (var i = 0; i < r.lines.length; i++) {
    final planks = r.lines[i].planks;
    if (r.lines[i].startOffsetMm != plan.startU[i]) {
      bad('row $i: start ${r.lines[i].startOffsetMm} != planned ${plan.startU[i]}');
    }
    final sum = planks.fold<int>(0, (s, p) => s + p.length);
    if (sum != plan.lengths[i]) {
      bad('row $i: planks sum $sum != row length ${plan.lengths[i]}');
    }
    // Every wall of a notched room is square to the rows, so nothing is cut on
    // the slant. A chamfer is the one wall that is not, and rows that reach it
    // are bevelled on purpose.
    if (square && (!plan.startBevel[i].isSquare || !plan.endBevel[i].isSquare)) {
      bad('row $i: ends ${plan.startBevel[i]}/${plan.endBevel[i]} are not square');
    }
    for (final plank in planks) {
      if (plank.length < c.minimumLaminateLength && plank.length != plan.lengths[i]) {
        bad('row $i: a plank of ${plank.length} is under the minimum');
      }
    }
  }

  final used =
      r.lines.fold<int>(0, (s, l) => s + l.planks.fold<int>(0, (t, p) => t + p.length));
  final left = r.pieces.fold<int>(0, (s, p) => s + p.length);
  final waste = r.trash.fold<int>(0, (s, p) => s + p.length);
  final bought = r.totalPlanks * c.laminateLength;
  if (used + left + waste != bought) {
    bad('balance: laid $used + pieces $left + waste $waste != bought $bought');
  }

  // The drawing is where a wrong outline shows. A plank reaching into a cut is
  // invisible in the lengths and obvious here.
  final scheme = buildScheme(r, system: MeasurementSystem.metric, minTextMm: 3);
  final walls = LaidFloor(scheme.room);
  var drawn = 0.0;
  for (final shape in scheme.planks) {
    if (shape.outline.isEmpty) {
      bad('plank ${shape.plank.number}: cut away to nothing');
      continue;
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
  final rotated = rowFrame([for (final p in floorPolygon) Point(p.dx, p.dy)],
      r.direction == Direction.diagonal ? -pi / 4 : 0.0);

  var covered = 0;
  for (var i = 0; i < plan.numberOfRows; i++) {
    covered += plan.lengths[i] * plan.widths[i];
  }

  if (square) {
    // Every wall is square to the rows, so the floor takes a handful of
    // discrete lengths across and each row must be laid to one of them.
    final reaches = _reaches(rotated);
    if (reaches.isEmpty) {
      bad('the floor has no reach at all');
      return;
    }
    // What the drawing may leave uncovered: a strip one millimetre deep along
    // the far wall, the width of the room. [rowWidths] halves the shortfall
    // between the first row and the last, and half of an odd number of
    // millimetres is not a whole one — a rectangle ends the same millimetre
    // short. What this is watching for is a *row* missing, which is orders of
    // magnitude bigger.
    final millimetre = reaches.last;
    if (drawn > floor + 1 || drawn < floor - millimetre - 1) {
      bad('drawing: planks cover ${drawn.round()} mm² of a ${floor.round()} mm² floor');
    }
    if (covered < floor - millimetre - plan.numberOfRows) {
      bad('coverage: rows reach ${covered.round()} mm² of a ${floor.round()} mm² floor, '
          'so some of it is left bare');
    }
    for (var i = 0; i < plan.numberOfRows; i++) {
      final length = plan.lengths[i].toDouble();
      if (!reaches.any((reach) => (length - reach).abs() <= 1)) {
        bad('row $i: ${plan.lengths[i]} mm is no reach the floor has '
            '(${reaches.map((reach) => reach.round()).join(" / ")})');
      }
    }
    // Each step may cost one row an overshoot, and none may cost more: a row
    // laid to the wider of two reaches runs that far past the step, which is
    // what a fitter does anyway, notching the board round the inside corner.
    final steps = reaches.last - reaches.first;
    if (covered > floor + steps * c.laminateWidth * reaches.length + plan.numberOfRows) {
      bad('coverage: rows reach ${covered.round()} mm² of a ${floor.round()} mm² floor, '
          'more than the rows across the cuts can account for');
    }
    return;
  }

  // A chamfer puts a wall at an angle to the rows, and the reaches stop being
  // discrete: every row that meets the cut is a different length. So the bound
  // moves from the floor as a whole to each row against its own strip, which is
  // how test/uneven_stress_test.dart has always bounded a slanted wall.
  //
  // The total is deliberately not held to the floor here. [Bevel.fromLean]
  // refuses to cut an end steeper than 45° however steeply the wall runs —
  // past that the cut runs along the plank rather than across it, which is a
  // rip and not an end cut — so a cut wall steeper than 45° to the rows leaves
  // a shallow wedge of floor bare along it for the skirting board to cover.
  // That is the documented bargain, not a miscalculation, and it is why the
  // slack below is the same 10% that suite allows.
  var vMin = double.infinity;
  var vMax = double.negativeInfinity;
  for (final corner in rotated) {
    vMin = min(vMin, corner.y);
    vMax = max(vMax, corner.y);
  }
  for (var i = 0; i < plan.numberOfRows; i++) {
    final vLo = vMin + i * c.laminateWidth;
    final vHi = min(vMin + (i + 1) * c.laminateWidth, vMax);
    // The chord is piecewise linear in v, so its extremes over the strip are at
    // the strip's edges or at a corner of the room inside it.
    final marks = <double>[
      vLo,
      vHi,
      for (final corner in rotated)
        if (corner.y > vLo && corner.y < vHi) corner.y,
    ];
    var longest = 0.0;
    var atEdges = double.infinity;
    for (final v in marks) {
      final span = spanAt(rotated, v);
      final chord = span == null ? 0.0 : span.length;
      longest = max(longest, chord);
      if (v == vLo || v == vHi) atEdges = min(atEdges, chord);
    }
    if (plan.lengths[i] > longest + 1) {
      bad('row $i: ${plan.lengths[i]} mm is longer than the floor ever is '
          'across its strip (${longest.round()} mm)');
    }
    if (plan.lengths[i] < atEdges - 1) {
      bad('row $i: ${plan.lengths[i]} mm is shorter than the floor is at both '
          'edges of its strip (${atEdges.round()} mm)');
    }
  }
  if (covered < floor * 0.9) {
    bad('coverage: rows reach ${covered.round()} mm² of a ${floor.round()} mm² floor');
  }
}

int run(CutCornersRoomShape shape, String name, Direction direction, int lamLength,
    int lamWidth, int indent, int minLen, int offset) {
  final cfg = 'room=${shape.length}x${shape.width} $name '
      '${shape.cut.name}, $direction, laminate=${lamLength}x$lamWidth, '
      'min=$minLen, offset=$offset, indent=$indent';
  if (shape.problem != null) {
    violations.add('the fixture is not a room: ${shape.problem}  [$cfg]');
    return 0;
  }
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
      checkResult(cfg, c, r, plan, shape.cut == CornerCut.notch);
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

/// The arrangements a fitter would recognise, and the names they go by.
const arrangements = <String, List<RoomCorner>>{
  'a T': [RoomCorner.nearLeft, RoomCorner.nearRight],
  'a U on its side': [RoomCorner.nearLeft, RoomCorner.farLeft],
  'a Z': [RoomCorner.nearLeft, RoomCorner.farRight],
  'three cut': [RoomCorner.nearLeft, RoomCorner.nearRight, RoomCorner.farLeft],
  'all four cut': RoomCorner.values,
};

void main() {
  setUp(violations.clear);

  CutCornersRoomShape make(
          List<int> room, List<RoomCorner> corners, CornerCut cut, int a, int b) =>
      CutCornersRoomShape(
        length: room[0],
        width: room[1],
        cut: cut,
        cuts: {
          for (final corner in corners) corner: CornerSize(along: a, across: b)
        },
      );

  test('the rooms this feature exists for hold the invariants', () {
    // A living room with a boxed-in riser at each end of one wall, a kitchen
    // with two chimney breasts, a studio with the hall cut out of one corner
    // and a cupboard out of another.
    const rooms = [
      [4000, 3000, 900, 700],
      [5200, 3400, 1100, 800],
      [6000, 4000, 1500, 1000],
      [3000, 2400, 700, 500],
    ];
    var laid = 0;
    var tried = 0;
    for (final room in rooms) {
      for (final entry in arrangements.entries) {
        for (final direction in [Direction.length, Direction.width]) {
          tried++;
          laid += run(
              make(room, entry.value, CornerCut.notch, room[2], room[3]),
              entry.key,
              direction,
              1380,
              190,
              10,
              300,
              300);
        }
      }
    }
    expect(violations, isEmpty, reason: report());
    expect(laid, greaterThan(tried ~/ 2),
        reason: 'most of these rooms must actually lay out');
  });

  test('a chamfered room lays out, and at 45° as well', () {
    // The whole point of a chamfer: it leaves the room convex, so the 45°
    // layout a notch has to give up is still on offer.
    var laid = 0;
    for (final room in const [
      [4000, 3000, 900, 1200],
      [5200, 3400, 1500, 1000],
      [3000, 2400, 600, 800],
    ]) {
      for (final corners in const [
        [RoomCorner.farRight],
        [RoomCorner.nearLeft, RoomCorner.nearRight],
        [RoomCorner.nearLeft, RoomCorner.farRight],
      ]) {
        for (final direction in Direction.values) {
          laid += run(make(room, corners, CornerCut.chamfer, room[2], room[3]),
              'chamfer', direction, 1380, 190, 10, 300, 300);
        }
      }
    }
    expect(violations, isEmpty, reason: report());
    expect(laid, greaterThan(0), reason: 'a chamfered room must lay out at all');
  });

  test('random rooms hold the invariants', () {
    final rnd = Random(20261004);
    for (var i = 0; i < 160; i++) {
      final length = 1500 + rnd.nextInt(6000);
      final width = 1200 + rnd.nextInt(4000);
      final cut = CornerCut.values[rnd.nextInt(2)];
      final corners = <RoomCorner>[];
      for (final corner in RoomCorner.values) {
        if (rnd.nextBool()) corners.add(corner);
      }
      if (corners.isEmpty) corners.add(RoomCorner.values[rnd.nextInt(4)]);
      // Each wall carries at most two cuts, so a quarter of it each leaves the
      // arm every bound asks for whatever lands where.
      final a = MIN_NOTCH_MM + rnd.nextInt((length ~/ 4) - MIN_NOTCH_MM + 1);
      final b = MIN_NOTCH_MM + rnd.nextInt((width ~/ 4) - MIN_NOTCH_MM + 1);
      final shape = CutCornersRoomShape(
        length: length,
        width: width,
        cut: cut,
        cuts: {
          for (final corner in corners) corner: CornerSize(along: a, across: b)
        },
      );
      final direction = cut == CornerCut.chamfer
          ? Direction.values[rnd.nextInt(3)]
          : [Direction.length, Direction.width][rnd.nextInt(2)];
      run(shape, 'random ${corners.length} cut', direction, 1200 + rnd.nextInt(600),
          120 + rnd.nextInt(120), 8 + rnd.nextInt(5), 250 + rnd.nextInt(150),
          250 + rnd.nextInt(200));
    }
    expect(violations, isEmpty, reason: report());
  });
}
