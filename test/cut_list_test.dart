// The cut list is the only place where Result.pieces and Result.trash reach the
// user, and the only place that turns the layout into text an installer can
// read at the saw. These tests pin both the arithmetic and the rendered lines.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/pages/result_screen.dart';
import 'package:floor_calculator/utils/cut_list.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/widgets/cut_list_sheet.dart';

// The same room as the scheme goldens: three planks per row, a staircase that
// restarts, and offcuts that get reused.
List<Result> fixtures() => Calculation(
      shape: RoomShape.rectangle(3000, 1200),
      laminateLength: 1200,
      laminateWidth: 190,
      planksInPack: 8,
      indentFromWall: 10,
      minimumLaminateLength: 300,
      rowOffset: 300,
      direction: Direction.length,
    ).calculate();

Result fixture() => fixtures().first;

/// The strings the sheet renders, without a widget tree to render them in.
final ru = lookupAppLocalizations(const Locale('ru'));

Future<void> pumpRu(WidgetTester tester, Widget child, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ));
  await tester.pumpAndSettle();
}

Future<void> pumpSheet(WidgetTester tester, MeasurementSystem system) =>
    pumpRu(tester, CutListSheet(fixture(), 1, system), const Size(500, 900));

void main() {
  group('grouping', () {
    test('lengths come out longest first, with a count each', () {
      final grouped = groupByLength([
        Plank(1, 301, 190),
        Plank(2, 619, 190),
        Plank(3, 301, 190),
      ]);
      expect(grouped.keys.toList(), [619, 301]);
      expect(grouped[301], 2);
    });

    test('nothing to group is an empty map, not a zero entry', () {
      expect(groupByLength([]), isEmpty);
    });
  });

  group('runs', () {
    test('planks of one size off consecutive boards become one run', () {
      final runs = runsOf([
        Plank(1, 1270, 270),
        Plank(2, 1270, 270),
        Plank(3, 1270, 270),
      ]);
      expect(runs.length, 1);
      expect(runs.first.map((p) => p.number), [1, 2, 3]);
    });

    test('a different size breaks the run', () {
      final runs = runsOf([
        Plank(1, 1270, 270),
        Plank(2, 1270, 270),
        Plank(3, 621, 270),
      ]);
      expect(runs.map((r) => r.length), [2, 1]);
    });

    test('a gap in the numbers breaks it too', () {
      // Which is a row that opens with the offcut of a board laid earlier: the
      // piece keeps its own number, and a range over it would point at boards
      // that are not in this row.
      final runs = runsOf([
        Plank(3, 1270, 270),
        Plank(21, 1270, 270),
        Plank(22, 1270, 270),
      ]);
      expect(runs.map((r) => r.first.number), [3, 21]);
      expect(runs.last.length, 2);
    });

    test('nothing to run over is no runs', () {
      expect(runsOf([]), isEmpty);
    });
  });

  group('waste', () {
    test('counts whole planks left in the last pack, not just offcuts', () {
      // Two planks bought, one laid whole, nothing cut: still half wasted.
      final result = Result(
        1200,
        RoomShape.rectangle(3000, 1200),
        2,
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
      expect(totalPacks(result), 1);
      expect(wastePercent(result), 50);
    });

    test('a row narrowed across its width still consumes full plank lengths', () {
      final result = fixture();
      // 7 rows of 2980 mm laid out of 3 packs of 8 planks 1200 mm long.
      expect(totalPacks(result), 3);
      expect(wastePercent(result), 28);
    });
  });

  group('sheet', () {
    testWidgets('reports packs, every row, leftovers and waste', (tester) async {
      await pumpSheet(tester, MeasurementSystem.metric);
      expect(find.text('Схема укладки №1'), findsOneWidget);
      expect(find.text('Понадобится упаковок: 3'), findsOneWidget);
      expect(find.text('19 панелей'), findsOneWidget);
      // The first and last rows are ripped to 115 mm, which the head of the row
      // says once — and which is why nothing in them is whole, full length or
      // not.
      expect(find.text('Ряд 1 (×115 мм): №1 1199, №2 1200, №3 581'), findsOneWidget);
      // Row 3 opens with the offcut of plank 3, so the numbering is not a
      // running count and the list must carry the plank's own number.
      expect(find.text('Ряд 3 (×190 мм): №3 599, №7 1200 (целые), №8 1181'), findsOneWidget);
      expect(find.text('Ряд 7 (×115 мм): №17 1199, №18 1200, №19 581'), findsOneWidget);
      expect(find.text('Остатки: 619 мм × 1, 319 мм × 2, 301 мм × 2'), findsOneWidget);
      expect(find.text('Отходы (28%): 20 мм × 2, 19 мм × 2, 1 мм × 3'), findsOneWidget);
    });

    testWidgets('imperial sizes carry their own marks instead of a unit', (tester) async {
      await pumpSheet(tester, MeasurementSystem.imperial);
      // Sixteenths keep 1199 mm and 1200 mm apart, which tenths of an inch
      // rounded into the same 3'-11.2''.
      expect(find.text("Ряд 1 (×4 1/2''): №1 3'-11 3/16'', №2 3'-11 1/4'', №3 1'-10 7/8''"),
          findsOneWidget);
      expect(find.text("Остатки: 2'-0 3/8'' × 1, 1'-0 9/16'' × 2, 11 7/8'' × 2"), findsOneWidget);
    });

    test('a long row says the whole planks once, with the numbers it spans', () {
      // Twelve metres of room: eight boards go down untouched between the two
      // that are cut, and the old list wrote the same line eight times.
      final result = Calculation(
        shape: RoomShape.rectangle(12000, 2000),
        laminateLength: 1270,
        laminateWidth: 270,
        planksInPack: 8,
        indentFromWall: 10,
        minimumLaminateLength: 300,
        rowOffset: 300,
        direction: Direction.length,
      ).calculate().first;
      final lines = cutList(result, 1, MeasurementSystem.metric, ru);
      expect(lines, contains('Ряд 1 (×270 мм): №1 1199, №2–№9 1270 (целые), №10 621'));
      // The last row is ripped to 90 mm. Its planks are still full length and
      // still consecutive, so they are still one run — but nothing about them
      // is whole any more, and the marker goes.
      expect(lines, contains('Ряд 8 (×90 мм): №69 899, №70–№77 1270, №78 921'));
    });

    test('the row that crosses a cut-away corner says so', () {
      // The one plank the list cannot describe with a length. Everywhere else
      // a number in this list is a straight cut; here it is the long side of
      // a notch, and the list has to send the fitter to the drawing for the
      // rest of it.
      final result = Calculation(
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
        direction: Direction.length,
      ).calculate().first;
      expect(result.steppedRows.length, 1, reason: 'one cut, one row across it');
      final lines = cutList(result, 1, MeasurementSystem.metric, ru);
      expect(
          lines.where((l) => l.startsWith('Ряд ${result.steppedRows.first + 1} идёт через')).length,
          1);

      // And a room with no cut says nothing of the kind.
      expect(fixture().steppedRows, isEmpty);
      expect(cutList(fixture(), 1, MeasurementSystem.metric, ru).where((l) => l.contains('вырез')),
          isEmpty);
    });
  });

  testWidgets('the variant list shows waste once and leftovers per variant', (tester) async {
    await pumpRu(tester, ResultScreen(fixtures()), const Size(500, 900));
    expect(fixtures().map(wastePercent).toSet(), {28},
        reason: 'the same packs cover the same floor, so waste cannot differ by variant');
    expect(find.text('Отходы: 28%'), findsOneWidget);
    expect(find.text('Остатки: 5 шт'), findsOneWidget);
    expect(find.text('Остатки: 9 шт'), findsOneWidget);
    expect(find.text('Остатки: 11 шт'), findsOneWidget);
  });
}
