// The floor as it is actually laid, in millimetres of room: every plank a
// polygon, every label a box to write in. The screen and the PDF both draw from
// here, so they cannot drift apart, and the arithmetic can be tested without a
// canvas.
//
// A row is built in its own coordinates — u along the row, v across the rows —
// and put on the floor by one affine map per [Direction]. Trapezoids and corner
// triangles then come out of the bevels on their own, with no case for the
// corners of the room.
import 'dart:math' as math;
import 'dart:math' show Point;
import 'dart:ui';

import 'models.dart';
import 'room_shape.dart';
import 'row_plan.dart';
import 'utils/units.dart';

/// A plank where it lies. [outline] runs from the near-left corner in the order
/// the four corners meet, so it can be stroked as a closed path directly.
class PlankShape {
  final Plank plank;
  final List<Offset> outline;

  const PlankShape(this.plank, this.outline);
}

/// A string and the room it has. The box is measured along the text, so a
/// caller that rotates the canvas by [angle] can lay it out in plain
/// left-to-right coordinates.
class SchemeLabel {
  final String text;
  final Offset centre;
  final double angle;
  final Size box;

  /// Plank numbers are set bold, everything else plain — a fitter reads the
  /// numbers in order and the sizes only at the plank he is cutting.
  final bool bold;

  const SchemeLabel(this.text, this.centre, this.angle, this.box, {this.bold = false});
}

class Scheme {
  /// The walls, corner by corner. The laid area sits inside them by the
  /// expansion gap. As many corners as the room has walls — four for a room
  /// measured wall by wall, six for one with a corner cut away — and not a
  /// rectangle unless the room was measured as one.
  final List<Offset> room;
  final List<PlankShape> planks;
  final List<SchemeLabel> labels;

  /// Everything drawn, walls and the labels written outside them.
  final Rect bounds;

  const Scheme({
    required this.room,
    required this.planks,
    required this.labels,
    required this.bounds,
  });
}

/// How much of a plank's width the text may take, and how wide one character is
/// for that height. Rough on purpose: the painter fits the text properly inside
/// the box it is handed, and these only decide whether a label is worth writing
/// at all and how much room to leave for the ones written outside the floor.
const double _textFill = 0.62;
const double _charAdvance = 0.58;

double _textWidth(String text, double height) => text.length * _charAdvance * height;

/// The height [text] comes out at once it is fitted into a box, in millimetres.
double _fits(String text, double boxWidth, double boxHeight) =>
    math.min(boxHeight, boxWidth / (text.length * _charAdvance));

/// The walls as they are drawn, in millimetres: x across the page, y down it.
///
/// Planks are read along their length, so a row is always drawn running left to
/// right. Laying across the room therefore turns the room a quarter of a turn
/// rather than the rows — its width goes across the page and its length down
/// it. [planFor] turns the floor the same way for the same reason, and the two
/// have to agree or the drawing is of a different room than the one laid.
List<Offset> drawnRoom(Result result) =>
    _asDrawn(result.shape, result.shape.corners(), result.direction);

/// The floor inside those walls: what the planks are cut against.
List<Offset> drawnFloor(Result result) =>
    _asDrawn(result.shape, result.shape.floor(result.indentFromWall), result.direction);

/// The room's own geometry comes in as plain points — [RoomOutline] and
/// [planFor] have no business knowing about canvases — and turns into canvas
/// coordinates here, which is the first place they mean anything.
///
/// The quarter turn is [RoomOutline.turned], the same one [planFor] lays the
/// rows through. One function rather than two matching ones: they used to be a
/// transpose apiece, each right about the other and both mirroring the room.
List<Offset> _asDrawn(RoomOutline shape, List<Point<double>> polygon, Direction direction) {
  final placed = direction == Direction.width ? shape.turned(polygon) : polygon;
  return [for (final p in placed) Offset(p.x, p.y)];
}

/// The smallest rectangle [polygon] fits in.
Rect boundsOf(List<Offset> polygon) {
  var rect = Rect.fromPoints(polygon.first, polygon.first);
  for (final point in polygon.skip(1)) {
    rect = rect.expandToInclude(Rect.fromPoints(point, point));
  }
  return rect;
}

/// Turn a finished calculation into something drawable.
///
/// [minTextMm] is the smallest text worth writing, in millimetres of room —
/// a caller with a canvas converts its pixel floor by the scale it draws at.
/// Labels that would come out below it are dropped, longest first: a plank too
/// small for both its number and its length keeps the number, and one too small
/// for that is left blank rather than smudged.
Scheme buildScheme(
  Result result, {
  required MeasurementSystem system,
  required double minTextMm,
}) {
  final planks = <PlankShape>[];
  final labels = <SchemeLabel>[];
  final indent = result.indentFromWall.toDouble();
  final room = drawnRoom(result);
  final floorCorners = drawnFloor(result);
  final floor = LaidFloor(floorCorners);
  final place = _placement(result, floorCorners);
  // Where the rows were measured from, for the one thing that has to ask the
  // floor again: how far a row actually reaches at a given height. Only a
  // floor with an inside corner needs it, and such a floor is only ever laid
  // along a wall, so the row frame is the drawing's own frame shifted.
  final floorBounds = boundsOf(floorCorners);
  final floorPoints = [for (final p in floorCorners) Point(p.dx, p.dy)];

  var v = 0.0;
  for (final line in result.lines) {
    final width = line.planks.first.width.toDouble();
    final vLo = v;
    final vHi = v + width;
    v = vHi;
    final half = width / 2;
    var u = line.startOffsetMm.toDouble();

    for (final plank in line.planks) {
      final u0 = u;
      final u1 = u + plank.length;
      u = u1;
      // A 45° end reaches half a width further on the side its long corner is
      // on and half a width less on the other; a square end is flat.
      final left = _bevelReach(plank.leftBevel, half);
      final right = _bevelReach(plank.rightBevel, half);
      // A row is a band of constant width, but the floor it crosses is a
      // rectangle: the row that straddles a corner has its end folded by the
      // wall and comes out with five sides rather than four. Cutting the band
      // against the floor produces that, and the corner triangles, without a
      // case for either.
      planks.add(PlankShape(
        plank,
        clipToFloor([
          place(u0 + left, vLo),
          place(u1 - right, vLo),
          place(u1 + right, vHi),
          place(u0 - left, vHi),
        ], floor),
      ));

      // The bounding box of a trapezoid lies about the room for text: only the
      // shorter of the two parallel edges is backed by material end to end.
      var from = u0 + left.abs();
      var usable = plank.length - left.abs() - right.abs();
      final vMid = (vLo + vHi) / 2;
      if (!floor.isConvex) {
        // A plank the cut-away corner took half of still has its number
        // written down the middle of the plank the row plan laid, which for
        // that one plank is a point outside the room. Fitted to the part of
        // the row that is floor at this height instead. Nowhere else can a
        // plank reach past the floor, so nowhere else does this fire.
        final reach = spanAt(floorPoints, floorBounds.top + vMid);
        if (reach != null) {
          final lo = math.max(from, reach.lo - floorBounds.left);
          final hi = math.min(from + usable, reach.hi - floorBounds.left);
          from = lo;
          usable = math.max(0.0, hi - lo);
        }
      }
      final height = width * _textFill;
      final number = ' ${plank.number}';
      // A plank still at its full length was not cut, and its size is the one
      // written on the pack.
      final size =
          plank.length < result.laminateLength ? ' ${sizeLabel(plank.length, system)}' : null;
      // Both fit as they always have, the number in the left third and the size
      // in the rest. When they do not, the size goes and the number takes the
      // whole plank — dropping the number instead would leave a piece with a
      // measurement on it and no way to tell which piece it is.
      final both = size != null &&
          math.min(_fits(number, usable / 3, height), _fits(size, usable * 2 / 3, height)) >=
              minTextMm;
      if (both) {
        labels.add(SchemeLabel(
          number,
          place(from + usable / 6, vMid),
          place.angle,
          Size(usable / 3, height),
          bold: true,
        ));
        labels.add(SchemeLabel(
          size,
          place(from + usable * 2 / 3, vMid),
          place.angle,
          Size(usable * 2 / 3, height),
        ));
      } else if (_fits(number, usable, height) >= minTextMm) {
        labels.add(SchemeLabel(
          number,
          place(from + usable / 2, vMid),
          place.angle,
          Size(usable, height),
          bold: true,
        ));
      }
    }
  }

  // How wide to rip each row, written just outside the wall that row begins
  // against. Rows parallel to a wall all begin against the same one and the
  // numbers line up down its side; rows at 45° change walls at the corner, and
  // following them there is what keeps the labels off the floor instead of
  // trailing away from it.
  final rowLabels = result.lines.map((l) => '${sizeLabel(l.planks.first.width, system)} ').toList();
  final gutterHeight =
      result.lines.map((l) => l.planks.first.width * _textFill).fold<double>(0, math.max);
  final gutter =
      rowLabels.fold<double>(0, (widest, text) => math.max(widest, _textWidth(text, gutterHeight)));
  v = 0.0;
  for (var i = 0; i < result.lines.length; i++) {
    final line = result.lines[i];
    final width = line.planks.first.width.toDouble();
    final start = place(line.startOffsetMm.toDouble(), v + width / 2);
    final outward = floor.outward(start);
    labels.add(SchemeLabel(
      rowLabels[i],
      start + outward * (gutter / 2 + indent),
      // Labels off a side wall stack downwards and are written across; labels
      // off a top or bottom wall stack sideways and have to be turned, or each
      // would be written over the next. Which of the two a wall is has to be
      // read off the direction it leans, not off an exact zero: a wall of a
      // room whose corners are not square misses that by a hair and every
      // label lands on the one before it.
      outward.dx.abs() < outward.dy.abs() ? math.pi / 2 : 0,
      Size(gutter, width * _textFill),
    ));
    v += width;
  }

  // The room's own measurements, written along the wall each one belongs to.
  //
  // Nothing else on the drawing says how big the room is — the numbers inside
  // the planks are cut lengths, the ones down the side are row widths. For a
  // room whose walls differ that silence is the whole story: fifteen millimetres
  // out of five metres is a pixel or two of drawing, far too little to see and
  // plenty to cut wrong, so the shape has to be read rather than looked at.
  //
  // The lengths come from the room as it was measured rather than from the
  // corners as they were drawn: they are the numbers the user typed, and no
  // amount of turning and insetting can round them off.
  final walls = result.shape.wallLengths();
  final roomNormals = normalsOf(room);
  for (var i = 0; i < room.length; i++) {
    final from = room[i];
    final to = room[(i + 1) % room.length];
    final text = sizeLabel(walls[i], system);
    final outward = Offset(-roomNormals[i].dx, -roomNormals[i].dy);
    // A room measurement is the one label that is never dropped — nothing else
    // on the drawing says how big the room is — but it may shrink. The two
    // walls of a cut-away corner are short, and in feet and inches the text
    // for one of them comes out wider than the wall it is written on and
    // lands on its neighbours. Written at the height that fits its own wall,
    // it stays where it belongs; a wall long enough for its own text, which
    // every wall of every room drawn before this was, keeps the shared height
    // and nothing already drawn moves.
    final height = math.min(gutterHeight, _fits(text, (to - from).distance, gutterHeight));
    labels.add(SchemeLabel(
      text,
      (from + to) / 2 +
          outward * (_reservedOutside(labels, floor, i) + gutterHeight / 2 + indent),
      _alongWall(to - from),
      Size(_textWidth(text, height), height),
    ));
  }

  var bounds = boundsOf(room);
  for (final label in labels) {
    bounds = bounds.expandToInclude(Rect.fromCircle(
      center: label.centre,
      radius: math.max(label.box.width, label.box.height) / 2,
    ));
  }
  return Scheme(room: room, planks: planks, labels: labels, bounds: bounds);
}

/// Which way is in for each wall of a polygon in canvas coordinates. Worked out
/// once per drawing and handed round: it is the same walls for every plank,
/// and [inwardNormals] is the one place that decides what "in" means.
List<Offset> normalsOf(List<Offset> polygon) => [
      for (final normal in inwardNormals([for (final p in polygon) Point(p.dx, p.dy)]))
        Offset(normal.x, normal.y)
    ];

/// The laid floor as the drawing asks about it: its walls, which way is in, and
/// where its inside corner is if it has one.
///
/// One object because the questions all have to be answered about the same
/// floor, and because every one of the answers changes when the floor stops
/// being convex.
class LaidFloor {
  /// The floor's own corners, in canvas coordinates.
  final List<Offset> corners;
  final List<Offset> normals;

  /// Where the floor turns back on itself — the inside corner of a room with a
  /// piece cut out of it. Empty for every room that is convex, and that is the
  /// condition everything below switches on.
  final List<int> reflex;

  LaidFloor(this.corners)
      : normals = normalsOf(corners),
        reflex = reflexCorners([for (final p in corners) Point(p.dx, p.dy)]);

  bool get isConvex => reflex.isEmpty;

  /// How deep inside wall `i` a point lies; negative when outside.
  double depth(Offset point, int i) =>
      (point.dx - corners[i].dx) * normals[i].dx +
      (point.dy - corners[i].dy) * normals[i].dy;

  /// Whether the foot of the perpendicular from [point] onto wall `i` lands on
  /// the wall rather than past one of its ends.
  bool _alongside(Offset point, int i) {
    final from = corners[i];
    final to = corners[(i + 1) % corners.length];
    final edge = to - from;
    final squared = edge.dx * edge.dx + edge.dy * edge.dy;
    if (squared == 0) return false;
    final t = ((point.dx - from.dx) * edge.dx + (point.dy - from.dy) * edge.dy) / squared;
    return t >= 0 && t <= 1;
  }

  /// Which wall [point] is nearest to.
  ///
  /// A wall's line runs on past both of its ends. In a convex room that costs
  /// nothing — the floor is on the inside of every one of those lines — so the
  /// nearest line is the nearest wall, and ties go to the later wall, which is
  /// the order the rectangle case has always resolved them in.
  ///
  /// An inside corner breaks it. The wall that stops at that corner has a line
  /// that carries straight on through the other arm of the room, and reports a
  /// point nowhere near it as being well outside it — which would write the
  /// row widths of half an L-shaped room into the middle of the floor instead
  /// of out past the wall they belong to. So where there is an inside corner,
  /// a wall only counts if the point is level with it. A point outside the
  /// room may be level with none, and then every wall counts again.
  int nearestWall(Offset point) {
    for (final restrict in isConvex ? const [false] : const [true, false]) {
      var nearest = double.infinity;
      var wall = -1;
      for (var i = 0; i < corners.length; i++) {
        if (restrict && !_alongside(point, i)) continue;
        final d = depth(point, i);
        if (d <= nearest) {
          nearest = d;
          wall = i;
        }
      }
      if (wall >= 0) return wall;
    }
    return 0;
  }

  /// The way out of the floor from the wall [point] is nearest to.
  Offset outward(Offset point) {
    final normal = normals[nearestWall(point)];
    return Offset(-normal.dx, -normal.dy);
  }

  /// How far inside the floor a point is, in millimetres; negative when it is
  /// outside.
  ///
  /// Measured to the walls themselves rather than to their lines, for the
  /// reason [nearestWall] gives. For a point inside a convex floor the two
  /// agree exactly; for a room with a corner cut away the line of the wall
  /// that stops at that corner runs on through the other arm, and a plank
  /// standing in that arm is not outside anything.
  double insideDepth(Offset point) {
    var nearest = double.infinity;
    for (var i = 0; i < corners.length; i++) {
      nearest = math.min(nearest, _distanceToWall(point, i));
    }
    return _contains(point) ? nearest : -nearest;
  }

  double _distanceToWall(Offset point, int i) {
    final from = corners[i];
    final to = corners[(i + 1) % corners.length];
    final edge = to - from;
    final squared = edge.dx * edge.dx + edge.dy * edge.dy;
    if (squared == 0) return (point - from).distance;
    final t =
        (((point.dx - from.dx) * edge.dx + (point.dy - from.dy) * edge.dy) / squared)
            .clamp(0.0, 1.0);
    return (point - (from + edge * t)).distance;
  }

  /// Whether [point] is on the inside, by counting how often a ray from it
  /// crosses the walls.
  bool _contains(Offset point) {
    var inside = false;
    for (var i = 0; i < corners.length; i++) {
      final from = corners[i];
      final to = corners[(i + 1) % corners.length];
      if ((from.dy > point.dy) == (to.dy > point.dy)) continue;
      final at = from.dx + (point.dy - from.dy) / (to.dy - from.dy) * (to.dx - from.dx);
      if (point.dx < at) inside = !inside;
    }
    return inside;
  }
}

/// The angle text written along [edge] runs at, turned back when it would come
/// out upside down.
double _alongWall(Offset edge) {
  final angle = math.atan2(edge.dy, edge.dx);
  if (angle > math.pi / 2) return angle - math.pi;
  if (angle < -math.pi / 2) return angle + math.pi;
  return angle;
}

/// How far out of wall [wall] the labels already written beside it reach, so
/// that the wall's own measurement can go past them instead of on top.
double _reservedOutside(List<SchemeLabel> labels, LaidFloor floor, int wall) {
  var out = 0.0;
  for (final label in labels) {
    if (floor.nearestWall(label.centre) != wall) continue;
    final beyond =
        -floor.depth(label.centre, wall) + math.max(label.box.width, label.box.height) / 2;
    out = math.max(out, beyond);
  }
  return out;
}

/// [polygon] with everything outside [floor] cut away.
///
/// Sutherland–Hodgman cuts against one wall's line at a time, which needs the
/// floor to lie on one side of every one of those lines. A room with a corner
/// cut out of it does not: the wall that stops at the inside corner has a line
/// that carries on through the other arm, and cutting against it leaves only
/// the little rectangle where the two arms overlap — which is to say almost
/// every plank disappears. So the inside corner comes out of the loop and goes
/// back in as a corner rather than as two lines: what is beyond *both* of its
/// walls is taken away in one step, by [_withoutCorner].
///
/// A convex floor takes exactly the path it always took, wall by wall and in
/// order, so every drawing made before this keeps every coordinate it had.
///
/// One polygon out, never two, however many corners are cut. A cut corner sits
/// in a corner of the room's own bounding box, so the quarter-plane it takes
/// away reaches in from the outside and bites an *end* off a plank; it cannot
/// reach the middle and part the plank in two. Several cuts bite several ends,
/// and what is left is still one unbroken ring — which is why
/// [PlankShape.outline] is a single list of points.
///
/// The cuts are applied one after another, so every cut after the first is
/// handed a polygon the one before it made concave. That is outside what the
/// argument in [_withoutCorner] covers, and it is checked rather than assumed:
/// test/scheme_geometry_test.dart walks a grid of planks over rooms with two,
/// three and four corners cut away and holds each cut plank against the area
/// arithmetic says it should have.
List<Offset> clipToFloor(List<Offset> polygon, LaidFloor floor) {
  var out = polygon;
  final skip = <int>{};
  for (final corner in floor.reflex) {
    skip.add((corner + floor.corners.length - 1) % floor.corners.length);
    skip.add(corner);
  }
  for (var i = 0; i < floor.corners.length; i++) {
    if (skip.contains(i)) continue;
    final corner = floor.corners[i];
    final normal = floor.normals[i];
    out = _clipHalfPlane(
        out, (p) => (p.dx - corner.dx) * normal.dx + (p.dy - corner.dy) * normal.dy);
    if (out.isEmpty) return out;
  }
  for (final corner in floor.reflex) {
    final before = (corner + floor.corners.length - 1) % floor.corners.length;
    out = _withoutCorner(
        out, floor.corners[corner], floor.normals[before], floor.normals[corner]);
    if (out.isEmpty) return out;
  }
  return out;
}

List<Offset> _clipHalfPlane(List<Offset> polygon, double Function(Offset) depth) {
  final out = <Offset>[];
  for (var i = 0; i < polygon.length; i++) {
    final previous = polygon[(i + polygon.length - 1) % polygon.length];
    final current = polygon[i];
    final before = depth(previous);
    final now = depth(current);
    if ((before < 0) != (now < 0)) {
      final t = before / (before - now);
      out.add(Offset(
        previous.dx + (current.dx - previous.dx) * t,
        previous.dy + (current.dy - previous.dy) * t,
      ));
    }
    if (now >= 0) out.add(current);
  }
  return out;
}

/// Two points the same to within this are the same point. Only ever used to
/// drop a duplicate a cut has just produced on top of a corner that was
/// already there, so it has to be smaller than anything anyone would draw.
const double _crumbMm = 1e-6;

/// [polygon] with the quarter-plane beyond a corner cut away.
///
/// The corner is at [apex] and its two walls run off it with inward normals
/// [normalA] and [normalB]; what goes is everything beyond both at once.
///
/// The ring is walked once, keeping what the cut leaves and adding a point
/// wherever the walk crosses one of the two walls. The corner's own tip is put
/// back wherever the walk leaves on one wall and comes back on the other,
/// which is the only way it can be reached on a convex [polygon]: between two
/// crossings of the *same* wall the boundary is a straight chord and the tip
/// is not on it.
///
/// A polygon an earlier cut has already made concave is outside that argument,
/// and the rule holds there anyway — see [clipToFloor] for which test says so
/// and how. Written out because the two statements are easy to confuse: the
/// *reasoning* here needs convexity, the *code* turns out not to.
///
/// Landing exactly on a wall is the ordinary case here, not a rare one — a row
/// boundary or a plank end sits on the wall of the cut as often as not — so
/// both decisions are made strictly. A crossing counts only where the edge
/// passes from one side of a wall clear to the other, and a corner sitting on
/// a wall is kept only if an edge leads off it back into the room. Keeping
/// such a corner regardless is what a first draft of this did, and it left a
/// plank whose end lay along the cut wearing a flat spike into it: no area to
/// speak of, but enough to send the outline round the wrong way and draw the
/// plank into the void.
List<Offset> _withoutCorner(
    List<Offset> polygon, Offset apex, Offset normalA, Offset normalB) {
  double depth(Offset p, Offset normal) =>
      (p.dx - apex.dx) * normal.dx + (p.dy - apex.dy) * normal.dy;
  double leads(Offset from, Offset to, Offset normal) =>
      (to.dx - from.dx) * normal.dx + (to.dy - from.dy) * normal.dy;

  bool keeps(int i) {
    final corner = polygon[i];
    final a = depth(corner, normalA);
    final b = depth(corner, normalB);
    if (a > 0 || b > 0) return true;
    if (a < 0 && b < 0) return false;
    // On one of the two walls, with none of the room on the other side of it
    // just here. Such a corner belongs to the piece only if an edge leads off
    // it back into the room; otherwise it is the tip of a sliver the cut left
    // behind, and a sliver is not a shape.
    for (final to in [
      polygon[(i + polygon.length - 1) % polygon.length],
      polygon[(i + 1) % polygon.length],
    ]) {
      if (a == 0 && leads(corner, to, normalA) > 0) return true;
      if (b == 0 && leads(corner, to, normalB) > 0) return true;
    }
    return false;
  }

  final points = <Offset>[];
  // Which of the two walls each point was cut on, or -1 for a corner of
  // [polygon] that the cut did not touch.
  final onWall = <int>[];
  void add(Offset point, int wall) {
    if (points.isNotEmpty) {
      final last = points.last;
      if ((last.dx - point.dx).abs() < _crumbMm && (last.dy - point.dy).abs() < _crumbMm) {
        return;
      }
    }
    points.add(point);
    onWall.add(wall);
  }

  for (var i = 0; i < polygon.length; i++) {
    final previous = polygon[(i + polygon.length - 1) % polygon.length];
    final current = polygon[i];
    // Where this edge meets each of the two walls, in the order it meets them.
    final crossings = <double>[];
    final walls = <int>[];
    for (var wall = 0; wall < 2; wall++) {
      final normal = wall == 0 ? normalA : normalB;
      final other = wall == 0 ? normalB : normalA;
      final before = depth(previous, normal);
      final now = depth(current, normal);
      if (!((before > 0 && now < 0) || (before < 0 && now > 0))) continue;
      final t = before / (before - now);
      final at = Offset(
        previous.dx + (current.dx - previous.dx) * t,
        previous.dy + (current.dy - previous.dy) * t,
      );
      // Past the apex the wall's line is inside the room, and crossing it
      // there cuts nothing.
      if (depth(at, other) > 0) continue;
      crossings.add(t);
      walls.add(wall);
    }
    if (crossings.length == 2 && crossings[0] > crossings[1]) {
      crossings.insert(0, crossings.removeLast());
      walls.insert(0, walls.removeLast());
    }
    for (var c = 0; c < crossings.length; c++) {
      final t = crossings[c];
      add(
        Offset(
          previous.dx + (current.dx - previous.dx) * t,
          previous.dy + (current.dy - previous.dy) * t,
        ),
        walls[c],
      );
    }
    if (keeps(i)) add(current, -1);
  }

  if (points.length < 3) return const [];
  final out = <Offset>[];
  for (var i = 0; i < points.length; i++) {
    out.add(points[i]);
    final next = (i + 1) % points.length;
    if (onWall[i] >= 0 && onWall[next] >= 0 && onWall[i] != onWall[next]) out.add(apex);
  }
  return out;
}

/// How far past its centreline a bevelled end reaches on the far side of the
/// row, negative when the long corner is on the near side instead.
///
/// Measured against the row's own half width, not the plank's: the sliver of a
/// row against a far corner is ripped narrow, and its end slants across only
/// what is left of it.
double _bevelReach(Bevel bevel, double halfWidth) => halfWidth * bevel.slope;

/// Room coordinates from row coordinates: `u` along the rows, `v` across them.
class _Placement {
  final double angle;
  final Offset Function(double u, double v) _map;

  const _Placement(this.angle, this._map);

  Offset call(double u, double v) => _map(u, v);
}

/// The one place a laying direction becomes a position on the floor. It has to
/// undo exactly what [planFor] did, or the planks land somewhere the room is
/// not.
///
/// A rectangle keeps a closed form of its own, because [planFor] does: its rows
/// come from [straightPlan] and [diagonalPlan], which measure from the room's
/// own corners rather than from an outline that was turned and measured.
///
/// The 45° map is fixed by where [diagonalPlan] measures from: `v` is the
/// distance from the corner the layout starts at, and `u` is measured along the
/// rows from a zero chosen so that the row starting on the wall `x = 0` sits at
/// `u = b/√2`. Reading that back gives the map below — and the corner the rows
/// run out at lands exactly on `(a, b)`, which is what
/// test/scheme_geometry_test.dart checks.
_Placement _placement(Result result, List<Offset> floor) {
  final angle = result.direction == Direction.diagonal ? -math.pi / 4 : 0.0;
  if (result.shape.isRectangular) {
    final indent = result.indentFromWall.toDouble();
    final rectangle = result.shape as RoomShape;
    final b = (rectangle.widthLeft - result.indentFromWall * 2).toDouble();
    switch (result.direction) {
      // Rows parallel to a wall are always drawn left to right; laying across
      // the room turns the room instead, in [drawnRoom].
      case Direction.length:
      case Direction.width:
        return _Placement(0, (u, v) => Offset(indent + u, indent + v));
      case Direction.diagonal:
        return _Placement(
          angle,
          (u, v) => Offset(
            indent + (u + v) / math.sqrt2 - b / 2,
            indent + (v - u) / math.sqrt2 + b / 2,
          ),
        );
    }
  }
  // Any other room is laid out by [scanPlan], which turned the floor until the
  // rows ran along `u` and then measured from its near corner. Turn it back.
  final rotated = rowFrame([for (final p in floor) Point(p.dx, p.dy)], angle);
  var uMin = double.infinity;
  var vMin = double.infinity;
  for (final corner in rotated) {
    uMin = math.min(uMin, corner.x);
    vMin = math.min(vMin, corner.y);
  }
  final cos = math.cos(angle);
  final sin = math.sin(angle);
  return _Placement(angle, (u, v) {
    final uAbs = uMin + u;
    final vAbs = vMin + v;
    return Offset(uAbs * cos - vAbs * sin, uAbs * sin + vAbs * cos);
  });
}
