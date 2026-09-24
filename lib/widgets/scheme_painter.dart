// Draws a [Scheme] on a canvas. Everything about where things go is decided in
// scheme_geometry.dart; this only turns millimetres into pixels and fits the
// text into the boxes it is given.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../scheme_geometry.dart';

/// The size the text is measured at before being scaled to its box. Large
/// enough that the ratio it yields is not quantised by hinting.
const double _referenceFontSize = 100;

class SchemePainter extends CustomPainter {
  final Scheme scheme;

  /// Pixels per millimetre of room.
  final double scale;

  /// The face to write the labels in. A canvas inherits nothing, so without
  /// this the text falls back to the platform default rather than the font the
  /// rest of the app is set in — visible as boxes wherever that default is not
  /// installed. Size, weight and colour are set here; only the family is taken.
  final TextStyle style;

  const SchemePainter(this.scheme, this.scale, this.style);

  Offset _px(Offset mm) => Offset(
        (mm.dx - scheme.bounds.left) * scale,
        (mm.dy - scheme.bounds.top) * scale,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey
      ..strokeWidth = 1;
    canvas.drawPath(_outlineOf(scheme.room), wall);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 1;
    for (final shape in scheme.planks) {
      canvas.drawPath(_outlineOf(shape.outline), edge);
    }

    for (final label in scheme.labels) {
      _drawLabel(canvas, label);
    }
  }

  /// A closed path through [corners]. The walls are drawn the same way the
  /// planks are, because a room whose opposite walls differ is no more a
  /// rectangle than a plank cut against one is.
  Path _outlineOf(List<Offset> corners) {
    final path = Path();
    for (var i = 0; i < corners.length; i++) {
      final p = _px(corners[i]);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  void _drawLabel(Canvas canvas, SchemeLabel label) {
    final box = Size(label.box.width * scale, label.box.height * scale);
    if (box.width <= 0 || box.height <= 0) return;
    // Measure once at a reference size and once at the size that measurement
    // implies: a proportional font does not scale its metrics exactly, but one
    // correction is enough to land inside the box.
    final measured = _layout(label, _referenceFontSize);
    final ratio = math.min(box.width / measured.width, box.height / measured.height);
    if (!ratio.isFinite || ratio <= 0) return;
    final fitted = _layout(label, _referenceFontSize * ratio);

    final centre = _px(label.centre);
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(label.angle);
    fitted.paint(canvas, Offset(-fitted.width / 2, -fitted.height / 2));
    canvas.restore();
  }

  TextPainter _layout(SchemeLabel label, double fontSize) => TextPainter(
        text: TextSpan(
          text: label.text,
          style: style.copyWith(
            fontSize: fontSize,
            color: Colors.black,
            fontWeight: label.bold ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  bool shouldRepaint(SchemePainter old) =>
      old.scheme != scheme || old.scale != scale || old.style != style;
}
