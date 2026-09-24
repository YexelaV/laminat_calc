// The invariants of a room whose walls are not all square to each other, over
// many rooms and all three laying directions.
//
// Nothing here says which rooms must produce a layout — like the 45° case, the
// rows differ in length and whether a joint pattern exists is a search rather
// than a formula. What it says is that whatever comes out is a floor a fitter
// could cut and lay: the planks add up to the rows, the rows add up to the
// floor, every plank is inside the walls, the joints keep their distance, and
// the material balances.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/row_plan.dart';
import 'package:floor_calculator/scheme_geometry.dart';
import 'package:floor_calculator/utils/units.dart';

final violations = <String>[];

double _area(List<Offset> polygon) {
  var sum = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final from = polygon[i];
    final to = polygon[(i + 1) % polygon.length];
    sum += from.dx * to.dy - to.dx * from.dy;
  }
  return sum.abs() / 2;
}

/// How far inside [polygon] a point is; negative when it is out.
double _depthInside(Offset point, List<Offset> polygon) {
  final normals = normalsOf(polygon);
  var least = double.infinity;
  for (var i = 0; i < polygon.length; i++) {
    final depth = (point.dx - polygon[i].dx) * normals[i].dx +
        (point.dy - polygon[i].dy) * normals[i].dy;
    least = min(least, depth);
  }
  return least;
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

    for (var j = 0; j < planks.length; j++) {
      final p = planks[j];
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

  final used = r.lines.fold<int>(0, (s, l) => s + l.planks.fold<int>(0, (t, p) => t + p.length));
  final left = r.pieces.fold<int>(0, (s, p) => s + p.length);
  final waste = r.trash.fold<int>(0, (s, p) => s + p.length);
  final bought = r.totalPlanks * c.laminateLength;
  if (used + left + waste != bought) {
    bad('balance: laid $used + pieces $left + waste $waste != bought $bought');
  }

  // The drawing is where a wrong outline shows: a plank whose end runs past a
  // slanted wall is invisible in the lengths and obvious here.
  final scheme = buildScheme(r, system: MeasurementSystem.metric, minTextMm: 3);
  for (final shape in scheme.planks) {
    for (final point in shape.outline) {
      final depth = _depthInside(point, scheme.room);
      if (depth < -0.5) {
        bad('plank ${shape.plank.number}: a corner is ${(-depth).toStringAsFixed(1)} mm '
            'outside the walls');
        break;
      }
    }
  }

  // Every row is as long as the floor is wide somewhere inside its own strip.
  //
  // Not "as long as the strip's area over its width": a row is measured on its
  // centreline, which is the model the 45° layout has always used, and where a
  // corner of the room falls inside a strip the centreline is longer than the
  // average. That overstates the material for that one row, always upwards —
  // the buyer is never short — and it is what keeps the plank count honest,
  // which is the number being bought. What would be wrong is a row longer than
  // the floor ever is across its strip, or shorter than it is at both edges.
  final floorPolygon = drawnFloor(r);
  final rotated = rowFrame([for (final p in floorPolygon) Point(p.dx, p.dy)],
      r.direction == Direction.diagonal ? -pi / 4 : 0.0);
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

  // And the rows between them still have to reach most of the floor, or the
  // walk has lost a strip somewhere.
  final floor = _area(floorPolygon);
  final covered = r.lines.fold<double>(
      0, (s, l) => s + plan.lengths[l.number] * plan.widths[l.number].toDouble());
  if (covered < floor * 0.9) {
    bad('coverage: rows reach ${covered.round()} mm² of a ${floor.round()} mm² floor');
  }
}

int run(RoomShape shape, Direction direction, int lamLength, int lamWidth, int indent, int minLen,
    int offset) {
  final cfg = 'room=${shape.lengthNear}/${shape.lengthFar}/${shape.widthLeft}/'
      '${shape.widthRight} diag=${shape.diagonal}, $direction, '
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

/// A room measured wall by wall, with the diagonal pulled [skew] millimetres
/// off the one a rectangle would have and clamped to what the walls can close
/// round.
RoomShape shapeOf(int near, int far, int left, int right, int skew) {
  final low = RoomShape.minDiagonal(
      lengthNear: near, lengthFar: far, widthLeft: left, widthRight: right);
  final high = RoomShape.maxDiagonal(
      lengthNear: near, lengthFar: far, widthLeft: left, widthRight: right);
  return RoomShape(
    lengthNear: near,
    lengthFar: far,
    widthLeft: left,
    widthRight: right,
    diagonal: (RoomShape.rectangleDiagonal(near, left) + skew).clamp(low, high),
  );
}

void main() {
  setUp(violations.clear);

  test('a room measured wall by wall holds the invariants', () {
    // The room this feature exists for: a tape measure round a living room.
    final real = shapeOf(5010, 4980, 3000, 3025, 0);
    expect(real.problem, isNull);
    for (final direction in Direction.values) {
      run(real, direction, 1380, 190, 10, 300, 300);
    }
    // Rooms a builder would call badly out of square, to show nothing here is a
    // small-angle approximation.
    for (final direction in Direction.values) {
      run(shapeOf(6000, 5600, 4000, 4300, 120), direction, 1380, 190, 10, 300, 300);
      run(shapeOf(3000, 3200, 2500, 2400, -80), direction, 1285, 192, 10, 300, 300);
      run(shapeOf(4000, 4000, 4000, 4000, 60), direction, 1380, 190, 10, 300, 300);
    }
    expect(violations, isEmpty, reason: report());
  });

  test('a room whose walls happen to be equal still lays out like a rectangle', () {
    // The diagonal is the only thing separating this from a rectangle, and one
    // millimetre of it sends the room down the general path. The two must not
    // disagree about how much floor there is to cover.
    for (final direction in Direction.values) {
      run(shapeOf(5000, 5000, 4000, 4000, 1), direction, 1380, 190, 10, 300, 300);
      run(shapeOf(5000, 5000, 4000, 4000, -1), direction, 1380, 190, 10, 300, 300);
    }
    expect(violations, isEmpty, reason: report());
  });

  test('random rooms hold the invariants', () {
    final rnd = Random(20260907);
    var laid = 0;
    const runs = 400;
    for (var i = 0; i < runs; i++) {
      final near = rnd.nextInt(8001) + 2000;
      final left = rnd.nextInt(6001) + 2000;
      // Opposite walls within a twentieth of each other: past that it is not a
      // room measured carefully, it is a room measured wrong.
      int nudge(int side) => side + rnd.nextInt(side ~/ 10 + 1) - side ~/ 20;
      final shape = shapeOf(near, nudge(near), left, nudge(left), rnd.nextInt(201) - 100);
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
      laid += run(shape, Direction.values[rnd.nextInt(3)], lamLength, lamWidth,
          rnd.nextInt(3) * 5, minLen, offset);
    }
    expect(violations, isEmpty, reason: report());
    // Not a specification, a tripwire: if the engine stops finding layouts for
    // rooms it used to lay, the search has lost its reach.
    expect(laid, greaterThan(runs ~/ 5), reason: 'only $laid of $runs rooms produced a layout');
  });
}
