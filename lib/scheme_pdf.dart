// The same scheme on a page. Nothing here decides where anything goes — that is
// scheme_geometry.dart — so the sheet a fitter carries and the screen he checks
// it against cannot disagree.
import 'dart:math' as math;

// Matrix4 comes from vector_math, which both Flutter and the pdf package build
// on; taking it from Flutter keeps it out of pubspec.yaml.
import 'package:flutter/widgets.dart' show AssetBundle, Matrix4, Offset;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'models.dart';
import 'scheme_geometry.dart';
import 'utils/cut_list.dart';
import 'utils/units.dart';

// A printed page cannot be zoomed. Text smaller than this is not worth the ink,
// and the ladder in buildScheme drops it.
const double _minTextPt = 3.5;

// The size of [schemePdf]'s credit line. Bigger than a footnote — it is read
// at arm's length off a phone screen or a printed sheet, not proofread.
const double _creditPt = 9;

/// Where a PDF a user saves and hands on points back to. A scheme on paper or
/// a screen the app never opened on is the one copy of it that reaches
/// someone else, and this is the line that brings it back — the only thing
/// that changes if the listing ever moves.
const PLAY_STORE_URL =
    'https://play.google.com/store/apps/details?id=com.floor_calculator.host';

/// The face the page is set in, in plain and bold.
///
/// The pdf package cannot reach the app's fonts, and its built-in Type 1 ones
/// carry no glyph past U+00FF and throw rather than substitute — which is why
/// Roboto is shipped as an asset. It covers Latin and Cyrillic, which between
/// them is every alphabet the app ships in.
///
/// [PdfFonts.canPrint] is the guard for the day one arrives that it does not.
/// Rather than set a page of empty boxes, the cut list is left off and the
/// user still reads it on screen and shares it as text, where the device's own
/// fonts set it. A language in a third alphabet means shipping a face for it —
/// Noto under the Open Font Licence, about 200 KB a weight — and teaching this
/// class to pick a face per string.
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
String _plainMark(int number) => '$number';

pw.Document schemePdf(
  Result result,
  MeasurementSystem system,
  PdfFonts fonts, {
  List<CutLine> cutList = const [],
  String Function(int)? rowMark,
  // What made this: just the sentence, already localised, the same way
  // [cutList] arrives already built — this file draws a report, it does not
  // write one. The link itself is added here, set apart in blue so it reads
  // as one, and printed at the foot of every page: PDF pages are the one copy
  // of a scheme that leaves the app in someone else's hands.
  String? credit,
}) {
  // Built before it is tested, so the guard is run over the characters that
  // actually reach the page — the dash between the two halves included.
  final said = credit == null ? null : '$credit — ';
  final showCredit = said != null && fonts.canPrint(said + PLAY_STORE_URL);
  pw.Widget footer(pw.Context context) => pw.UrlLink(
        destination: PLAY_STORE_URL,
        child: pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(
              text: said,
              style: pw.TextStyle(font: fonts.plain, fontSize: _creditPt, color: PdfColors.grey700),
            ),
            pw.TextSpan(
              text: PLAY_STORE_URL,
              style: pw.TextStyle(font: fonts.plain, fontSize: _creditPt, color: PdfColors.blue),
            ),
          ]),
        ),
      );

  // The bounds barely move with the text floor, so measure with no floor, fix
  // the scale, then build the scheme the page actually gets.
  final measured = buildScheme(result,
      system: system, minTextMm: 0, rowMark: rowMark ?? _plainMark);
  final format = measured.bounds.width >= measured.bounds.height
      ? PdfPageFormat.a4.landscape
      : PdfPageFormat.a4.portrait;
  final scale = math.min(
    format.availableWidth / measured.bounds.width,
    format.availableHeight / measured.bounds.height,
  );
  final scheme = buildScheme(result,
      system: system,
      minTextMm: _minTextPt / scale,
      rowMark: rowMark ?? _plainMark);

  final pdf = pw.Document();
  pdf.addPage(pw.Page(
    pageFormat: format,
    build: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Expanded rather than sized to the drawing, so the credit line below
        // it lands on the page's own bottom edge and not wherever the scheme
        // happens to end — the two are turned to match each other's aspect,
        // not each other's height.
        pw.Expanded(
          child: pw.Align(
            alignment: pw.Alignment.topLeft,
            child: pw.CustomPaint(
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
          ),
        ),
        if (showCredit) footer(context),
      ],
    ),
  ));

  // A line the font cannot print would come out as a row of empty boxes, so the
  // report is left off the page whole rather than in part — it is still shared
  // as text from the cut list sheet.
  if (cutList.isNotEmpty && cutList.every((line) => fonts.canPrint(line.text))) {
    final plain = pw.TextStyle(font: fonts.plain, fontSize: 10);
    final bold = pw.TextStyle(font: fonts.bold, fontSize: 10);
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      footer: showCredit ? footer : null,
      build: (context) => [
        pw.Text(cutList.first.text, style: pw.TextStyle(font: fonts.bold, fontSize: 14)),
        pw.SizedBox(height: 12),
        for (final line in cutList.skip(1))
          if (line.isEmpty)
            pw.SizedBox(height: 10)
          else
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              // The sizes in bold, as on screen. Two fonts rather than one
              // emboldened, because a PDF has no synthetic weight: the bold
              // face is a second embedded font and the text has to ask for it.
              child: pw.RichText(
                text: pw.TextSpan(children: [
                  for (final span in line.spans)
                    pw.TextSpan(text: span.text, style: span.bold ? bold : plain),
                ]),
              ),
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

  void outline(List<Offset> corners) {
    canvas.moveTo(x(corners.first.dx), y(corners.first.dy));
    for (final point in corners.skip(1)) {
      canvas.lineTo(x(point.dx), y(point.dy));
    }
    canvas
      ..closePath()
      ..strokePath();
  }

  canvas
    ..setLineWidth(0.4)
    ..setStrokeColor(PdfColors.grey);
  // The walls are drawn corner to corner like everything else: a room whose
  // opposite walls differ is not a rectangle.
  outline(scheme.room);
  canvas.setStrokeColor(PdfColors.black);

  for (final shape in scheme.planks) {
    outline(shape.outline);
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
