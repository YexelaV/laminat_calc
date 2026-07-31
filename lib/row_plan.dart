// The shape of the rows, independent of what gets laid in them. Straight and
// diagonal laying differ only in this file: everywhere downstream a row is a
// centreline length, a start position and a pair of end bevels.
import 'dart:math' as math;

import 'models.dart';

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
  /// half a plank width of reach.
  final List<int> capFirst;
  final List<int> capLast;

  /// The cap for a plank that spans a whole row alone, bevelled at both ends.
  final List<int> capWhole;

  final List<Bevel> startBevel;
  final List<Bevel> endBevel;

  RowPlan({
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

  int get numberOfRows => lengths.length;

  /// True when every row is the same square-ended length, i.e. this is straight
  /// laying and the cheaper scalar reasoning still applies.
  bool get isUniform => shift.every((s) => s == 0);
}

/// The rows a room is laid in. The single place a laying direction turns into
/// geometry: the engine and the field validators must agree to the millimetre,
/// so neither may derive the rows for itself.
RowPlan planFor({
  required int roomLength,
  required int roomWidth,
  required int indentFromWall,
  required int laminateLength,
  required int laminateWidth,
  required Direction direction,
}) {
  final a = roomLength - indentFromWall * 2;
  final b = roomWidth - indentFromWall * 2;
  if (direction == Direction.diagonal) {
    return diagonalPlan(a: a, b: b, laminateLength: laminateLength, laminateWidth: laminateWidth);
  }
  final along = direction == Direction.length ? a : b;
  final across = direction == Direction.length ? b : a;
  return straightPlan(
    rowLength: along,
    numberOfRows: (across / laminateWidth).ceil(),
    laminateLength: laminateLength,
    laminateWidth: laminateWidth,
  );
}

/// Rows parallel to a wall: all the same length, square at both ends, and all
/// starting from the same place.
RowPlan straightPlan({
  required int rowLength,
  required int numberOfRows,
  required int laminateLength,
  required int laminateWidth,
}) =>
    RowPlan(
      lengths: List.filled(numberOfRows, rowLength),
      widths: List.filled(numberOfRows, laminateWidth),
      startU: List.filled(numberOfRows, 0),
      shift: List.filled(numberOfRows, 0),
      capFirst: List.filled(numberOfRows, laminateLength),
      capLast: List.filled(numberOfRows, laminateLength),
      capWhole: List.filled(numberOfRows, laminateLength),
      startBevel: List.filled(numberOfRows, Bevel.square),
      endBevel: List.filled(numberOfRows, Bevel.square),
    );

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

  // Half a width, rounded up: a plank must be long enough for the bevel's long
  // corner, and rounding the other way would claim reach the plank has not got.
  final bevelCost = (w + 1) ~/ 2;
  return RowPlan(
    lengths: lengths,
    widths: widths,
    startU: startU,
    shift: shift,
    capFirst: List.filled(rows, laminateLength - bevelCost),
    capLast: List.filled(rows, laminateLength - bevelCost),
    capWhole: List.filled(rows, laminateLength - w),
    startBevel: startBevel,
    endBevel: endBevel,
  );
}
