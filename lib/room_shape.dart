// The floor as a shape rather than two numbers. Everything here is in
// millimetres of room and knows nothing about canvases or laminate.
import 'dart:math' as math;
import 'dart:math' show Point;

import 'constants.dart';

/// What is wrong with a set of measurements, when something is.
enum RoomProblem {
  /// The diagonal is too short or too long for the walls to reach round it —
  /// one of the two triangles it cuts the room into does not close.
  diagonalDoesNotClose,

  /// The walls close, but into a shape with a corner folded inwards. A room is
  /// not measured wrong this way by accident; a mistyped digit gets here.
  notConvex,

  /// A corner cut away with a zero side is not a cut. Two corners of the
  /// outline land on each other, the wall between them has no direction to
  /// face, and the inward normal of a wall of no length is not a number.
  notchNotCut,

  /// The cut takes so much of the room that what it leaves along one axis is
  /// narrower than the narrowest room this calculator takes.
  notchLeavesNoRoom,
}

/// The outline of a room: all the engine and the drawing ever need to know
/// about where the walls are.
///
/// There are two kinds, and they share nothing but this. A room measured wall
/// by wall is a quadrilateral and assumes nothing about its corners. A room
/// with a corner cut away is square throughout and is measured as the
/// rectangle it would have been, less the piece that is missing. Everything
/// downstream — the rows, the engine, the drawing — wants only what is
/// declared here.
abstract class RoomOutline {
  const RoomOutline();

  /// The corners, starting at the one the rows start from and going round.
  /// Four of them for a quadrilateral, six for a room with a corner cut away.
  List<Point<double>> corners();

  /// The length of each wall, wall `i` running from corner `i` to corner
  /// `i + 1`.
  ///
  /// The numbers the user measured, or whole-millimetre differences of them —
  /// never read back off the drawn corners. A wall is written on the drawing
  /// to be cut to, and no amount of turning and insetting leaves a measurement
  /// round.
  List<int> wallLengths();

  /// What is wrong with the measurements, when something is.
  RoomProblem? get problem;

  /// A rectangle is worth knowing about for its own sake: it is what every
  /// room was until walls could differ, and it goes down closed-form paths
  /// that have to keep producing the numbers they always did, to the
  /// millimetre. Those paths are reached through this and nothing else.
  bool get isRectangular;

  /// The room as one string, for the answer [planFeasible] keeps. Two rooms
  /// that differ anywhere have to differ here, or the form answers a question
  /// about one of them with the answer to the other.
  String get key;

  /// The floor inside the walls: [corners] with every wall moved in by the
  /// expansion gap.
  List<Point<double>> floor(int indentFromWall) =>
      insetPolygon(corners(), indentFromWall.toDouble());

  /// Whether every wall is square to the rows.
  ///
  /// What a row reaches is then constant between corners rather than sliding
  /// along with them, which is the whole of the argument that lets the rows be
  /// worked out exactly, corner by corner, instead of sampled down the middle
  /// of each — see [spansOver]. A room that is not this goes the sampled way.
  bool get isRectilinear => false;

  /// Whether a 45° row can be laid in this room.
  ///
  /// False where a 45° strip would cross the floor twice: a row there is two
  /// rows, and nothing downstream — not [RowSpan], not the cut list — has a way
  /// to say so. Every outline that turns back on itself is like that at some
  /// angle, and no convex one is at any.
  bool get takesDiagonal => true;

  /// How far the room reaches across. The point a quarter turn is taken about,
  /// and the only reason [turned] is a method rather than a free function: the
  /// walls and the floor have to turn about the *same* point, and the floor's
  /// own extent is a gap short of the room's.
  double get _turnPivot => corners().map((corner) => corner.y).reduce(math.max);

  /// [polygon] — these walls, or the floor inside them — turned a quarter turn
  /// so that rows laid across the room run along `x`.
  ///
  /// A turn and not a reflection. Transposing `(x, y) → (y, x)` also stands the
  /// room on its side and is one character shorter, but it prints the room
  /// mirrored: the near wall comes out on the far side, and a measurement
  /// written on a wall lands on the wrong one. On a rectangle the two are
  /// indistinguishable, which is how the transpose survived this long.
  List<Point<double>> turned(List<Point<double>> polygon) {
    final pivot = _turnPivot;
    return [for (final p in polygon) Point(pivot - p.y, p.x)];
  }
}

/// A room measured the way a floor actually is: round the four walls, then
/// across.
///
/// Four lengths are one measurement short of a shape. A quadrilateral has five
/// degrees of freedom — eight coordinates less the three of moving it about —
/// and four sides leave one of them open: the outline folds like a hinge, and
/// nothing in the four numbers says how far. The diagonal closes it exactly and
/// without assuming anything about right angles, because it cuts the outline
/// into two triangles and a triangle is fixed by its three sides.
///
/// The corners run [P0] → [P1] along [lengthNear], [P1] → [P2] along
/// [widthRight], [P2] → [P3] along [lengthFar], [P3] → [P0] along [widthLeft],
/// and the diagonal is [P0] to [P2].
class RoomShape extends RoomOutline {
  /// The wall the rows are laid parallel to, and the one opposite it.
  final int lengthNear;
  final int lengthFar;

  /// The wall the rows start against, and the one they run out at.
  final int widthLeft;
  final int widthRight;

  /// Corner to corner, from where [lengthNear] meets [widthLeft] to where
  /// [lengthFar] meets [widthRight].
  final int diagonal;

  const RoomShape({
    required this.lengthNear,
    required this.lengthFar,
    required this.widthLeft,
    required this.widthRight,
    required this.diagonal,
  });

  /// The room as it was measured before this screen existed: one length, one
  /// width, square corners.
  RoomShape.rectangle(int length, int width)
      : lengthNear = length,
        lengthFar = length,
        widthLeft = width,
        widthRight = width,
        diagonal = rectangleDiagonal(length, width);

  /// The diagonal of a true rectangle, to the millimetre. Also what the form
  /// fills the field with, so that a room nobody measured across still lays out
  /// exactly as it did before.
  static int rectangleDiagonal(int length, int width) =>
      math.sqrt(length * length + width * width).round();

  /// The diagonal is compared against the rounded hypotenuse rather than the
  /// exact one, which no whole number of millimetres ever is. A user who typed
  /// equal walls and let the field fill itself means a rectangle, and gets one.
  @override
  bool get isRectangular =>
      lengthNear == lengthFar &&
      widthLeft == widthRight &&
      diagonal == rectangleDiagonal(lengthNear, widthLeft);

  /// Only when it is a true rectangle. Four walls that merely happen to be
  /// equal still close round a diagonal of their own choosing, and the one the
  /// user typed leans them. Nothing reads this — [planFor] answers a rectangle
  /// from [isRectangular] before it asks — but a predicate that lies is worse
  /// than one that is never consulted.
  @override
  bool get isRectilinear => isRectangular;

  @override
  String get key => '$lengthNear/$lengthFar/$widthLeft/$widthRight/$diagonal';

  @override
  List<int> wallLengths() => [lengthNear, widthRight, lengthFar, widthLeft];

  /// The shortest and longest diagonal the walls can close round: the triangle
  /// inequality, once for each half of the room. A diagonal exactly at either
  /// limit flattens its triangle into a line, so the bounds step one millimetre
  /// inside it.
  ///
  /// The form hands these straight to the field validator, so the minimum and
  /// maximum a user is shown are the arithmetic itself and not a guess at it.
  static int minDiagonal({
    required int lengthNear,
    required int lengthFar,
    required int widthLeft,
    required int widthRight,
  }) =>
      math.max((lengthNear - widthRight).abs(), (widthLeft - lengthFar).abs()) + 1;

  static int maxDiagonal({
    required int lengthNear,
    required int lengthFar,
    required int widthLeft,
    required int widthRight,
  }) =>
      math.min(lengthNear + widthRight, widthLeft + lengthFar) - 1;

  @override
  RoomProblem? get problem {
    final low = minDiagonal(
      lengthNear: lengthNear,
      lengthFar: lengthFar,
      widthLeft: widthLeft,
      widthRight: widthRight,
    );
    final high = maxDiagonal(
      lengthNear: lengthNear,
      lengthFar: lengthFar,
      widthLeft: widthLeft,
      widthRight: widthRight,
    );
    if (diagonal < low || diagonal > high) return RoomProblem.diagonalDoesNotClose;
    return isConvexPolygon(corners()) ? null : RoomProblem.notConvex;
  }

  /// The four corners, starting at the one the rows start from and going round.
  ///
  /// [P0] sits at the origin and [lengthNear] runs off along the x axis; the
  /// rest follows from the two triangles. A rectangle is written out rather
  /// than solved, so that a room nobody measured across is the same rectangle
  /// down to the last bit.
  @override
  List<Point<double>> corners() {
    if (isRectangular) {
      final l = lengthNear.toDouble();
      final w = widthLeft.toDouble();
      return [Point(0, 0), Point(l, 0), Point(l, w), Point(0, w)];
    }
    final d = diagonal.toDouble();
    final near = lengthNear.toDouble();
    // P2 closes the first triangle: [diagonal] from the origin, [widthRight]
    // from the far end of [lengthNear]. Below the axis is the same room upside
    // down, so the root is taken positive.
    final x2 = (d * d + near * near - widthRight * widthRight) / (2 * near);
    final y2 = math.sqrt(math.max(0.0, d * d - x2 * x2));
    final p2 = Point(x2, y2);

    // P3 closes the second one, on the far side of the diagonal from P1 — the
    // side the sign below picks out.
    final unit = Point(x2 / d, y2 / d);
    final along = (widthLeft * widthLeft + d * d - lengthFar * lengthFar) / (2 * d);
    final across = math.sqrt(math.max(0.0, widthLeft * widthLeft - along * along));
    final p3 = Point(
      unit.x * along - unit.y * across,
      unit.y * along + unit.x * across,
    );
    return [Point(0, 0), Point(near, 0), p2, p3];
  }
}

/// Which corner of the room has been cut away, named the way [RoomShape] names
/// its walls: [nearLeft] is the corner the rows start from, and the rest follow
/// round.
enum RoomCorner { nearLeft, nearRight, farRight, farLeft }

/// A wall of the rectangle a room is measured as, named the way [RoomCorner]
/// names its corners: [near] is the wall the rows run along and start against
/// the left end of, and the rest follow round.
///
/// Here because a room with a pair of cuts has them on one *wall* — a T stands
/// on one — and naming the wall is the only way to say which pair without
/// naming two corners and hoping they are adjacent.
enum RoomWall { near, right, far, left }

extension RoomWallCorners on RoomWall {
  /// The wall's two corners, left to right along the near and far walls and
  /// near to far down the left and right ones.
  ///
  /// Screen order rather than ring order, because these two are what the form
  /// calls the first and second shoulder and what the sketch writes them
  /// beside. Ring order would put the far wall's corners back to front, and the
  /// user would be typing into the field at the other end of the room.
  List<RoomCorner> get corners {
    switch (this) {
      case RoomWall.near:
        return const [RoomCorner.nearLeft, RoomCorner.nearRight];
      case RoomWall.right:
        return const [RoomCorner.nearRight, RoomCorner.farRight];
      case RoomWall.far:
        return const [RoomCorner.farLeft, RoomCorner.farRight];
      case RoomWall.left:
        return const [RoomCorner.nearLeft, RoomCorner.farLeft];
    }
  }

  /// Whether the wall runs along the room's length. The shoulders of a pair of
  /// cuts are measured along the wall and their depth across it, and which of
  /// [CornerSize.along] and [CornerSize.across] is which turns on this.
  bool get runsAlongLength => this == RoomWall.near || this == RoomWall.far;
}

/// How a corner is taken off the rectangle the room is measured as.
enum CornerCut {
  /// A square bite out of the corner: a niche, a boxed-in riser, a corner
  /// chimney. It leaves an inside corner, and so a room that is not convex.
  notch,

  /// A straight run across the corner. The room stays convex, which is why a
  /// chamfered room keeps the 45° layout a notched one has to give up.
  chamfer,
}

/// How far a cut reaches along each of the two walls meeting at the corner.
class CornerSize {
  /// Along the near and far walls — the ones the rows run parallel to.
  final int along;

  /// Along the left and right walls.
  final int across;

  /// What the user measured along the wall a 45° cut leaves, when that is how
  /// the cut was given. Null for a square notch, which has no wall of its own
  /// but two, each measured by its own leg.
  ///
  /// Kept rather than worked back out of [along]. A 45° cut's leg is its wall
  /// over root two and does not come out whole, so the leg is rounded — and
  /// squaring the rounded leg back up lands a millimetre off the typed number
  /// about a third of the time. The drawing writes this beside the cut, and a
  /// drawing that answers 1003 to a typed 1002 is a drawing nobody trusts
  /// again.
  final int? measuredWall;

  const CornerSize({required this.along, required this.across, this.measuredWall});

  /// The cut a 45° wall of [wall] millimetres takes off each of the two walls
  /// it joins.
  ///
  /// Measured this way round because that is the way a tape can be laid on it:
  /// once the corner is cut there is no corner left to measure the legs from,
  /// and the cut face is the only one of the three a fitter can put a tape
  /// along.
  static CornerSize chamfer(int wall) {
    final leg = (wall / math.sqrt2).round();
    return CornerSize(along: leg, across: leg, measuredWall: wall);
  }

  /// The shortest and longest wall a 45° cut may leave, given what its legs are
  /// allowed to be. The form shows these, so what is on screen is this
  /// arithmetic and not a second guess at it.
  static int wallOfLeg(int leg) => (leg * math.sqrt2).round();

  @override
  String toString() =>
      measuredWall == null ? '${along}x$across' : '${along}x$across@$measuredWall';
}

/// A rectangle with corners taken off it: [length] by [width], less a cut at
/// every corner named in [cuts], all of them taken off the way [cut] says.
///
/// Right angles except where a corner is cut, and that is a choice rather than
/// an oversight. A room measured wall by wall ([RoomShape]) assumes nothing
/// about its corners and pays for it with a diagonal; eight walls would need
/// five diagonals, thirteen numbers to type and a sketch nobody could read. A
/// niche, a riser or a corner chimney is square to the room it is cut from, and
/// measuring it as two sides of a rectangle is both what a tape measure gives
/// and what the fitter will cut to.
///
/// **Why any set of corners is safe.** The outline is monotone in both axes —
/// at any height the floor is one unbroken run, and likewise across — because
/// every missing piece is pressed into a *corner* rather than sitting in the
/// middle of a wall. A cut in a left corner eats into the left *end* of the
/// rows that reach it; one in a right corner eats into the right end; none of
/// them can reach the middle of a row and part it in two. So every row is one
/// unbroken row however many corners are gone, which is what lets the rest of
/// the calculator take an L, a T, a U lying on its side or a Z without learning
/// anything new. It stops being true of a piece cut out of the middle of a
/// wall, and it stops being true at 45° — which is why neither is offered.
///
/// **Why one [cut] for the whole room rather than one per corner.** A room with
/// a notch somewhere and a chamfer somewhere else has both an inside corner and
/// a slanted wall, and the exactness [isRectilinear] claims holds for neither
/// arrangement. Ruling the mixture out by construction is cheaper than
/// detecting it, and no fitter has ever asked for it.
class CutCornersRoomShape extends RoomOutline {
  /// The bounding rectangle: the wall the rows run along, and the one they
  /// start against, as they would be with nothing cut away.
  final int length;
  final int width;

  final CornerCut cut;

  /// Which corners are gone and how far each cut reaches. A corner missing from
  /// here is a corner still square.
  final Map<RoomCorner, CornerSize> cuts;

  const CutCornersRoomShape({
    required this.length,
    required this.width,
    required this.cut,
    required this.cuts,
  });

  /// The narrowest strip of floor a cut may leave beside it and still leave a
  /// room. The geometry itself only needs a millimetre; this is the number the
  /// calculator already calls the smallest room there is.
  static const int minArmMm = MIN_ROOM_MM;

  /// Never. The closed forms a rectangle goes down measure from two numbers,
  /// and this room is not two numbers however square its corners are — and
  /// [Calculation.rowLength] casts on the strength of this answer, so a room
  /// with no cuts at all still has to say no.
  @override
  bool get isRectangular => false;

  /// A notched room is all right angles; a chamfered one is not.
  @override
  bool get isRectilinear => cut == CornerCut.notch;

  /// A chamfer leaves the room convex, so a 45° strip crosses it once. A notch
  /// does not, and a 45° row across one is two rows.
  @override
  bool get takesDiagonal => cut == CornerCut.chamfer;

  @override
  String get key {
    final parts = <String>[];
    for (final corner in RoomCorner.values) {
      final size = cuts[corner];
      if (size != null) parts.add('${corner.index}:$size');
    }
    // Led by a letter so that it can never read as a [RoomShape] key, which is
    // five numbers and starts with one.
    return 'C${cut.index}/$length/$width/${parts.join(',')}';
  }

  int _along(RoomCorner corner) => cuts[corner]?.along ?? 0;

  int _across(RoomCorner corner) => cuts[corner]?.across ?? 0;

  @override
  RoomProblem? get problem {
    for (final size in cuts.values) {
      if (size.along < MIN_NOTCH_MM || size.across < MIN_NOTCH_MM) {
        return RoomProblem.notchNotCut;
      }
    }
    // Two cuts on one wall eat into it from both ends at once, and what they
    // leave between them still has to be a room. With a single cut this is the
    // bound the form has always shown, the other end of the wall contributing
    // nothing.
    final pairs = [
      [_along(RoomCorner.nearLeft) + _along(RoomCorner.nearRight), length],
      [_along(RoomCorner.farLeft) + _along(RoomCorner.farRight), length],
      [_across(RoomCorner.nearLeft) + _across(RoomCorner.farLeft), width],
      [_across(RoomCorner.nearRight) + _across(RoomCorner.farRight), width],
    ];
    for (final pair in pairs) {
      if (pair[0] > pair[1] - minArmMm) {
        return RoomProblem.notchLeavesNoRoom;
      }
    }
    return null;
  }

  /// The corners in whole millimetres, from the one the rows start from and
  /// round.
  ///
  /// Whole millimetres because [wallLengths] is taken off the same walk: a wall
  /// written on the drawing to be cut to has to be the number the user typed or
  /// a difference of two of them, never a length read back off a drawn corner.
  /// One walk and not two so that the corners and the walls cannot drift apart
  /// — the drawing pairs them off by index.
  ///
  /// The walk runs the same way round as the rectangle it is cut from, so
  /// [inwardNormals] and [turned] see the room they expect.
  List<Point<int>> _ring() {
    final walked = <Point<int>>[];
    for (final corner in RoomCorner.values) {
      walked.addAll(_pointsAt(corner));
    }
    return [...walked.skip(_lead), ...walked.take(_lead)];
  }

  /// How far the walk is rotated so that the near wall opens the ring, the way
  /// [corners] promises and the way a rectangle always did. A cut near left
  /// corner is reached at the *end* of its own points, not the start, so the
  /// ring turns onto the last of them.
  int get _lead => _pointsAt(RoomCorner.nearLeft).length - 1;

  /// Which corner's cut each wall is, for the walls that are one.
  ///
  /// A notch gives its corner two walls — the two legs of the piece taken out —
  /// and a chamfer gives one, the run across. Every other wall is a wall of the
  /// bounding rectangle and belongs to no cut.
  ///
  /// The drawing asks because a wall whose measurement nobody has typed is
  /// written up as a question mark rather than as the number the outline had to
  /// invent to be an outline at all.
  Map<RoomCorner, List<int>> cutWalls() {
    final owners = <RoomCorner>[];
    for (final corner in RoomCorner.values) {
      owners.addAll(List.filled(_pointsAt(corner).length, corner));
    }
    final walked = [...owners.skip(_lead), ...owners.take(_lead)];
    final out = <RoomCorner, List<int>>{};
    for (var i = 0; i < walked.length; i++) {
      // A wall runs between two points, and it is part of a cut only when both
      // of them were put there by the same cut corner.
      final corner = walked[i];
      if (corner != walked[(i + 1) % walked.length]) continue;
      if (!cuts.containsKey(corner)) continue;
      out.putIfAbsent(corner, () => []).add(i);
    }
    return out;
  }

  /// What stands in place of [corner]: the corner itself when it is square, the
  /// two ends of the cut when it is chamfered, and those two with the inside
  /// corner between them when it is notched. In the order the walk reaches
  /// them.
  List<Point<int>> _pointsAt(RoomCorner corner) {
    final size = cuts[corner];
    if (size == null) {
      switch (corner) {
        case RoomCorner.nearLeft:
          return [const Point(0, 0)];
        case RoomCorner.nearRight:
          return [Point(length, 0)];
        case RoomCorner.farRight:
          return [Point(length, width)];
        case RoomCorner.farLeft:
          return [Point(0, width)];
      }
    }
    final a = size.along;
    final b = size.across;
    switch (corner) {
      case RoomCorner.nearLeft:
        return [
          Point(0, b),
          if (cut == CornerCut.notch) Point(a, b),
          Point(a, 0),
        ];
      case RoomCorner.nearRight:
        return [
          Point(length - a, 0),
          if (cut == CornerCut.notch) Point(length - a, b),
          Point(length, b),
        ];
      case RoomCorner.farRight:
        return [
          Point(length, width - b),
          if (cut == CornerCut.notch) Point(length - a, width - b),
          Point(length - a, width),
        ];
      case RoomCorner.farLeft:
        return [
          Point(a, width),
          if (cut == CornerCut.notch) Point(a, width - b),
          Point(0, width - b),
        ];
    }
  }

  @override
  List<Point<double>> corners() =>
      [for (final p in _ring()) Point(p.x.toDouble(), p.y.toDouble())];

  @override
  List<int> wallLengths() {
    final ring = _ring();
    // The wall a 45° cut leaves is the one wall here that is not a difference
    // of two typed numbers. Where the user measured it, that measurement is
    // what goes on the drawing — see [CornerSize.measuredWall] for why it is
    // kept rather than squared back up out of the rounded legs.
    final measured = <int, int>{};
    cutWalls().forEach((corner, walls) {
      final wall = cuts[corner]?.measuredWall;
      if (wall != null && walls.length == 1) measured[walls.single] = wall;
    });

    final out = <int>[];
    for (var i = 0; i < ring.length; i++) {
      final said = measured[i];
      if (said != null) {
        out.add(said);
        continue;
      }
      final from = ring[i];
      final to = ring[(i + 1) % ring.length];
      final dx = (to.x - from.x).abs();
      final dy = (to.y - from.y).abs();
      // A wall square to an axis is a difference of two typed numbers and comes
      // out whole; anything else is a hypotenuse and is rounded.
      out.add(dx == 0
          ? dy
          : dy == 0
              ? dx
              : math.sqrt(dx * dx + dy * dy).round());
    }
    return out;
  }
}

/// A room with one corner cut square out of it, the shape this calculator had
/// before it could take more than one.
///
/// Kept as its own name because an L is what a user says and what half the
/// tests are written about; it adds nothing to [CutCornersRoomShape] but a way
/// of naming a single notch.
class LRoomShape extends CutCornersRoomShape {
  LRoomShape({
    required super.length,
    required super.width,
    required this.notchLength,
    required this.notchWidth,
    required this.corner,
  }) : super(
          cut: CornerCut.notch,
          cuts: {corner: CornerSize(along: notchLength, across: notchWidth)},
        );

  /// How far the cut reaches along the length and along the width.
  final int notchLength;
  final int notchWidth;

  final RoomCorner corner;

  /// Restated rather than inherited: a static is not, and every caller of this
  /// one reaches for it by the L's name.
  static const int minArmMm = CutCornersRoomShape.minArmMm;

  /// The bounds the form shows the user, so that what is on screen is this
  /// arithmetic and not a second guess at it.
  static int maxNotchLength(int length) => length - minArmMm;

  static int maxNotchWidth(int width) => width - minArmMm;
}

/// [value] held between [least] and [most], and [least] itself where a room is
/// too small for those two to be in that order.
///
/// A room may be [MIN_ROOM_MM] across, and a cut needs [MIN_NOTCH_MM] of its
/// own plus [CutCornersRoomShape.minArmMm] of floor beside it — so there are
/// rooms the form accepts that no cut fits into, and in those the ceiling on a
/// cut lands below its floor. [num.clamp] throws when its bounds cross, which
/// is no way to answer "how big may this cut be" — the answer is that the
/// smallest cut there is is already too big, and [RoomOutline.problem] is what
/// says so, under the sketch and at the Next button.
int heldBetween(int value, int least, int most) =>
    value.clamp(least, math.max(least, most));

/// [polygon] with every edge moved [gap] towards the inside, corners
/// re-cut where the moved edges now meet.
///
/// The corners have to run round it in order, and no two of them may sit on top
/// of each other — a wall of no length has no direction and so no normal. A
/// corner that turns inwards is fine: its two walls still move towards the
/// inside, and where they now meet is further out along the diagonal than the
/// corner was, which is the mitre a fitter squares off anyway.
///
/// An axis-aligned rectangle comes back exactly
/// `Rect.fromLTWH(gap, gap, w - 2gap, h - 2gap)`, which is what the drawing has
/// always inset to and must keep inseting to.
List<Point<double>> insetPolygon(List<Point<double>> polygon, double gap) {
  final n = polygon.length;
  final normals = inwardNormals(polygon);
  // Each edge as the line `normal · x = offset`, already moved inwards.
  final offsets = <double>[
    for (var i = 0; i < n; i++)
      normals[i].x * polygon[i].x + normals[i].y * polygon[i].y + gap
  ];
  final out = <Point<double>>[];
  for (var i = 0; i < n; i++) {
    // Corner i is where the edge arriving at it meets the edge leaving it.
    final a = normals[(i + n - 1) % n];
    final b = normals[i];
    final ca = offsets[(i + n - 1) % n];
    final cb = offsets[i];
    final det = a.x * b.y - a.y * b.x;
    out.add(Point(
      (ca * b.y - cb * a.y) / det,
      (a.x * cb - b.x * ca) / det,
    ));
  }
  return out;
}

/// The inward unit normal of each wall of a [polygon], wall `i` running
/// from corner `i` to corner `i + 1`.
///
/// One definition of "inside", used by everything that has to agree on it: the
/// gap the floor is inset by, and the walls the planks are cut against. Taken
/// from the outline's own turn rather than from a convention about which way
/// the corners are listed, so nothing depends on which way the y axis points —
/// and for the same reason it does not depend on the outline being convex: the
/// signed area of a simple polygon says which way it runs whatever its corners
/// do.
List<Point<double>> inwardNormals(List<Point<double>> polygon) {
  final inward = _signedArea(polygon) > 0 ? 1.0 : -1.0;
  final normals = <Point<double>>[];
  for (var i = 0; i < polygon.length; i++) {
    final edge = polygon[(i + 1) % polygon.length] - polygon[i];
    final length = edge.magnitude;
    normals.add(Point(-edge.y * inward / length, edge.x * inward / length));
  }
  return normals;
}

/// How far a row reaches, and how the walls lean where it meets them.
class RowSpan {
  /// Where the row starts and ends along `u`.
  final double lo;
  final double hi;

  /// `u` per `v` along the wall at each end: 0 for a wall the row meets head
  /// on, ±1 for one it meets at 45°. This is what the slant of the plank's end
  /// is cut from.
  final double loLean;
  final double hiLean;

  const RowSpan(this.lo, this.hi, this.loLean, this.hiLean);

  double get length => hi - lo;
}

/// Where the line across the rows at [v] enters and leaves [polygon], or null
/// when it misses it. In the row frame, so `x` is `u` and `y` is `v`.
///
/// The leftmost and rightmost crossings, which are the two ends of the row only
/// if the line meets the outline in a single unbroken run. Every convex outline
/// is like that, and so is a room with a corner cut away, as long as the rows
/// run parallel to its walls: the cut is pressed into a corner, so what it
/// takes off a row it takes off one *end* of it. Turn the same room 45° and the
/// cut lands in the middle of the row instead, splitting it in two, and what
/// comes back from here is the two halves and the hole between them.
RowSpan? spanAt(List<Point<double>> polygon, double v) {
  var lo = double.infinity;
  var hi = double.negativeInfinity;
  var loLean = 0.0;
  var hiLean = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final from = polygon[i];
    final to = polygon[(i + 1) % polygon.length];
    // A wall running along the row has no crossing to give: where it touches
    // the line it does so along its whole length, and the walls at either end
    // of it report the same two points.
    if (from.y == to.y) continue;
    final t = (v - from.y) / (to.y - from.y);
    if (t < 0 || t > 1) continue;
    final u = from.x + (to.x - from.x) * t;
    final lean = (to.x - from.x) / (to.y - from.y);
    if (u < lo) {
      lo = u;
      loLean = lean;
    }
    if (u > hi) {
      hi = u;
      hiLean = lean;
    }
  }
  return lo > hi ? null : RowSpan(lo, hi, loLean, hiLean);
}

/// Every distinct run the floor makes across the strip from [vLo] to [vHi].
///
/// One of them for a strip the walls run straight through, and two where a
/// corner steps sideways inside it.
///
/// Exact rather than sampled. The reach of an outline whose walls are all
/// square to each other is constant in `v` between corners, so the strip is
/// cut at every corner inside it and each piece measured down its middle —
/// which catches every value the reach takes and no value it does not.
List<RowSpan> spansOver(List<Point<double>> polygon, double vLo, double vHi) {
  final breaks = <double>[vLo, vHi];
  for (final corner in polygon) {
    if (corner.y > vLo && corner.y < vHi) breaks.add(corner.y);
  }
  breaks.sort();
  final out = <RowSpan>[];
  for (var i = 0; i + 1 < breaks.length; i++) {
    final at = spanAt(polygon, (breaks[i] + breaks[i + 1]) / 2);
    if (at != null) out.add(at);
  }
  return out;
}

/// The furthest the floor reaches anywhere in the strip from [vLo] to [vHi].
///
/// [spanAt] measures one line, but a row is a band a plank wide, and where a
/// wall steps sideways inside that band the two edges of the band disagree. A
/// row has to be laid to the wider of them: a row laid to the narrower leaves a
/// ribbon of real floor bare against a wall, which is a hole in the room, while
/// a row laid to the wider runs a little way past the step into the cut — which
/// is what a fitter does anyway, notching the board round the inside corner.
RowSpan? widestSpanOver(List<Point<double>> polygon, double vLo, double vHi) {
  RowSpan? widest;
  for (final at in spansOver(polygon, vLo, vHi)) {
    if (widest == null) {
      widest = at;
      continue;
    }
    // The enclosure of the runs rather than the longest of them: the cut may
    // be at either end of the row, and a room cut at both would be enclosed by
    // neither on its own. Each end keeps the lean of the wall it came from.
    final lo = at.lo < widest.lo ? at : widest;
    final hi = at.hi > widest.hi ? at : widest;
    widest = RowSpan(lo.lo, hi.hi, lo.loLean, hi.hiLean);
  }
  return widest;
}

/// The corners [polygon] turns the wrong way at — the inside corner of a room
/// with a piece cut out of it, and nothing at all in a convex one.
///
/// Corner `i` is the one between wall `i - 1` and wall `i`. Read off the
/// outline's own turn, like [inwardNormals], so it does not depend on which
/// way round the corners happen to be listed.
List<int> reflexCorners(List<Point<double>> polygon) {
  final turn = _signedArea(polygon) > 0 ? 1.0 : -1.0;
  final out = <int>[];
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[(i + polygon.length - 1) % polygon.length];
    final b = polygon[i];
    final c = polygon[(i + 1) % polygon.length];
    final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
    if (cross * turn < 0) out.add(i);
  }
  return out;
}

double _signedArea(List<Point<double>> polygon) {
  var sum = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final from = polygon[i];
    final to = polygon[(i + 1) % polygon.length];
    sum += from.x * to.y - to.x * from.y;
  }
  return sum / 2;
}

/// Whether [polygon] turns the same way at every corner.
///
/// Public because the drawing has to ask: cutting a plank against the walls one
/// half-plane at a time is only the same thing as cutting it against the room
/// when the room is convex, and a room with a corner cut away is not.
bool isConvexPolygon(List<Point<double>> polygon) {
  var sign = 0;
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    final c = polygon[(i + 2) % polygon.length];
    final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
    // A corner that has not turned at all leaves three walls in a line, which
    // is a triangle wearing a fourth measurement and still lays out fine.
    if (cross == 0) continue;
    final now = cross > 0 ? 1 : -1;
    if (sign != 0 && now != sign) return false;
    sign = now;
  }
  return true;
}
