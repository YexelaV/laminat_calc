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
import 'dart:ui';

import 'models.dart';
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
  /// The walls. The laid area sits inside it by the expansion gap.
  final Rect room;
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

/// The room as it is drawn, in millimetres: width across the page, height down
/// it.
///
/// Planks are read along their length, so a row is always drawn running left to
/// right. Laying across the room therefore turns the room a quarter of a turn
/// rather than the rows — its width goes across the page and its length down it.
/// The scheme screen asks the same question of the same function to decide which
/// way up the phone should be.
Size drawnRoomSize(Result result) => result.direction == Direction.width
    ? Size(result.roomWidth.toDouble(), result.roomLength.toDouble())
    : Size(result.roomLength.toDouble(), result.roomWidth.toDouble());

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
  final a = (result.roomLength - result.indentFromWall * 2).toDouble();
  final b = (result.roomWidth - result.indentFromWall * 2).toDouble();
  final place = _placement(result.direction, indent: indent, a: a, b: b);
  final drawn = drawnRoomSize(result);
  final floor = Rect.fromLTWH(
      indent, indent, drawn.width - indent * 2, drawn.height - indent * 2);

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
        ], floor),
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
    final outward = _outward(start, floor);
    labels.add(SchemeLabel(
      rowLabels[i],
      start + outward * (gutter / 2 + indent),
      // Labels off a side wall stack downwards and are written across; labels
      // off a top or bottom wall stack sideways and have to be turned, or each
      // would be written over the next.
      outward.dx == 0 ? math.pi / 2 : 0,
      Size(gutter, width * _textFill),
    ));
    v += width;
  }

  final room = Offset.zero & drawn;
  var bounds = room;
  for (final label in labels) {
    bounds = bounds.expandToInclude(Rect.fromCircle(
      center: label.centre,
      radius: math.max(label.box.width, label.box.height) / 2,
    ));
  }
  return Scheme(room: room, planks: planks, labels: labels, bounds: bounds);
}

/// The way out of [rect] from the wall [point] is nearest to.
Offset _outward(Offset point, Rect rect) {
  final away = <double, Offset>{
    point.dx - rect.left: const Offset(-1, 0),
    rect.right - point.dx: const Offset(1, 0),
    point.dy - rect.top: const Offset(0, -1),
    rect.bottom - point.dy: const Offset(0, 1),
  };
  return away[away.keys.reduce(math.min)]!;
}

/// [polygon] with everything outside [rect] cut away, by Sutherland–Hodgman.
/// Convex against convex, so the result is one polygon and no hole.
List<Offset> _clip(List<Offset> polygon, Rect rect) {
  var out = polygon;
  for (final depth in <double Function(Offset)>[
    (p) => p.dx - rect.left,
    (p) => rect.right - p.dx,
    (p) => p.dy - rect.top,
    (p) => rect.bottom - p.dy,
  ]) {
    out = _clipHalfPlane(out, depth);
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
double _bevelReach(Bevel bevel, double halfWidth) {
  switch (bevel) {
    case Bevel.square:
      return 0;
    case Bevel.up:
      return halfWidth;
    case Bevel.down:
      return -halfWidth;
  }
}

/// Room coordinates from row coordinates: `u` along the rows, `v` across them.
class _Placement {
  final double angle;
  final Offset Function(double u, double v) _map;

  const _Placement(this.angle, this._map);

  Offset call(double u, double v) => _map(u, v);
}

/// The one place a laying direction becomes a position on the floor.
///
/// The 45° map is fixed by where [diagonalPlan] measures from: `v` is the
/// distance from the corner the layout starts at, and `u` is measured along the
/// rows from a zero chosen so that the row starting on the wall `x = 0` sits at
/// `u = b/√2`. Reading that back gives the map below — and the corner the rows
/// run out at lands exactly on `(a, b)`, which is what
/// test/scheme_geometry_test.dart checks.
_Placement _placement(Direction direction,
    {required double indent, required double a, required double b}) {
  switch (direction) {
    // Rows parallel to a wall are always drawn left to right; laying across the
    // room turns the room instead, in [drawnRoomSize].
    case Direction.length:
    case Direction.width:
      return _Placement(0, (u, v) => Offset(indent + u, indent + v));
    case Direction.diagonal:
      return _Placement(
        -math.pi / 4,
        (u, v) => Offset(
          indent + (u + v) / math.sqrt2 - b / 2,
          indent + (v - u) / math.sqrt2 + b / 2,
        ),
      );
  }
}
