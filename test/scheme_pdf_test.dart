// The page is only ever proved by saving it: schemePdf builds a widget tree and
// nothing is laid out or encoded until save() runs, so a page that cannot be
// written fails here and nowhere else.
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/scheme_pdf.dart';
import 'package:floor_calculator/utils/cut_list.dart';
import 'package:floor_calculator/utils/units.dart';

Result laid(Direction direction) {
  final results = Calculation(
    shape: RoomShape.rectangle(3000, 1200),
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

// The same room measured wall by wall. On the page the walls are no longer one
// drawRect but a path of four corners, and nothing else in this file draws one.
Result laidSkewed(Direction direction) {
  final results = Calculation(
    shape: RoomShape(
      lengthNear: 3000,
      lengthFar: 2880,
      widthLeft: 1200,
      widthRight: 1320,
      diagonal: 3300,
    ),
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

Result laidCutCorner(Direction direction) {
  final results = Calculation(
    shape: LRoomShape(
      length: 4000,
      width: 3000,
      notchLength: 1500,
      notchWidth: 1000,
      corner: RoomCorner.farRight,
    ),
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

  test('every language the app ships can be set in the PDF font', () async {
    // A character with no glyph is not an error: [schemePdf] leaves the whole
    // cut list off the document rather than print a page of empty boxes. So a
    // dash or a sign that Roboto happens not to carry would cost the user the
    // list in silence, and this is the only place that would notice.
    final result = laid(Direction.length);
    for (final locale in AppLocalizations.supportedLocales) {
      for (final system in MeasurementSystem.values) {
        final lines = await report(result, system, locale.languageCode);
        final unprintable = lines.where((line) => !fonts.canPrint(line));
        expect(unprintable, isEmpty,
            reason: '${locale.languageCode} in $system: $unprintable');
      }
    }
  });

  for (final direction in [Direction.length, Direction.diagonal]) {
    test('$direction in a room measured wall by wall saves', () async {
      final result = laidSkewed(direction);
      final pdf = schemePdf(result, MeasurementSystem.metric, fonts,
          cutList: await report(result, MeasurementSystem.metric, 'ru'));
      final bytes = await pdf.save();
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(bytes.length, greaterThan(1000));
    });
  }

  // Six walls instead of four, planks with six corners instead of four, and a
  // line in the report that no other room has. The page draws whatever list of
  // corners it is handed, so this is a check that it really is handed one.
  for (final direction in [Direction.length, Direction.width]) {
    test('$direction in a room with a corner cut away saves', () async {
      final result = laidCutCorner(direction);
      final report_ = await report(result, MeasurementSystem.metric, 'ru');
      expect(report_.where((line) => line.startsWith('Ряд') && line.contains('выреза')).length, 1,
          reason: 'the row across the cut is called out');
      final pdf = schemePdf(result, MeasurementSystem.metric, fonts, cutList: report_);
      final bytes = await pdf.save();
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(bytes.length, greaterThan(1000));
    });
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

    // Roboto covers Latin and Cyrillic, which between them is every alphabet
    // the app currently ships in — so nothing in lib/l10n can exercise this
    // and the text is written out here instead. The guard is what stands
    // between a twelfth language in a third alphabet and a page of empty
    // boxes, and it has to keep working while no locale needs it.
    test('a line the font cannot set leaves the report off the page', () async {
      const unsettable = 'पंक्ति 1: 980 मिमी';
      expect(fonts.canPrint(unsettable), isFalse);
      final result = laid(Direction.length);
      final pdf = schemePdf(result, MeasurementSystem.metric, fonts,
          cutList: ['Cut list', unsettable]);
      expect(pdf.document.pdfPageList.pages, hasLength(1));
    });

    test('every alphabet that does ship can be set', () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final lines = await report(laid(Direction.length), MeasurementSystem.metric,
            locale.languageCode);
        for (final line in lines) {
          expect(fonts.canPrint(line), isTrue,
              reason: '${locale.languageCode}: the font cannot set "$line"');
        }
      }
    });

    // The alphabets that do have to print. Nothing past U+00FF reached the page
    // before the font was shipped, so this is the check that it did.
    for (final locale in ['ru', 'bg', 'pl', 'tr', 'de', 'fr', 'pt', 'es', 'it', 'sv', 'en']) {
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
      RoomShape.rectangle(1400, 400),
      8,
      1,
      [
        Line(0, [Plank(1, 1200, 190)])
      ],
      [],
      [],
      laminateWidth: 190,
      direction: Direction.length,
      indentFromWall: 10,
    );
    final bytes = await schemePdf(result, MeasurementSystem.metric, fonts).save();
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
