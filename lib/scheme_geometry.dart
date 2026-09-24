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
  /// expansion gap. Four corners always, but not a rectangle unless the room
  /// was measured as one.
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

/// The room's own geometry comes in as plain points — [RoomShape] and [planFor]
/// have no business knowing about canvases — and turns into canvas coordinates
/// here, which is the first place they mean anything.
///
/// The quarter turn is [RoomShape.turned], the same one [planFor] lays the rows
/// through. One function rather than two matching ones: they used to be a
/// transpose apiece, each right about the other and both mirroring the room.
List<Offset> _asDrawn(RoomShape shape, List<Point<double>> polygon, Direction direction) {
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
  final floor = drawnFloor(result);
  final floorNormals = normalsOf(floor);
  final place = _placement(result, floor);

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
        _clip([
          place(u0 + left, vLo),
          place(u1 - right, vLo),
          place(u1 + right, vHi),
          place(u0 - left, vHi),
        ], floor, floorNormals),
      ));

      // The bounding box of a trapezoid lies about the room for text: only the
      // shorter of the two parallel edges is backed by material end to end.
      final from = u0 + left.abs();
      final usable = plank.length - left.abs() - right.abs();
      final vMid = (vLo + vHi) / 2;
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
    final outward = _outward(start, floor, floorNormals);
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
  final walls = [
    result.shape.lengthNear,
    result.shape.widthRight,
    result.shape.lengthFar,
    result.shape.widthLeft,
  ];
  final roomNormals = normalsOf(room);
  for (var i = 0; i < room.length; i++) {
    final from = room[i];
    final to = room[(i + 1) % room.length];
    final text = sizeLabel(walls[i], system);
    final outward = Offset(-roomNormals[i].dx, -roomNormals[i].dy);
    labels.add(SchemeLabel(
      text,
      (from + to) / 2 +
          outward *
              (_reservedOutside(labels, floor, floorNormals, i) + gutterHeight / 2 + indent),
      _alongWall(to - from),
      Size(_textWidth(text, gutterHeight), gutterHeight),
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
/// once per drawing and handed round: it is the same four walls for every plank,
/// and [inwardNormals] is the one place that decides what "in" means.
List<Offset> normalsOf(List<Offset> polygon) => [
      for (final normal in inwardNormals([for (final p in polygon) Point(p.dx, p.dy)]))
        Offset(normal.x, normal.y)
    ];

/// How deep inside the wall `i` of [floor] a point lies; negative when outside.
double _depth(Offset point, List<Offset> floor, List<Offset> normals, int i) =>
    (point.dx - floor[i].dx) * normals[i].dx + (point.dy - floor[i].dy) * normals[i].dy;

/// Which wall of [floor] a point is nearest to.
int _nearestWall(Offset point, List<Offset> floor, List<Offset> normals) {
  var nearest = double.infinity;
  var wall = 0;
  for (var i = 0; i < floor.length; i++) {
    final depth = _depth(point, floor, normals, i);
    // Ties go to the later wall, which is the order the rectangle case has
    // always resolved them in.
    if (depth <= nearest) {
      nearest = depth;
      wall = i;
    }
  }
  return wall;
}

/// The way out of [floor] from the wall [point] is nearest to.
Offset _outward(Offset point, List<Offset> floor, List<Offset> normals) {
  final normal = normals[_nearestWall(point, floor, normals)];
  return Offset(-normal.dx, -normal.dy);
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
double _reservedOutside(
    List<SchemeLabel> labels, List<Offset> floor, List<Offset> normals, int wall) {
  var out = 0.0;
  for (final label in labels) {
    if (_nearestWall(label.centre, floor, normals) != wall) continue;
    final beyond = -_depth(label.centre, floor, normals, wall) +
        math.max(label.box.width, label.box.height) / 2;
    out = math.max(out, beyond);
  }
  return out;
}

/// [polygon] with everything outside [floor] cut away, by Sutherland–Hodgman.
/// Convex against convex, so the result is one polygon and no hole.
List<Offset> _clip(List<Offset> polygon, List<Offset> floor, List<Offset> normals) {
  var out = polygon;
  for (var i = 0; i < floor.length; i++) {
    final corner = floor[i];
    final normal = normals[i];
    out = _clipHalfPlane(
        out, (p) => (p.dx - corner.dx) * normal.dx + (p.dy - corner.dy) * normal.dy);
    if (out.isEmpty) break;
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
    final b = (result.shape.widthLeft - result.indentFromWall * 2).toDouble();
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
