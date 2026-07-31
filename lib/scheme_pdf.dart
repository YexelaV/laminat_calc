// The same scheme on a page. Nothing here decides where anything goes — that is
// scheme_geometry.dart — so the sheet a fitter carries and the screen he checks
// it against cannot disagree.
import 'dart:math' as math;

// Matrix4 comes from vector_math, which both Flutter and the pdf package build
// on; taking it from Flutter keeps it out of pubspec.yaml.
import 'package:flutter/widgets.dart' show AssetBundle, Matrix4;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'models.dart';
import 'scheme_geometry.dart';
import 'utils/units.dart';

// A printed page cannot be zoomed. Text smaller than this is not worth the ink,
// and the ladder in buildScheme drops it.
const double _minTextPt = 3.5;

/// The face the page is set in, in plain and bold.
///
/// The pdf package cannot reach the app's fonts, and its built-in Type 1 ones
/// carry no glyph past U+00FF and throw rather than substitute — which is why
/// Roboto is shipped as an asset. It covers every alphabet the app is
/// translated into except Chinese; [PdfFonts.canPrint] is how the cut list finds
/// that out before it is written rather than after.
class PdfFonts {
  final pw.Font plain;
  final pw.Font bold;
  final Set<int> _glyphs;

  PdfFonts._(this.plain, this.bold, this._glyphs);

  static Future<PdfFonts> load(AssetBundle bundle) async {
    final plain = await bundle.load('assets/fonts/Roboto-Regular.ttf');
    final bold = await bundle.load('assets/fonts/Roboto-Bold.ttf');
    return PdfFonts._(
      pw.Font.ttf(plain),
      pw.Font.ttf(bold),
      TtfParser(plain).charToGlyphIndexMap.keys.toSet(),
    );
  }

  /// Whether every character of [text] has a glyph. A character without one
  /// prints as an empty box, so the caller leaves the text out instead.
  bool canPrint(String text) => text.runes.every(_glyphs.contains);
}

/// The finished layout: the scheme on its own sheet, then [cutList] if it is
/// given and the font can print it.
///
/// The scheme's sheet is turned to match the drawing. A page cannot be panned,
/// so the scheme is fitted to it, and fitting a tall drawing to a wide sheet
/// would print it at half the size for no reason.
pw.Document schemePdf(
  Result result,
  MeasurementSystem system,
  PdfFonts fonts, {
  List<String> cutList = const [],
}) {
  // The bounds barely move with the text floor, so measure with no floor, fix
  // the scale, then build the scheme the page actually gets.
  final measured = buildScheme(result, system: system, minTextMm: 0);
  final format = measured.bounds.width >= measured.bounds.height
      ? PdfPageFormat.a4.landscape
      : PdfPageFormat.a4.portrait;
  final scale = math.min(
    format.availableWidth / measured.bounds.width,
    format.availableHeight / measured.bounds.height,
  );
  final scheme = buildScheme(result, system: system, minTextMm: _minTextPt / scale);

  final pdf = pw.Document();
  pdf.addPage(pw.Page(
    pageFormat: format,
    build: (context) => pw.CustomPaint(
      size: PdfPoint(scheme.bounds.width * scale, scheme.bounds.height * scale),
      painter: (canvas, size) => _paint(
        canvas,
        size,
        scheme,
        scale,
        fonts.plain.getFont(context),
        fonts.bold.getFont(context),
      ),
    ),
  ));

  // A line the font cannot print would come out as a row of empty boxes, so the
  // report is left off the page whole rather than in part — it is still shared
  // as text from the cut list sheet.
  if (cutList.isNotEmpty && cutList.every(fonts.canPrint)) {
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text(cutList.first, style: pw.TextStyle(font: fonts.bold, fontSize: 14)),
        pw.SizedBox(height: 12),
        for (final line in cutList.skip(1))
          if (line.isEmpty)
            pw.SizedBox(height: 10)
          else
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(line, style: pw.TextStyle(font: fonts.plain, fontSize: 10)),
            ),
      ],
    ));
  }
  return pdf;
}

void _paint(
  PdfGraphics canvas,
  PdfPoint size,
  Scheme scheme,
  double scale,
  PdfFont plain,
  PdfFont bold,
) {
  // The one place the page's upward y axis meets the floor's downward one.
  // Never in the geometry: put it there and the scheme comes out mirrored.
  double x(double mm) => (mm - scheme.bounds.left) * scale;
  double y(double mm) => size.y - (mm - scheme.bounds.top) * scale;

  canvas
    ..setLineWidth(0.4)
    ..setStrokeColor(PdfColors.grey)
    ..drawRect(
      x(scheme.room.left),
      y(scheme.room.bottom),
      scheme.room.width * scale,
      scheme.room.height * scale,
    )
    ..strokePath()
    ..setStrokeColor(PdfColors.black);

  for (final shape in scheme.planks) {
    canvas.moveTo(x(shape.outline.first.dx), y(shape.outline.first.dy));
    for (final point in shape.outline.skip(1)) {
      canvas.lineTo(x(point.dx), y(point.dy));
    }
    canvas
      ..closePath()
      ..strokePath();
  }

  canvas.setFillColor(PdfColors.black);
  for (final label in scheme.labels) {
    final font = label.bold ? bold : plain;
    final metrics = font.stringMetrics(label.text);
    final fontSize = math.min(
      label.box.width * scale / metrics.maxWidth,
      label.box.height * scale / metrics.maxHeight,
    );
    if (!fontSize.isFinite || fontSize <= 0) continue;
    canvas
      ..saveContext()
      // The floor's angles are measured with y downwards, the page's with y up.
      ..setTransform(Matrix4.identity()
        ..translateByDouble(x(label.centre.dx), y(label.centre.dy), 0, 1)
        ..rotateZ(-label.angle))
      ..drawString(
        font,
        fontSize,
        label.text,
        -metrics.maxWidth * fontSize / 2,
        -(metrics.ascent + metrics.descent) * fontSize / 2,
      )
      ..restoreContext();
  }
}
