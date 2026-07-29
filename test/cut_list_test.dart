// The cut list is the only place where Result.pieces and Result.trash reach the
// user, and the only place that turns the layout into text an installer can
// read at the saw. These tests pin both the arithmetic and the rendered lines.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/pages/result_screen.dart';
import 'package:floor_calculator/utils/cut_list.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/widgets/cut_list_sheet.dart';

// The same room as the scheme goldens: three planks per row, a staircase that
// restarts, and offcuts that get reused.
List<Result> fixtures() => Calculation(
      roomLength: 3000,
      roomWidth: 1200,
      laminateLength: 1200,
      laminateWidth: 190,
      planksInPack: 8,
      indentFromWall: 10,
      minimumLaminateLength: 300,
      rowOffset: 300,
      direction: Direction.length,
    ).calculate();

Result fixture() => fixtures().first;

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

  group('waste', () {
    test('counts whole planks left in the last pack, not just offcuts', () {
      // Two planks bought, one laid whole, nothing cut: still half wasted.
      final result = Result(
        1200,
        3000,
        1200,
        2,
        1,
        [
          Line(0, [Plank(1, 1200, 190)])
        ],
        [],
        [],
        direction: Direction.length,
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
      expect(find.text('Ряд 1: №1 1199 мм, №2 1200 мм, №3 581 мм'), findsOneWidget);
      // Row 3 opens with the offcut of plank 3, so the numbering is not a
      // running count and the list must carry the plank's own number.
      expect(find.text('Ряд 3: №3 599 мм, №7 1200 мм, №8 1181 мм'), findsOneWidget);
      expect(find.text('Ряд 7: №17 1199 мм, №18 1200 мм, №19 581 мм'), findsOneWidget);
      expect(find.text('Остатки: 619 мм × 1, 319 мм × 2, 301 мм × 2'), findsOneWidget);
      expect(find.text('Отходы (28%): 20 мм × 2, 19 мм × 2, 1 мм × 3'), findsOneWidget);
    });

    testWidgets('imperial sizes carry their own marks instead of a unit', (tester) async {
      await pumpSheet(tester, MeasurementSystem.imperial);
      // Sixteenths keep 1199 mm and 1200 mm apart, which tenths of an inch
      // rounded into the same 3'-11.2''.
      expect(find.text("Ряд 1: №1 3'-11 3/16'', №2 3'-11 1/4'', №3 1'-10 7/8''"), findsOneWidget);
      expect(find.text("Остатки: 2'-0 3/8'' × 1, 1'-0 9/16'' × 2, 11 7/8'' × 2"), findsOneWidget);
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
