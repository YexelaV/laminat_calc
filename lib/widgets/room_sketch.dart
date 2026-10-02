// A small drawing of the room as its measurements describe it, with each
// measurement written on the wall it belongs to.
//
// Without it the form asks for "length 2" and the user has to guess which wall
// that is, and for a diagonal without saying between which corners. Drawn to
// scale, it answers both without a word of text, and a measurement that makes
// no room shows up as a shape that is obviously wrong before the Next button
// ever explains why.
//
// A room with a corner cut away asks one more question the fields cannot: which
// corner. The sketch answers that one too, and takes the answer — the corners
// are the targets, so the user points at the corner rather than reading four
// names and matching them to a picture.
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../room_shape.dart';
import '../utils/units.dart';

/// How much of the box the outline takes, leaving the rest for the labels that
/// sit outside it.
const double _fill = 0.66;
const double _labelSize = 11;

/// Material's smallest comfortable target. The outline is 99 px tall, so four
/// of these at its corners clear each other with room to spare.
const double _cornerTarget = 44;

/// Where the sketch puts a point of the room in the box it was given.
///
/// Shared by the painter and the corner targets, so that a tap lands on the
/// corner it is drawn over rather than near it.
class SketchProjection {
  final Rect bounds;
  final double scale;
  final Offset centre;

  const SketchProjection._(this.bounds, this.scale, this.centre);

  factory SketchProjection(List<Offset> corners, Size box) {
    var bounds = Rect.fromPoints(corners.first, corners.first);
    for (final corner in corners.skip(1)) {
      bounds = bounds.expandToInclude(Rect.fromPoints(corner, corner));
    }
    final scale = math.min(
      box.width * _fill / bounds.width,
      box.height * _fill / bounds.height,
    );
    return SketchProjection._(bounds, scale, Offset(box.width / 2, box.height / 2));
  }

  bool get isUsable => bounds.width > 0 && bounds.height > 0;

  Offset call(Offset mm) => centre + (mm - bounds.center) * scale;
}

class RoomSketch extends StatelessWidget {
  final RoomOutline shape;
  final MeasurementSystem system;

  /// Which corner is cut away, drawn as the handle that is filled in. Null for
  /// a room with no corner to cut, which is every room but a Г-shaped one.
  final RoomCorner? cutCorner;

  /// What to do when one of the four corners is tapped. Null leaves the sketch
  /// a picture, which is what a room measured wall by wall wants.
  final ValueChanged<RoomCorner>? onCorner;

  const RoomSketch({
    super.key,
    required this.shape,
    required this.system,
    this.cutCorner,
    this.onCorner,
  });

  /// The outline to draw. Measurements that describe no room are drawn as the
  /// shape they would be if they did, greyed out: something has to be on
  /// screen while a digit is half typed, and a folded-over outline is worse
  /// than none.
  List<Offset> _outline() {
    final closes = shape.problem == null;
    final RoomOutline drawable;
    if (closes) {
      drawable = shape;
    } else if (shape is LRoomShape) {
      // Clamped rather than replaced by a rectangle: the user is reading this
      // picture to see which corner is cut, and taking the cut away while
      // they type the number of it answers a question they did not ask.
      final l = shape as LRoomShape;
      drawable = LRoomShape(
        length: l.length,
        width: l.width,
        notchLength: l.notchLength.clamp(1, l.length - 1),
        notchWidth: l.notchWidth.clamp(1, l.width - 1),
        corner: l.corner,
      );
    } else {
      final quadrilateral = shape as RoomShape;
      drawable = RoomShape.rectangle(quadrilateral.lengthNear, quadrilateral.widthLeft);
    }
    return [for (final p in drawable.corners()) Offset(p.x, p.y)];
  }

  @override
  Widget build(BuildContext context) {
    final closes = shape.problem == null;
    final corners = _outline();
    final quadrilateral = shape is RoomShape ? shape as RoomShape : null;
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final box = Size(constraints.maxWidth, constraints.maxHeight);
          final place = SketchProjection(corners, box);
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoomSketchPainter(
                    corners: corners,
                    labels: [
                      for (final wall in shape.wallLengths()) sizeLabel(wall, system)
                    ],
                    diagonalLabel: quadrilateral == null
                        ? null
                        : sizeLabel(quadrilateral.diagonal, system),
                    cutCorner: cutCorner,
                    closes: closes,
                    place: place,
                    textStyle: DefaultTextStyle.of(context).style,
                  ),
                ),
              ),
              if (onCorner != null && place.isUsable)
                for (final corner in RoomCorner.values)
                  _target(context, corner, place),
            ],
          );
        },
      ),
    );
  }

  /// A tap target over one corner of the bounding rectangle.
  ///
  /// The bounding rectangle and not the outline: the cut corner is the one
  /// corner of the four that is *not* on the outline, and it has to be as easy
  /// to point at as the other three.
  Widget _target(BuildContext context, RoomCorner corner, SketchProjection place) {
    final at = place(_cornerOf(corner, place.bounds));
    return Positioned(
      left: at.dx - _cornerTarget / 2,
      top: at.dy - _cornerTarget / 2,
      width: _cornerTarget,
      height: _cornerTarget,
      child: Semantics(
        button: true,
        selected: corner == cutCorner,
        label: _cornerName(context, corner),
        child: GestureDetector(
          key: ValueKey('cut-corner-${corner.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onCorner!(corner),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Which corner of the bounding rectangle each name points at, with the near
/// wall drawn along the top as the finished scheme draws it.
Offset _cornerOf(RoomCorner corner, Rect bounds) {
  switch (corner) {
    case RoomCorner.nearLeft:
      return bounds.topLeft;
    case RoomCorner.nearRight:
      return bounds.topRight;
    case RoomCorner.farRight:
      return bounds.bottomRight;
    case RoomCorner.farLeft:
      return bounds.bottomLeft;
  }
}

/// Named by where it is in the picture rather than by near and far. The sketch
/// is right beside the control, so "top left" is read off the drawing; "near
/// left" would have to be worked out from it.
String _cornerName(BuildContext context, RoomCorner corner) {
  final strings = AppStrings.of(context);
  switch (corner) {
    case RoomCorner.nearLeft:
      return strings.corner_top_left;
    case RoomCorner.nearRight:
      return strings.corner_top_right;
    case RoomCorner.farRight:
      return strings.corner_bottom_right;
    case RoomCorner.farLeft:
      return strings.corner_bottom_left;
  }
}

class _RoomSketchPainter extends CustomPainter {
  final List<Offset> corners;

  /// One per wall, in the order the corners run.
  final List<String> labels;

  /// Null for a room that has no diagonal to measure.
  final String? diagonalLabel;

  /// The corner cut away, drawn as a filled handle among three hollow ones.
  final RoomCorner? cutCorner;

  final bool closes;
  final SketchProjection place;
  final TextStyle textStyle;

  const _RoomSketchPainter({
    required this.corners,
    required this.labels,
    required this.diagonalLabel,
    required this.cutCorner,
    required this.closes,
    required this.place,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!place.isUsable) return;
    Offset px(Offset mm) => place(mm);

    final colour = closes ? Colors.blue : Colors.grey;
    final wall = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = colour;
    final path = Path()..moveTo(px(corners.first).dx, px(corners.first).dy);
    for (final corner in corners.skip(1)) {
      path.lineTo(px(corner).dx, px(corner).dy);
    }
    canvas.drawPath(path..close(), wall);

    // The diagonal, dashed so it reads as a measurement rather than a wall.
    if (diagonalLabel != null) {
      _dashed(canvas, px(corners[0]), px(corners[2]), colour);
    }

    // Each measurement sits just outside the wall it belongs to, pushed out
    // along that wall's own normal rather than away from the middle of the
    // room: in a badly out-of-square room the middle is not reliably on the
    // other side of the wall, and the label lands back on the drawing.
    final normals = inwardNormals([for (final p in corners) Point(p.dx, p.dy)]);
    final taken = <Rect>[];
    for (var i = 0; i < corners.length && i < labels.length; i++) {
      final middle = (px(corners[i]) + px(corners[(i + 1) % corners.length])) / 2;
      final outward = -Offset(normals[i].x, normals[i].y);
      var at = middle + outward * 15;
      // The two walls of a cut-away corner are short and meet each other, so
      // their middles are a few pixels apart and their measurements land on
      // top of one another. Each steps further out along its own wall until
      // it is clear of the ones already written — out, so that it still reads
      // as belonging to its wall rather than to a neighbour.
      for (var step = 0; step < 4; step++) {
        final box = _box(labels[i], at).inflate(2);
        if (!taken.any(box.overlaps)) break;
        at += outward * 10;
      }
      taken.add(_box(labels[i], at));
      _text(canvas, labels[i], at, colour);
    }

    if (cutCorner != null) _handles(canvas, colour);

    if (diagonalLabel == null) return;
    // The diagonal's own number goes as near the middle of it as it can while
    // still clearing the wall labels. The middle itself is the obvious place
    // and often the wrong one: it is the height the two side walls carry their
    // labels at, and in a badly out-of-square room it is where a corner is.
    final from = px(corners[0]);
    final along = px(corners[2]) - from;
    var best = from + along * 0.5;
    var least = double.infinity;
    for (final fraction in [0.5, 0.42, 0.58, 0.34, 0.66, 0.26, 0.74]) {
      final at = from + along * fraction;
      final box = _box(diagonalLabel!, at).inflate(2);
      final overlap = taken.fold<double>(0, (sum, other) {
        final shared = box.intersect(other);
        return sum + (shared.isEmpty ? 0 : shared.width * shared.height);
      });
      if (overlap < least) {
        least = overlap;
        best = at;
        if (overlap == 0) break;
      }
    }
    _text(canvas, diagonalLabel!, best, colour, background: true);
  }

  /// The four corners as handles, the cut one filled. Three of them sit on the
  /// outline and one floats in the space the cut left, which is the whole
  /// point: that space is where the user is about to point.
  void _handles(Canvas canvas, Color colour) {
    for (final corner in RoomCorner.values) {
      final at = place(_cornerOf(corner, place.bounds));
      final chosen = corner == cutCorner;
      canvas.drawCircle(
        at,
        chosen ? 6 : 4,
        Paint()
          ..style = chosen ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = chosen ? colour : colour.withValues(alpha: 0.4),
      );
    }
  }

  void _dashed(Canvas canvas, Offset from, Offset to, Color colour) {
    const dash = 6.0;
    const gap = 4.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colour.withValues(alpha: 0.6);
    final total = (to - from).distance;
    if (total == 0) return;
    final step = (to - from) / total;
    for (var at = 0.0; at < total; at += dash + gap) {
      canvas.drawLine(from + step * at, from + step * math.min(at + dash, total), paint);
    }
  }

  TextPainter _layout(String text, Color colour) => TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(fontSize: _labelSize, color: colour),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  /// Where [text] would sit if it were written centred on [centre].
  Rect _box(String text, Offset centre) {
    final painter = _layout(text, Colors.black);
    return Rect.fromCenter(center: centre, width: painter.width, height: painter.height);
  }

  void _text(Canvas canvas, String text, Offset centre, Color colour,
      {bool background = false}) {
    final painter = _layout(text, colour);
    final at = centre - Offset(painter.width / 2, painter.height / 2);
    if (background) {
      // The diagonal runs under its own label; blanking the line behind it
      // keeps the number readable.
      canvas.drawRect(
        Rect.fromLTWH(at.dx - 2, at.dy, painter.width + 4, painter.height),
        Paint()..color = Colors.white,
      );
    }
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_RoomSketchPainter old) =>
      !listEquals(old.corners, corners) ||
      !listEquals(old.labels, labels) ||
      old.diagonalLabel != diagonalLabel ||
      old.cutCorner != cutCorner ||
      old.closes != closes;
}
