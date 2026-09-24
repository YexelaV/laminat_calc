// The shape of the rows, independent of what gets laid in them. Straight and
// diagonal laying differ only in this file: everywhere downstream a row is a
// centreline length, a start position and a pair of end bevels.
import 'dart:math' as math;
import 'dart:math' show Point;

import 'models.dart';
import 'room_shape.dart';

/// The only place the 45° layout is rounded to millimetres.
///
/// Every length in a diagonal layout is some side over √2, and the validators
/// and the engine have to agree on it to the millimetre: feasibility is not
/// monotone in the minimum plank length, so a 1 mm disagreement flips it and
/// the user gets a green form that then reports no laying variants. Rounding
/// each side once here and deriving the rest with integer arithmetic is what
/// keeps them identical — see test/row_geometry_test.dart for the straight-
/// laying version of that bug.
int diagonalExtentMm(int sideMm) => (sideMm / math.sqrt2).round();

/// The narrowest strip still worth laying. A few millimetres of floor against
/// a corner cannot be cut and clicked into place, and the skirting board covers
/// it. Straight laying meets the same limit and evens the shortfall out between
/// the first row and the last; a 45° layout ends in a sliver at both corners
/// and has nothing to even out against, so the far corner is left bare.
const int minRowWidthMm = 50;

/// How many rows a 45° layout across [a] by [b] comes to.
///
/// The engine and the validators both need this and must not count for
/// themselves: a row either exists in both or in neither, or the form goes
/// green on a layout that then yields nothing.
int diagonalRowCount({required int a, required int b, required int laminateWidth}) {
  final extent = diagonalExtentMm(a) + diagonalExtentMm(b);
  final rows = (extent / laminateWidth).ceil();
  final last = extent - (rows - 1) * laminateWidth;
  return rows > 1 && last < minRowWidthMm ? rows - 1 : rows;
}

/// The rows of a layout, measured along the row axis.
///
/// All rows are parallel, so they share one coordinate `u`, and a joint at
/// `startU[i] + <centreline lengths before it>` can be compared directly with a
/// joint in the row above. That comparison is the whole point of the class:
/// for straight laying `startU` is all zeros and it degenerates into today's
/// "compare the first plank lengths".
class RowPlan {
  /// Centreline length of each row.
  final List<int> lengths;

  /// How wide each row actually is. Every row but the last is a full plank
  /// wide; the last one is whatever is left over against the far corner.
  final List<int> widths;

  /// Where each row begins on the shared `u` axis.
  final List<int> startU;

  /// `startU[i] - startU[i + 1]`, the amount the staircase drifts on its own
  /// between two rows before [rowOffset] is applied.
  final List<int> shift;

  /// Longest centreline a plank may have in the first and last slot of a row.
  /// A bevelled end has to be cut out of a full plank on the slant, so it costs
  /// reach — half a plank width for a 45° cut, less for a shallower one.
  final List<int> capFirst;
  final List<int> capLast;

  /// The cap for a plank that spans a whole row alone, bevelled at both ends.
  /// Both cuts are rounded together rather than one at a time: rounding twice
  /// would take a millimetre off a plank that has it.
  final List<int> capWhole;

  final List<Bevel> startBevel;
  final List<Bevel> endBevel;

  RowPlan._({
    required this.lengths,
    required this.widths,
    required this.startU,
    required this.shift,
    required this.capFirst,
    required this.capLast,
    required this.capWhole,
    required this.startBevel,
    required this.endBevel,
  });

  /// The caps follow from the ends, so no plan works them out for itself: a
  /// row's reach and the bevel the engine then cuts have to be the same number.
  factory RowPlan({
    required List<int> lengths,
    required List<int> widths,
    required List<int> startU,
    required List<int> shift,
    required List<Bevel> startBevel,
    required List<Bevel> endBevel,
    required int laminateLength,
    required int laminateWidth,
  }) {
    final rows = lengths.length;
    return RowPlan._(
      lengths: lengths,
      widths: widths,
      startU: startU,
      shift: shift,
      capFirst: [
        for (var i = 0; i < rows; i++) laminateLength - startBevel[i].reachMm(laminateWidth)
      ],
      capLast: [
        for (var i = 0; i < rows; i++) laminateLength - endBevel[i].reachMm(laminateWidth)
      ],
      capWhole: [
        for (var i = 0; i < rows; i++)
          laminateLength - Bevel(startBevel[i].slope.abs() + endBevel[i].slope.abs())
              .reachMm(laminateWidth)
      ],
      startBevel: startBevel,
      endBevel: endBevel,
    );
  }

  int get numberOfRows => lengths.length;

  /// True when every row is the same square-ended length, i.e. all the rows
  /// carry one grid of joints and the cheaper scalar reasoning still applies.
  ///
  /// Both halves matter. Rows that start together but run to different lengths
  /// — a room whose opposite walls are not parallel — share no grid either, and
  /// treating them as if they did makes [Calculation.check] insist on an exact
  /// step the rows cannot hold.
  bool get isUniform =>
      shift.every((s) => s == 0) && lengths.every((l) => l == lengths.first);
}

/// The rows a room is laid in. The single place a laying direction turns into
/// geometry: the engine and the field validators must agree to the millimetre,
/// so neither may derive the rows for itself.
///
/// A rectangle goes down a closed form of its own rather than through
/// [scanPlan]. Not because the walk cannot do it — test/scan_plan_test.dart
/// shows it does, and nearer the room than the closed form at that — but
/// because a rectangle is what every room was until walls could differ, and it
/// has to keep laying out to the same millimetre it always did.
RowPlan planFor({
  required RoomShape shape,
  required int indentFromWall,
  required int laminateLength,
  required int laminateWidth,
  required Direction direction,
}) {
  if (shape.isRectangular) {
    final a = shape.lengthNear - indentFromWall * 2;
    final b = shape.widthLeft - indentFromWall * 2;
    if (direction == Direction.diagonal) {
      return diagonalPlan(a: a, b: b, laminateLength: laminateLength, laminateWidth: laminateWidth);
    }
    return straightPlan(
      rowLength: direction == Direction.length ? a : b,
      across: direction == Direction.length ? b : a,
      laminateLength: laminateLength,
      laminateWidth: laminateWidth,
    );
  }
  final floor = shape.floor(indentFromWall);
  return scanPlan(
    // Rows are always drawn and cut running along `u`. Laying across the room
    // turns the room rather than the rows, and [drawnRoom] turns it the same
    // way on the drawing side — through the same [RoomShape.turned], so the two
    // cannot end up looking at different rooms.
    floor: direction == Direction.width ? shape.turned(floor) : floor,
    angle: direction == Direction.diagonal ? -math.pi / 4 : 0,
    laminateLength: laminateLength,
    laminateWidth: laminateWidth,
  );
}

/// Rows parallel to a wall: all the same length, square at both ends, and all
/// starting from the same place.
///
/// [across] is the room the other way. A whole number of planks rarely covers
/// it, and the shortfall is settled here rather than after the laying, because
/// how wide a row is ripped is a property of the room and not of what went into
/// it. The last row takes what is left; when that is too narrow to lay, the
/// first row gives up half of its own width so that the floor ends the same way
/// it begins and neither end is a sliver.
///
/// Only parallel walls can be evened out like this. A room whose opposite walls
/// are not parallel has nothing to share the shortfall with, and [scanPlan]
/// leaves the last strip as the geometry gives it.
RowPlan straightPlan({
  required int rowLength,
  required int across,
  required int laminateLength,
  required int laminateWidth,
}) {
  final numberOfRows = (across / laminateWidth).ceil();
  final widths = List.filled(numberOfRows, laminateWidth);
  final leftOver = laminateWidth - (laminateWidth * numberOfRows - across);
  if (leftOver >= minRowWidthMm) {
    widths[numberOfRows - 1] = leftOver;
  } else {
    final shared = (leftOver + laminateWidth) ~/ 2;
    widths[0] = shared;
    widths[numberOfRows - 1] = shared;
  }
  return RowPlan(
    lengths: List.filled(numberOfRows, rowLength),
    widths: widths,
    startU: List.filled(numberOfRows, 0),
    shift: List.filled(numberOfRows, 0),
    startBevel: List.filled(numberOfRows, Bevel.square),
    endBevel: List.filled(numberOfRows, Bevel.square),
    laminateLength: laminateLength,
    laminateWidth: laminateWidth,
  );
}

/// The rows a floor of any shape is laid in, found by walking a strip across
/// it.
///
/// One generalisation covering both of the closed forms above. The floor is
/// turned so that the rows run along `u`, then cut into strips a plank wide.
/// Where a strip's centreline crosses the floor is the row — how long it is and
/// where it starts — and how the walls lean at those two crossings is the slant
/// of its two ends. A rectangle laid parallel to a wall comes back with equal
/// lengths, equal starts and square ends; the same rectangle at 45° comes back
/// as [diagonalPlan] draws it, to within the millimetre the two roundings differ
/// by (test/scan_plan_test.dart holds them to that).
///
/// [angle] is the direction the rows run in, measured the way the drawing
/// measures it: 0 along the room's length, −π/4 for a 45° layout.
///
/// A row is measured at the middle of the part of its strip that is inside the
/// floor, for the reason [diagonalPlan] gives: the last strip is a sliver
/// against a corner, and measured at the strip's own centre it can come out
/// empty while there is still floor to lay.
RowPlan scanPlan({
  required List<Point<double>> floor,
  required double angle,
  required int laminateLength,
  required int laminateWidth,
}) {
  final w = laminateWidth;
  final rotated = rowFrame(floor, angle);
  var uMin = double.infinity;
  var vMin = double.infinity;
  var vMax = double.negativeInfinity;
  for (final corner in rotated) {
    uMin = math.min(uMin, corner.x);
    vMin = math.min(vMin, corner.y);
    vMax = math.max(vMax, corner.y);
  }

  final extent = vMax - vMin;
  var rows = (extent / w).ceil();
  // The same sliver rule the 45° layout has always used. A shortfall cannot be
  // shared out between the first row and the last here: the walls those two lie
  // against are not parallel, so there is nothing to share it with.
  if (rows > 1 && extent - (rows - 1) * w < minRowWidthMm) rows--;

  final lengths = <int>[];
  final widths = <int>[];
  final startU = <int>[];
  final startBevel = <Bevel>[];
  final endBevel = <Bevel>[];
  for (var i = 0; i < rows; i++) {
    final vLo = vMin + i * w;
    final vHi = math.min(vMin + (i + 1) * w, vMax);
    final span = spanAt(rotated, (vLo + vHi) / 2);
    lengths.add(span == null ? 0 : math.max(0, span.length.round()));
    widths.add((vHi - vLo).round());
    startU.add(span == null ? 0 : (span.lo - uMin).round());
    // The plank's end follows the wall, so its far corner leads by as much as
    // the wall leans. At the start of the row the wall leans away from the row
    // and at the end towards it, which is where the sign comes from.
    startBevel.add(span == null ? Bevel.square : Bevel.fromLean(-span.loLean, w));
    endBevel.add(span == null ? Bevel.square : Bevel.fromLean(span.hiLean, w));
  }

  final shift = <int>[];
  for (var i = 0; i < rows; i++) {
    shift.add(i + 1 < rows ? startU[i] - startU[i + 1] : 0);
  }

  return RowPlan(
    lengths: lengths,
    widths: widths,
    startU: startU,
    shift: shift,
    startBevel: startBevel,
    endBevel: endBevel,
    laminateLength: laminateLength,
    laminateWidth: w,
  );
}

/// [polygon] turned so that rows running at [angle] run along `u`, which the
/// result carries as `x`, with `v` across them as `y`.
///
/// The drawing turns it back by the same angle, so the two share this.
List<Point<double>> rowFrame(List<Point<double>> polygon, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  return [
    for (final p in polygon) Point(p.x * c + p.y * s, -p.x * s + p.y * c),
  ];
}

/// Rows at 45° across a room of [a] by [b] (already inset from the walls).
///
/// Measuring rows by the perpendicular coordinate τ from the corner the layout
/// starts at, a row's centreline length is
///
///     ℓ(τ) = min(2τ, 2·min(a, b)/√2, 2(E − τ)),   E = (a + b)/√2
///
/// — it grows at 2 mm of row per mm of τ while both ends still run into the
/// same pair of walls, holds flat while one end has turned the corner and the
/// other has not, then falls at the same rate. The two corners are turned at
/// τ = b/√2 (the starting end) and τ = a/√2 (the finishing end), independently,
/// which is why the plateau exists at all and why it vanishes when a == b.
///
/// The starting end is also what makes the rows drift: its distance along the
/// row axis is |τ − b/√2|, so it walks towards the corner one plank width per
/// row, then away from it. That sign change happens exactly once.
RowPlan diagonalPlan({
  required int a,
  required int b,
  required int laminateLength,
  required int laminateWidth,
}) {
  final w = laminateWidth;
  // τ at which each end turns its corner. Rounded here and nowhere else.
  final kEnd = diagonalExtentMm(a);
  final kStart = diagonalExtentMm(b);
  final extent = kStart + kEnd;
  final plateau = 2 * math.min<int>(kStart, kEnd);

  final rows = diagonalRowCount(a: a, b: b, laminateWidth: w);
  final lengths = <int>[];
  final widths = <int>[];
  final startU = <int>[];
  final startBevel = <Bevel>[];
  final endBevel = <Bevel>[];

  for (var i = 0; i < rows; i++) {
    // A row is measured at the middle of the part of its strip that is inside
    // the room, not at the middle of the strip. The two coincide everywhere but
    // in the last row, which is a sliver against the far corner: measured at the
    // strip centre it can come out empty while there is still material to lay.
    // Since the chord falls off linearly there, the middle of the occupied part
    // gives exactly the strip's area over its width.
    final from = i * w;
    final to = math.min<int>((i + 1) * w, extent);
    // Twice the centreline coordinate, so the half-width offset stays integral.
    final twoTau = from + to;
    final length = math.min<int>(twoTau, math.min<int>(plateau, 2 * extent - twoTau));
    lengths.add(length < 0 ? 0 : length);
    widths.add(to - from);
    startU.add(((twoTau - 2 * kStart).abs() / 2).round());
    startBevel.add(twoTau < 2 * kStart ? Bevel.up : Bevel.down);
    endBevel.add(twoTau < 2 * kEnd ? Bevel.up : Bevel.down);
  }

  final shift = <int>[];
  for (var i = 0; i < rows; i++) {
    shift.add(i + 1 < rows ? startU[i] - startU[i + 1] : 0);
  }

  return RowPlan(
    lengths: lengths,
    widths: widths,
    startU: startU,
    shift: shift,
    startBevel: startBevel,
    endBevel: endBevel,
    laminateLength: laminateLength,
    laminateWidth: w,
  );
}
