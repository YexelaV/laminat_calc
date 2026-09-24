// A small drawing of the room as the five measurements describe it, with each
// measurement written on the wall it belongs to.
//
// Without it the form asks for "length 2" and the user has to guess which wall
// that is, and for a diagonal without saying between which corners. Drawn to
// scale, it answers both without a word of text, and a measurement that makes
// no room shows up as a shape that is obviously wrong before the Next button
// ever explains why.
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter/material.dart';

import '../room_shape.dart';
import '../utils/units.dart';

/// How much of the box the outline takes, leaving the rest for the labels that
/// sit outside it.
const double _fill = 0.66;
const double _labelSize = 11;

class RoomSketch extends StatelessWidget {
  final RoomShape shape;
  final MeasurementSystem system;

  const RoomSketch({super.key, required this.shape, required this.system});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 150,
        width: double.infinity,
        child: CustomPaint(
          painter: _RoomSketchPainter(
            shape: shape,
            labels: [
              sizeLabel(shape.lengthNear, system),
              sizeLabel(shape.widthRight, system),
              sizeLabel(shape.lengthFar, system),
              sizeLabel(shape.widthLeft, system),
            ],
            diagonalLabel: sizeLabel(shape.diagonal, system),
            closes: shape.problem == null,
            textStyle: DefaultTextStyle.of(context).style,
          ),
        ),
      );
}

class _RoomSketchPainter extends CustomPainter {
  final RoomShape shape;

  /// One per wall, in the order the corners run.
  final List<String> labels;
  final String diagonalLabel;

  /// Measurements that describe no room are drawn as the rectangle they would
  /// be if they did, greyed out: something has to be on screen while a digit is
  /// half typed, and a folded-over outline is worse than none.
  final bool closes;
  final TextStyle textStyle;

  const _RoomSketchPainter({
    required this.shape,
    required this.labels,
    required this.diagonalLabel,
    required this.closes,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final measured = closes
        ? shape.corners()
        : [
            const Point<double>(0, 0),
            Point<double>(shape.lengthNear.toDouble(), 0),
            Point<double>(shape.lengthNear.toDouble(), shape.widthLeft.toDouble()),
            Point<double>(0, shape.widthLeft.toDouble()),
          ];
    final corners = [for (final p in measured) Offset(p.x, p.y)];
    var bounds = Rect.fromPoints(corners.first, corners.first);
    for (final corner in corners.skip(1)) {
      bounds = bounds.expandToInclude(Rect.fromPoints(corner, corner));
    }
    if (bounds.width <= 0 || bounds.height <= 0) return;
    final scale = math.min(
      size.width * _fill / bounds.width,
      size.height * _fill / bounds.height,
    );
    final centre = Offset(size.width / 2, size.height / 2);
    Offset px(Offset mm) => centre + (mm - bounds.center) * scale;

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
    _dashed(canvas, px(corners[0]), px(corners[2]), colour);

    // Each measurement sits just outside the wall it belongs to, pushed out
    // along that wall's own normal rather than away from the middle of the
    // room: in a badly out-of-square room the middle is not reliably on the
    // other side of the wall, and the label lands back on the drawing.
    final normals = inwardNormals(measured);
    final taken = <Rect>[];
    for (var i = 0; i < corners.length; i++) {
      final middle = (px(corners[i]) + px(corners[(i + 1) % corners.length])) / 2;
      final at = middle - Offset(normals[i].x, normals[i].y) * 15;
      taken.add(_box(labels[i], at));
      _text(canvas, labels[i], at, colour);
    }

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
      final box = _box(diagonalLabel, at).inflate(2);
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
    _text(canvas, diagonalLabel, best, colour, background: true);
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
      old.shape.lengthNear != shape.lengthNear ||
      old.shape.lengthFar != shape.lengthFar ||
      old.shape.widthLeft != shape.widthLeft ||
      old.shape.widthRight != shape.widthRight ||
      old.shape.diagonal != shape.diagonal ||
      old.closes != closes ||
      old.diagonalLabel != diagonalLabel;
}
