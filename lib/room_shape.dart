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

  /// The rectangle missing from the floor's bounding box, or null when the
  /// floor fills it.
  ///
  /// Handed out rather than worked back out of [floor]: the drawing cuts
  /// planks against it, and a second derivation of the same rectangle is a
  /// second definition of it.
  List<Point<double>>? floorNotch(int indentFromWall) => null;

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

/// A room with one corner cut out of it: the rectangle [length] by [width],
/// less a [notchLength] by [notchWidth] rectangle at [corner].
///
/// Right angles throughout, and that is a choice rather than an oversight. A
/// room measured wall by wall ([RoomShape]) assumes nothing about its corners
/// and pays for it with a diagonal; six walls would need three diagonals, nine
/// numbers to type and a sketch nobody could read. A niche, a boxed-in riser or
/// a corner chimney is square to the room it is cut from, and measuring it as
/// two sides of a rectangle is both what a tape measure gives and what the
/// fitter will cut to.
///
/// The outline is monotone in both axes — at any height the floor is one
/// unbroken run, and likewise across — because the missing piece is pressed
/// into a *corner* rather than sitting in the middle of a wall. Every row that
/// runs parallel to a wall is therefore one unbroken row, which is what lets
/// the whole of the rest of the calculator take this room without learning
/// anything new. It stops being true at 45°, and that is why a 45° layout is
/// not offered here.
class LRoomShape extends RoomOutline {
  /// The bounding rectangle: the wall the rows run along, and the one they
  /// start against, as they would be with nothing cut away.
  final int length;
  final int width;

  /// How far the cut reaches along each of those two.
  final int notchLength;
  final int notchWidth;

  final RoomCorner corner;

  const LRoomShape({
    required this.length,
    required this.width,
    required this.notchLength,
    required this.notchWidth,
    required this.corner,
  });

  /// The narrowest strip of floor left beside the cut that is still a room.
  /// The geometry itself only needs a millimetre; this is the number the
  /// calculator already calls the smallest room there is.
  static const int minArmMm = MIN_ROOM_MM;

  /// The bounds the form shows the user, so that what is on screen is this
  /// arithmetic and not a second guess at it.
  static int maxNotchLength(int length) => length - minArmMm;

  static int maxNotchWidth(int width) => width - minArmMm;

  /// Never. The closed forms a rectangle goes down measure from two numbers,
  /// and this room is not two numbers however square its corners are.
  @override
  bool get isRectangular => false;

  @override
  String get key => 'L$length/$width/$notchLength/$notchWidth/${corner.index}';

  @override
  RoomProblem? get problem {
    if (notchLength < MIN_NOTCH_MM || notchWidth < MIN_NOTCH_MM) {
      return RoomProblem.notchNotCut;
    }
    if (notchLength > maxNotchLength(length) || notchWidth > maxNotchWidth(width)) {
      return RoomProblem.notchLeavesNoRoom;
    }
    return null;
  }

  /// The six corners, from the one the rows start from and round.
  ///
  /// Written out for each corner rather than derived, for the reason
  /// [RoomShape.corners] writes out its rectangle: these are the numbers the
  /// user typed, and the outline has to carry them unrounded. All four run the
  /// same way round as the rectangle they are cut from, so [inwardNormals] and
  /// [turned] see the room they expect.
  @override
  List<Point<double>> corners() {
    final l = length.toDouble();
    final w = width.toDouble();
    final a = notchLength.toDouble();
    final b = notchWidth.toDouble();
    switch (corner) {
      case RoomCorner.nearLeft:
        return [
          Point(a, 0),
          Point(l, 0),
          Point(l, w),
          Point(0, w),
          Point(0, b),
          Point(a, b),
        ];
      case RoomCorner.nearRight:
        return [
          Point(0, 0),
          Point(l - a, 0),
          Point(l - a, b),
          Point(l, b),
          Point(l, w),
          Point(0, w),
        ];
      case RoomCorner.farRight:
        return [
          Point(0, 0),
          Point(l, 0),
          Point(l, w - b),
          Point(l - a, w - b),
          Point(l - a, w),
          Point(0, w),
        ];
      case RoomCorner.farLeft:
        return [
          Point(0, 0),
          Point(l, 0),
          Point(l, w),
          Point(a, w),
          Point(a, w - b),
          Point(0, w - b),
        ];
    }
  }

  @override
  List<int> wallLengths() {
    final a = notchLength;
    final b = notchWidth;
    switch (corner) {
      case RoomCorner.nearLeft:
        return [length - a, width, length, width - b, a, b];
      case RoomCorner.nearRight:
        return [length - a, b, a, width - b, length, width];
      case RoomCorner.farRight:
        return [length, width - b, a, b, length - a, width];
      case RoomCorner.farLeft:
        return [length, width, length - a, b, a, width - b];
    }
  }

  /// The cut keeps its size when the floor steps in from the walls.
  ///
  /// Both walls of the cut move away from it by the gap and both walls opposite
  /// move towards it by the same, so the missing rectangle comes out
  /// [notchLength] by [notchWidth] still, sitting in the corner of the floor's
  /// own bounding box. Worth stating because it is not what an offset usually
  /// does, and because [floor] arrives at the same six points the long way
  /// round, through [insetPolygon] — test/room_shape_test.dart holds the two
  /// together.
  @override
  List<Point<double>> floorNotch(int indentFromWall) {
    final g = indentFromWall.toDouble();
    final left = g;
    final right = length - g;
    final near = g;
    final far = width - g;
    final a = notchLength.toDouble();
    final b = notchWidth.toDouble();
    switch (corner) {
      case RoomCorner.nearLeft:
        return _rectangle(left, near, left + a, near + b);
      case RoomCorner.nearRight:
        return _rectangle(right - a, near, right, near + b);
      case RoomCorner.farRight:
        return _rectangle(right - a, far - b, right, far);
      case RoomCorner.farLeft:
        return _rectangle(left, far - b, left + a, far);
    }
  }
}

List<Point<double>> _rectangle(double x0, double y0, double x1, double y1) =>
    [Point(x0, y0), Point(x1, y0), Point(x1, y1), Point(x0, y1)];

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
