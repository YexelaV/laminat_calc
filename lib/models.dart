import 'package:equatable/equatable.dart';

import 'room_shape.dart';

enum Direction { length, width, diagonal }

/// Which corner of a plank end carries the material, as the slant of the cut:
/// how far the long corner reaches past the centreline, per half width of the
/// row. [square] is 0 and a 45° cut is ±1 — [up] when the long corner sits on
/// the far side of the row, [down] when it sits on the near side.
///
/// A number rather than three cases, because a wall the rows do not meet head
/// on gives everything in between: a room whose opposite walls differ has every
/// row ending on the same slight slant, and a 45° layout in such a room has two
/// slants of its own. Laying parallel to a wall in a true rectangle meets it
/// head on and only ever produces [square].
///
/// Cutting one plank in two yields complementary ends — the offcut owns the
/// corner the plank gave up — which is what decides whether a leftover can be
/// slotted into a later row.
class Bevel {
  final double slope;

  const Bevel(this.slope);

  static const square = Bevel(0.0);
  static const up = Bevel(1.0);
  static const down = Bevel(-1.0);

  /// The end a wall leaning by [lean] — `u` per `v` — cuts on a row of
  /// [laminateWidth].
  ///
  /// Snapped to a grid, for two reasons that both bite. Ends are compared for
  /// equality, and that is what lets an offcut from one row into another: a
  /// wall measured twice by different routes must not come out as two ends that
  /// differ in the last bit. And a wall square to within a rounding crumb has
  /// to come out [square] exactly, or the crumb rounds up into a millimetre of
  /// reach the row never lost and a square offcut stops fitting a square end.
  ///
  /// Never steeper than 45°, however steeply the wall runs. Past 45° the cut is
  /// running more along the plank than across it, which is a rip and not an end
  /// cut, and nobody tapers a plank forty to one: the fitter cuts the steepest
  /// end worth cutting and the skirting board covers the sliver of floor left
  /// in the corner. The bound also keeps the arithmetic honest — an unbounded
  /// slant asks a plank for more reach than it is long, and a row that asks
  /// that has no layout at all.
  factory Bevel.fromLean(double lean, int laminateWidth) {
    final snapped = (lean.clamp(-1.0, 1.0) * _leanGrid).round() / _leanGrid;
    // Less than half a millimetre of lean across the row is not a cut anyone
    // can make, and the skirting board covers the difference.
    if (snapped.abs() * laminateWidth / 2 < 0.5) return square;
    return Bevel(snapped);
  }

  bool get isSquare => slope == 0.0;

  Bevel get complement => Bevel(-slope);

  /// Whether two ends are cut towards the same side of the row. An end can be
  /// recut to any other leaning the same way; the other way round the material
  /// was never there.
  bool leansSameWayAs(Bevel other) => slope.sign == other.slope.sign;

  /// How much centreline a plank of [laminateWidth] gives up to this cut.
  ///
  /// Rounded up: a plank must be long enough for the cut's long corner, and
  /// rounding the other way would claim reach the plank has not got.
  int reachMm(int laminateWidth) => (slope.abs() * laminateWidth / 2).ceil();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Bevel && other.slope == slope;

  @override
  int get hashCode => slope.hashCode;

  @override
  String toString() => 'Bevel($slope)';
}

const double _leanGrid = 1e6;

enum OffsetMode { half, third, quarter, exact }

extension OffsetModeFraction on OffsetMode {
  int? get divisor {
    switch (this) {
      case OffsetMode.half:
        return 2;
      case OffsetMode.third:
        return 3;
      case OffsetMode.quarter:
        return 4;
      case OffsetMode.exact:
        return null;
    }
  }
}

class Plank {
  final int number;
  int length;
  int width;
  bool hasLeftLock;
  bool hasRightLock;

  /// The shape of each end. [length] is the centreline, so a bevelled end
  /// reaches half a width further on one side and half a width less on the
  /// other; which side is what [Bevel] records.
  Bevel leftBevel;
  Bevel rightBevel;

  Plank(
    this.number,
    this.length,
    this.width, {
    this.hasLeftLock = true,
    this.hasRightLock = true,
    this.leftBevel = Bevel.square,
    this.rightBevel = Bevel.square,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Plank &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          length == other.length &&
          width == other.width;

  @override
  int get hashCode => number.hashCode + length.hashCode + width.hashCode;
}

class Line extends Equatable {
  final int number;
  final List<Plank> planks;

  /// Where the row begins on the axis all rows share. Rows of a diagonal
  /// layout start at different places, and the drawing has to take the shift
  /// from here rather than derive it again, or the two will disagree.
  final int startOffsetMm;

  const Line(this.number, this.planks, {this.startOffsetMm = 0});

  @override
  List<Object> get props => [number, planks, startOffsetMm];
}

/// A stretch of one row the floor does not reach the whole width of.
///
/// A row is one width over its whole length in every room but one with a piece
/// cut out of it. There the floor steps sideways inside a row: it runs the full
/// width of the row for most of its length and only [width] of it from [fromMm]
/// to [toMm], because the cut has taken the rest. A plank lying wholly out
/// there is ripped to [width]; the one plank the step falls inside is notched
/// round the inside corner and keeps the row's own width.
///
/// Measured from the row's own start, like a plank's place in it, so that the
/// cut list can walk the planks and the steps together without knowing where on
/// the floor either of them sits.
class RowStep extends Equatable {
  /// Which row, by the number [Line.number] gives it.
  final int row;

  final int fromMm;
  final int toMm;

  /// What the floor leaves of the row there — always less than its full width.
  final int width;

  const RowStep({
    required this.row,
    required this.fromMm,
    required this.toMm,
    required this.width,
  });

  /// Whether a plank lying from [lo] to [hi] along the row is wholly inside the
  /// step, and so ripped to [width] rather than notched.
  bool holds(int lo, int hi) => lo >= fromMm && hi <= toMm;

  @override
  List<Object> get props => [row, fromMm, toMm, width];
}

class Result extends Equatable {
  final int totalPlanks;
  final List<Line> lines = [];
  final List<Plank> pieces = [];
  final List<Plank> trash = [];
  final int laminateLength;

  /// What a plank measured before anything was done to it. The length is above;
  /// this is the other half, and the cut list needs both to say which planks go
  /// down untouched — a row narrowed across its width is laid with planks of
  /// full length that have still been ripped.
  final int laminateWidth;

  /// The room the planks were laid in. The drawing rebuilds the outline from it
  /// rather than being handed one, so the floor that is drawn and the floor
  /// that was laid are the same measurements.
  final RoomOutline shape;
  final int quantityPerPack;
  final Direction direction;

  /// The expansion gap left around the floor. The drawing needs it to know
  /// where the laid area sits inside the room, which for a 45° layout is the
  /// difference between meeting the walls and floating free of them.
  final int indentFromWall;

  /// The stretches of a row the floor does not reach the whole width of.
  ///
  /// Only in a room with a corner cut away, and the reason the cut list cannot
  /// say a row's width once in front of it: out past the step the row is
  /// narrower, and the planks out there are ripped to that. The plank the step
  /// itself falls inside is cut round the corner rather than straight across,
  /// and its length in the list is the longer side of that cut — the drawing is
  /// the only place the step is shown, so the list has to point at it.
  final List<RowStep> rowSteps;

  Result(
    this.laminateLength,
    this.shape,
    this.quantityPerPack,
    this.totalPlanks,
    List<Line> lines,
    List<Plank> pieces,
    List<Plank> trash, {
    required this.laminateWidth,
    required this.direction,
    required this.indentFromWall,
    this.rowSteps = const [],
  }) {
    this.lines.addAll(lines);
    this.pieces.addAll(pieces);
    this.trash.addAll(trash);
  }

  @override
  List<Object> get props => [lines, pieces, trash, direction];
}
