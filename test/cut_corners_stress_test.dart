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

/// Where the floor starts, where it ends and how far it reaches, in each band
/// between corners. One band per step; a room with n notches has at most n + 1
/// of them.
class _Bands {
  final List<double> lefts;
  final List<double> rights;
  final List<double> reaches;

  const _Bands(this.lefts, this.rights, this.reaches);

  bool get isEmpty => reaches.isEmpty;
}

_Bands _bands(List<Point<double>> floor) {
  final lefts = <double>{};
  final rights = <double>{};
  final reaches = <double>{};
  final vs = floor.map((p) => p.y).toSet().toList()..sort();
  for (var i = 0; i + 1 < vs.length; i++) {
    final span = spanAt(floor, (vs[i] + vs[i + 1]) / 2);
    if (span == null) continue;
    lefts.add(span.lo);
    rights.add(span.hi);
    reaches.add(span.length);
  }
  return _Bands(lefts.toList()..sort(), rights.toList()..sort(),
      reaches.toList()..sort());
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
    // Every wall is square to the rows, so the floor starts, ends and reaches a
    // handful of discrete distances across, one per band between steps.
    final bands = _bands(rotated);
    if (bands.isEmpty) {
      bad('the floor has no reach at all');
      return;
    }
    final reaches = bands.reaches;
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
    // A row begins at a wall the floor has and ends at one — each end on its
    // own, which is the whole of what a room of square walls allows.
    //
    // Not "the row is one of the reaches the floor has", which is what this
    // said while every room tried had its steps at one end or spread far apart.
    // A row whose strip holds a step at *each* end — a Z with its two inside
    // corners a plank's width apart — reaches from the left wall of one band to
    // the right wall of another, and is longer than the floor is at any single
    // height in it. That is the only row that covers the strip: laid to either
    // band's reach it leaves a ribbon of real floor bare against a wall, and the
    // coverage bounds above are what say so. The board is notched at both ends
    // instead, which is what a fitter does at one.
    // [RowPlan.startU] is measured from the leftmost the floor reaches, so the
    // walls it is compared against are measured from there too.
    final uMin = rotated.map((p) => p.x).reduce(min);
    for (var i = 0; i < plan.numberOfRows; i++) {
      final from = uMin + plan.startU[i];
      final to = from + plan.lengths[i];
      if (!bands.lefts.any((wall) => (from - wall).abs() <= 1)) {
        bad('row $i: starts at ${from.round()} mm, where the floor has no wall '
            '(${bands.lefts.map((w) => w.round()).join(" / ")})');
      }
      if (!bands.rights.any((wall) => (to - wall).abs() <= 1)) {
        bad('row $i: ends at ${to.round()} mm, where the floor has no wall '
            '(${bands.rights.map((w) => w.round()).join(" / ")})');
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

/// Lays one room one way and holds the result to the invariants.
///
/// Takes an outline rather than a [CutCornersRoomShape] so that the room whose
/// piece is out of a *wall* can be run through the same stand: what the checks
/// need of a room is that every wall be square to the rows, and that is
/// [RoomOutline.isRectilinear], which both kinds answer for themselves.
int run(RoomOutline shape, String name, Direction direction, int lamLength,
    int lamWidth, int indent, int minLen, int offset) {
  final cfg = '$name, $direction, laminate=${lamLength}x$lamWidth, '
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
      checkResult(cfg, c, r, plan, shape.isRectilinear);
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
              'room=${room[0]}x${room[1]} ${entry.key} notch',
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

  test('a Z lays out however its two cuts are sized', () {
    // The pair that shares no wall, which is the shape the form grew a tile for
    // and the one [make] cannot build: its two cuts are their own sizes, and
    // nothing on any wall holds them apart. The third fixture is the far end of
    // what that allows — two cuts as deep along the room as a lone cut may be,
    // passing each other across it — and it is the one most likely to break a
    // row, because the rows beside either cut are as short as a room gets.
    var laid = 0;
    for (final room in const [
      // length, width, then along and across for each of the two cuts
      [4000, 3000, 900, 700, 1500, 1100],
      [5200, 3400, 1600, 900, 800, 1300],
      [6000, 4000, 5500, 900, 5500, 900],
      [3000, 2400, 700, 1900, 1200, 400],
    ]) {
      for (final pair in const [
        [RoomCorner.nearLeft, RoomCorner.farRight],
        [RoomCorner.nearRight, RoomCorner.farLeft],
      ]) {
        final shape = CutCornersRoomShape(
          length: room[0],
          width: room[1],
          cut: CornerCut.notch,
          cuts: {
            pair[0]: CornerSize(along: room[2], across: room[3]),
            pair[1]: CornerSize(along: room[4], across: room[5]),
          },
        );
        expect(shape.problem, isNull, reason: '$room $pair');
        for (final direction in [Direction.length, Direction.width]) {
          laid += run(shape, 'room=${room[0]}x${room[1]} a Z', direction, 1380, 190, 10, 300, 300);
        }
      }
    }
    expect(violations, isEmpty, reason: report());
    expect(laid, greaterThan(0), reason: 'a Z must actually lay out');
  });

  test('a notch in the middle of a wall lays out across that wall', () {
    // The room the whole shape was added for, and the one claim it rests on:
    // laid across the notched wall the engine needs nothing it does not already
    // do. Every wall, both ends of the notch apart, and depths from a nick to
    // most of the room.
    final rnd = Random(20261008);
    var laid = 0;
    var refused = 0;
    for (var i = 0; i < 200; i++) {
      final length = 1500 + rnd.nextInt(6000);
      final width = 1200 + rnd.nextInt(4000);
      final wall = RoomWall.values[rnd.nextInt(4)];
      final along = wall.runsAlongLength ? length : width;
      final across = wall.runsAlongLength ? width : length;
      // The two ends share the wall with the notch between them, so a third of
      // it each leaves a third for the notch whatever lands where.
      int end() => MIN_NOTCH_MM + rnd.nextInt(max(1, along ~/ 3 - MIN_NOTCH_MM) + 1);
      final shape = WallNotchRoomShape(
        length: length,
        width: width,
        wall: wall,
        offsetFirst: end(),
        offsetSecond: end(),
        depth: MIN_NOTCH_MM +
            rnd.nextInt(max(1, across - MIN_ROOM_MM - MIN_NOTCH_MM) + 1),
      );
      if (shape.problem != null) {
        refused++;
        continue;
      }
      // The one direction such a room takes. The other parts every row that
      // meets the notch in two, which is why it is not offered.
      final direction =
          shape.takesAlongLength ? Direction.length : Direction.width;
      expect(shape.takesAlongLength, isNot(shape.takesAcrossWidth),
          reason: 'exactly one of the two, always');
      laid += run(
          shape,
          'room=${length}x$width notch in the $wall',
          direction,
          1200 + rnd.nextInt(600),
          120 + rnd.nextInt(120),
          8 + rnd.nextInt(5),
          250 + rnd.nextInt(150),
          250 + rnd.nextInt(200));
    }
    expect(violations, isEmpty, reason: report());
    expect(laid, greaterThan(100), reason: 'most of these rooms must lay out');
    expect(refused, lessThan(60), reason: 'and the generator must mostly make rooms');
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
              'room=${room[0]}x${room[1]} chamfer', direction, 1380, 190, 10, 300, 300);
        }
      }
    }
    expect(violations, isEmpty, reason: report());
    expect(laid, greaterThan(0), reason: 'a chamfered room must lay out at all');
  });

  test('random rooms hold the invariants', () {
    final rnd = Random(20261004);
    var tried = 0;
    var refused = 0;
    for (var i = 0; i < 240; i++) {
      final length = 1500 + rnd.nextInt(6000);
      final width = 1200 + rnd.nextInt(4000);
      final cut = CornerCut.values[rnd.nextInt(2)];
      final corners = <RoomCorner>[];
      for (final corner in RoomCorner.values) {
        if (rnd.nextBool()) corners.add(corner);
      }
      if (corners.isEmpty) corners.add(RoomCorner.values[rnd.nextInt(4)]);
      // A size of its own per cut, drawn from the whole of what a lone cut may
      // be. This used to be one size for all of them, capped at a quarter of
      // the side, which kept every pair clear of every other by construction —
      // and so never generated the thing worth generating: cuts that reach past
      // one another, and cuts that reach too far. [problem] is what sorts the
      // two, so a shape it turns down is counted and skipped rather than laid.
      int leg(int side) =>
          MIN_NOTCH_MM + rnd.nextInt(side - MIN_ROOM_MM - MIN_NOTCH_MM + 1);
      final shape = CutCornersRoomShape(
        length: length,
        width: width,
        cut: cut,
        cuts: {
          for (final corner in corners)
            corner: CornerSize(along: leg(length), across: leg(width))
        },
      );
      if (shape.problem != null) {
        refused++;
        continue;
      }
      tried++;
      final direction = cut == CornerCut.chamfer
          ? Direction.values[rnd.nextInt(3)]
          : [Direction.length, Direction.width][rnd.nextInt(2)];
      run(shape, 'room=${length}x$width random ${corners.length} cut', direction,
          1200 + rnd.nextInt(600),
          120 + rnd.nextInt(120), 8 + rnd.nextInt(5), 250 + rnd.nextInt(150),
          250 + rnd.nextInt(200));
    }
    expect(violations, isEmpty, reason: report());
    // Both counts, so that the run cannot go quiet by refusing everything or by
    // never putting two cuts near enough to each other to be refused.
    expect(tried, greaterThan(40), reason: 'too few rooms survived the bounds');
    expect(refused, greaterThan(40), reason: 'the bounds were never reached');
  });
}
