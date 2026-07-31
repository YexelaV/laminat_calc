// The page is only ever proved by saving it: schemePdf builds a widget tree and
// nothing is laid out or encoded until save() runs, so a page that cannot be
// written fails here and nowhere else.
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/scheme_pdf.dart';
import 'package:floor_calculator/utils/cut_list.dart';
import 'package:floor_calculator/utils/units.dart';

Result laid(Direction direction) {
  final results = Calculation(
    roomLength: 3000,
    roomWidth: 1200,
    laminateLength: 1200,
    laminateWidth: 190,
    planksInPack: 8,
    indentFromWall: 10,
    minimumLaminateLength: 300,
    rowOffset: 300,
    direction: direction,
  ).calculate();
  expect(results, isNotEmpty, reason: 'the fixture must be layable');
  return results.first;
}

void main() {
  // rootBundle needs the binding, and the fonts are read once for every test.
  TestWidgetsFlutterBinding.ensureInitialized();
  late PdfFonts fonts;
  setUpAll(() async => fonts = await PdfFonts.load(rootBundle));

  Future<List<String>> report(Result result, MeasurementSystem system, String locale) async =>
      cutList(result, 1, system, await AppLocalizations.delegate.load(Locale(locale)));

  for (final direction in Direction.values) {
    for (final system in MeasurementSystem.values) {
      test('$direction in $system saves', () async {
        final result = laid(direction);
        final pdf = schemePdf(result, system, fonts, cutList: await report(result, system, 'ru'));
        final bytes = await pdf.save();
        // %PDF at the head is the whole of the format's magic number.
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
        expect(bytes.length, greaterThan(1000));
      });
    }
  }

  // A page cannot be panned, so the scheme is fitted to it. Printing a drawing
  // taller than it is wide onto a wide sheet would halve it for nothing, and the
  // 3000x1200 fixture comes out taller than wide as soon as the rows run across
  // the room and the drawing turns with them.
  test('the sheet is turned to match the drawing', () {
    double aspect(Direction direction) {
      final page = schemePdf(laid(direction), MeasurementSystem.metric, fonts)
          .document
          .pdfPageList
          .pages
          .first;
      return page.pageFormat.width / page.pageFormat.height;
    }

    expect(aspect(Direction.length), greaterThan(1));
    expect(aspect(Direction.width), lessThan(1));
  });

  group('the cut list on paper', () {
    test('follows the scheme, and is left out when not asked for', () async {
      final result = laid(Direction.length);
      final without = schemePdf(result, MeasurementSystem.metric, fonts);
      expect(without.document.pdfPageList.pages, hasLength(1));

      final with_ = schemePdf(result, MeasurementSystem.metric, fonts,
          cutList: await report(result, MeasurementSystem.metric, 'ru'));
      await with_.save();
      expect(with_.document.pdfPageList.pages.length, greaterThan(1),
          reason: 'the report has more rows than fit beside the scheme');
    });

    // Roboto covers every alphabet the app is translated into but Chinese. A
    // page of empty boxes is worse than no page: the report is still shared as
    // text from the cut list sheet.
    test('a language the font cannot set is left off the page', () async {
      final result = laid(Direction.length);
      final chinese = schemePdf(result, MeasurementSystem.metric, fonts,
          cutList: await report(result, MeasurementSystem.metric, 'zh'));
      expect(chinese.document.pdfPageList.pages, hasLength(1));
    });

    // The alphabets that do have to print. Nothing past U+00FF reached the page
    // before the font was shipped, so this is the check that it did.
    for (final locale in ['ru', 'pl', 'tr', 'de', 'fr', 'pt', 'es', 'it', 'en']) {
      test('$locale prints', () async {
        final result = laid(Direction.length);
        final pdf = schemePdf(result, MeasurementSystem.metric, fonts,
            cutList: await report(result, MeasurementSystem.metric, locale));
        expect(pdf.document.pdfPageList.pages.length, greaterThan(1));
        expect(String.fromCharCodes((await pdf.save()).take(4)), '%PDF');
      });
    }
  });

  // The scale is fixed from a scheme measured with no text floor, and then the
  // page is built with one. A room whose bounds come out degenerate would make
  // that scale infinite and every font size with it.
  test('a scheme of one plank still saves', () async {
    final result = Result(
      1200,
      1400,
      400,
      8,
      1,
      [
        Line(0, [Plank(1, 1200, 190)])
      ],
      [],
      [],
      direction: Direction.length,
      indentFromWall: 10,
    );
    final bytes = await schemePdf(result, MeasurementSystem.metric, fonts).save();
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
