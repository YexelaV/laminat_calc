// The floor as a shape rather than two numbers. Everything here is in
// millimetres of room and knows nothing about canvases or laminate.
import 'dart:math' as math;
import 'dart:math' show Point;

/// What is wrong with a set of measurements, when something is.
enum RoomProblem {
  /// The diagonal is too short or too long for the walls to reach round it —
  /// one of the two triangles it cuts the room into does not close.
  diagonalDoesNotClose,

  /// The walls close, but into a shape with a corner folded inwards. A room is
  /// not measured wrong this way by accident; a mistyped digit gets here.
  notConvex,
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
class RoomShape {
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

  /// A rectangle is worth knowing about for its own sake: it is what every room
  /// was until now, and it goes down a closed-form path that has to keep
  /// producing the numbers it always did, to the millimetre.
  ///
  /// The diagonal is compared against the rounded hypotenuse rather than the
  /// exact one, which no whole number of millimetres ever is. A user who typed
  /// equal walls and let the field fill itself means a rectangle, and gets one.
  bool get isRectangular =>
      lengthNear == lengthFar &&
      widthLeft == widthRight &&
      diagonal == rectangleDiagonal(lengthNear, widthLeft);

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
    return _isConvex(corners()) ? null : RoomProblem.notConvex;
  }

  /// The four corners, starting at the one the rows start from and going round.
  ///
  /// [P0] sits at the origin and [lengthNear] runs off along the x axis; the
  /// rest follows from the two triangles. A rectangle is written out rather
  /// than solved, so that a room nobody measured across is the same rectangle
  /// down to the last bit.
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

  /// The floor inside the walls: [corners] with every wall moved in by the
  /// expansion gap.
  List<Point<double>> floor(int indentFromWall) => insetPolygon(corners(), indentFromWall.toDouble());

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

/// [polygon] with every edge moved [gap] towards the inside, corners
/// re-cut where the moved edges now meet.
///
/// Convex only, and the corners have to run round it in order. An axis-aligned
/// rectangle comes back exactly `Rect.fromLTWH(gap, gap, w - 2gap, h - 2gap)`,
/// which is what the drawing has always inset to and must keep inseting to.
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

/// The inward unit normal of each wall of a convex [polygon], wall `i` running
/// from corner `i` to corner `i + 1`.
///
/// One definition of "inside", used by everything that has to agree on it: the
/// gap the floor is inset by, and the walls the planks are cut against. Taken
/// from the outline's own turn rather than from a convention about which way
/// the corners are listed, so nothing depends on which way the y axis points.
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
/// Convex only: the line then crosses the outline exactly twice, and the
/// leftmost and rightmost crossings are the two ends of one row.
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

double _signedArea(List<Point<double>> polygon) {
  var sum = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final from = polygon[i];
    final to = polygon[(i + 1) % polygon.length];
    sum += from.x * to.y - to.x * from.y;
  }
  return sum / 2;
}

bool _isConvex(List<Point<double>> polygon) {
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
