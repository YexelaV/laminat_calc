// Golden tests for the two screens that render a finished calculation.
//
// Regenerate after an intentional visual change:
//   flutter test --update-goldens test/golden_test.dart
//
// The tester draws text in its own test font, where every glyph is an identical
// box. That makes the goldens independent of the host's fonts, but it also means
// they cannot tell one string from another — 'панель' and 'панели' are the same
// six boxes. The variant list is still a widget tree, so its labels are pinned
// here with find.text. The scheme is not: it is one canvas, and its labels are
// pinned in scheme_geometry_test.dart, where they can be read as strings rather
// than counted as boxes. What these images add is that the arithmetic that test
// checks reaches the screen at all.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/pages/result_screen.dart';
import 'package:floor_calculator/pages/scheme_screen.dart';
import 'package:floor_calculator/pages/start_screen.dart';
import 'package:floor_calculator/utils/units.dart';

// A small room that still exercises the interesting paths: the row length is
// not a whole number of planks, the staircase restarts before the last row, and
// the leftover across the rows is narrow enough to be split between the first
// and the last row.
Result schemeResult({Direction direction = Direction.length}) {
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
  expect(results, isNotEmpty, reason: 'the golden fixture must be layable');
  return results.first;
}

// One variant per plural category so a single golden pins all of them.
Result variantWithPlanks(int totalPlanks) => Result(
      1200,
      3000,
      1200,
      8,
      totalPlanks,
      [
        Line(totalPlanks, [Plank(1, 1200, 190)])
      ],
      [],
      [],
      direction: Direction.length,
      indentFromWall: 10,
    );

Widget wrap(Widget child, {Locale locale = const Locale('ru')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

Future<void> pumpAt(WidgetTester tester, Widget widget, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => getIt.registerSingleton<CalculateCubit>(CalculateCubit()));
  tearDown(getIt.reset);

  group('laying scheme', () {
    testWidgets('rows along the room length, millimetres', (tester) async {
      await pumpAt(tester, wrap(SchemeScreen(schemeResult(), 1)), const Size(600, 400));
      await expectLater(
        find.byType(SchemeScreen),
        matchesGoldenFile('goldens/scheme_metric.png'),
      );
    });

    // Rows are always drawn left to right, so laying across the room turns the
    // room: the same 3000x1200 floor comes out 1200 wide and 3000 deep, which is
    // why this one is shot upright.
    testWidgets('rows along the room width are turned with the room', (tester) async {
      await pumpAt(
        tester,
        wrap(SchemeScreen(schemeResult(direction: Direction.width), 1)),
        const Size(400, 600),
      );
      await expectLater(
        find.byType(SchemeScreen),
        matchesGoldenFile('goldens/scheme_along_width.png'),
      );
    });

    testWidgets('rows at 45°', (tester) async {
      await pumpAt(
        tester,
        wrap(SchemeScreen(schemeResult(direction: Direction.diagonal), 1)),
        const Size(600, 500),
      );
      await expectLater(
        find.byType(SchemeScreen),
        matchesGoldenFile('goldens/scheme_diagonal.png'),
      );
    });

    testWidgets('plank sizes are labelled in feet and inches', (tester) async {
      getIt.get<CalculateCubit>().setMeasurementSystem(MeasurementSystem.imperial);
      await pumpAt(tester, wrap(SchemeScreen(schemeResult(), 1)), const Size(600, 400));
      await expectLater(
        find.byType(SchemeScreen),
        matchesGoldenFile('goldens/scheme_imperial.png'),
      );
    });
  });

  // Not a golden: a widget test cannot turn the device, so what is checked is
  // the request the screen makes of the platform.
  group('orientation', () {
    List<MethodCall> watchPlatform(WidgetTester tester) {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      return calls;
    }

    List<String> orientationsIn(List<MethodCall> calls) => calls
        .where((c) => c.method == 'SystemChrome.setPreferredOrientations')
        .expand((c) => (c.arguments as List).cast<String>())
        .toList();

    const every = [
      'DeviceOrientation.portraitUp',
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.portraitDown',
      'DeviceOrientation.landscapeRight',
    ];
    const landscape = [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ];

    testWidgets('opening the scheme leaves the device alone', (tester) async {
      final calls = watchPlatform(tester);
      await pumpAt(tester, wrap(SchemeScreen(schemeResult(), 1)), const Size(600, 400));
      expect(orientationsIn(calls), isEmpty);
    });

    testWidgets('the button turns the phone, and turns it back', (tester) async {
      final calls = watchPlatform(tester);
      await pumpAt(tester, wrap(SchemeScreen(schemeResult(), 1)), const Size(600, 400));

      await tester.tap(find.byIcon(Icons.screen_rotation));
      await tester.pumpAndSettle();
      expect(orientationsIn(calls), landscape);

      // The icon changes with it, so the fitter can see the screen is held.
      await tester.tap(find.byIcon(Icons.screen_lock_rotation));
      await tester.pumpAndSettle();
      expect(orientationsIn(calls), [...landscape, ...every]);
      expect(find.byIcon(Icons.screen_rotation), findsOneWidget);
    });

    testWidgets('leaving the screen gives every orientation back', (tester) async {
      final calls = watchPlatform(tester);
      await pumpAt(tester, wrap(SchemeScreen(schemeResult(), 1)), const Size(600, 400));
      await tester.tap(find.byIcon(Icons.screen_rotation));
      await tester.pumpAndSettle();
      await tester.pumpWidget(wrap(const SizedBox()));
      await tester.pumpAndSettle();
      expect(orientationsIn(calls), [...landscape, ...every]);
    });
  });

  group('variant list', () {
    final variants = [1, 2, 5, 11].map(variantWithPlanks).toList();

    testWidgets('russian plural forms', (tester) async {
      await pumpAt(tester, wrap(ResultScreen(variants)), const Size(500, 600));
      await expectLater(
        find.byType(ResultScreen),
        matchesGoldenFile('goldens/variants_ru.png'),
      );
      expect(find.text('№1 - 1 панель'), findsOneWidget);
      expect(find.text('№2 - 2 панели'), findsOneWidget);
      expect(find.text('№3 - 5 панелей'), findsOneWidget);
      // The suffix rule this replaced read 11 as 'панель'.
      expect(find.text('№4 - 11 панелей'), findsOneWidget);
    });

    // Polish has the same one/few/many split as Russian, so it is the other
    // locale where picking the wrong category is a visible mistake.
    testWidgets('polish plural forms', (tester) async {
      await pumpAt(
        tester,
        wrap(ResultScreen(variants), locale: const Locale('pl')),
        const Size(500, 600),
      );
      expect(find.text('nr 1 - 1 panel'), findsOneWidget);
      expect(find.text('nr 2 - 2 panele'), findsOneWidget);
      expect(find.text('nr 3 - 5 paneli'), findsOneWidget);
      expect(find.text('nr 4 - 11 paneli'), findsOneWidget);
    });

    testWidgets('english plural forms', (tester) async {
      await pumpAt(
        tester,
        wrap(ResultScreen(variants), locale: const Locale('en')),
        const Size(500, 600),
      );
      await expectLater(
        find.byType(ResultScreen),
        matchesGoldenFile('goldens/variants_en.png'),
      );
      expect(find.text('#1 - 1 panel'), findsOneWidget);
      expect(find.text('#2 - 2 panels'), findsOneWidget);
    });
  });

  // No golden here: the picker's content is ten SVG flags, and assets/es.svg is
  // 80 kB of 542 paths that only finishes decoding across a real async
  // boundary, not a pumpAndSettle. A golden would rasterize whichever flags
  // happened to be ready and flake on timing, so pin the structure instead.
  group('language picker', () {
    testWidgets('offers every supported locale', (tester) async {
      await pumpAt(tester, wrap(const StartScreen()), const Size(360, 640));
      // The locale list lives in two places: the .arb files, which generate
      // supportedLocales, and _languages in start_screen.dart. Adding a
      // language to the first and forgetting the second is the easy mistake.
      expect(find.byType(SvgPicture), findsNWidgets(AppLocalizations.supportedLocales.length));
      for (final name in ['Polski', 'Italiano', 'Türkçe']) {
        expect(find.text(name), findsOneWidget);
      }
    });
  });
}
