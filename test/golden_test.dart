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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/cubit/settings_cubit.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_shape.dart';
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
    shape: RoomShape.rectangle(3000, 1200),
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

// The same room measured wall by wall, so that no two opposite walls are
// parallel and no row is the same length as its neighbour. Skewed hard enough
// to see in a small picture — a real tape measure is off by a centimetre, not
// twelve — because what these images are for is showing that the drawing
// follows the outline at all.
Result skewedResult({Direction direction = Direction.length}) {
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
  expect(results, isNotEmpty, reason: 'the golden fixture must be layable');
  return results.first;
}

// The same room with a corner taken out of it: a riser boxed into the far
// right corner, a third of the length by a third of the width. Big enough to
// see in a small picture, and deep enough that rows run above it, below it and
// across the step between.
Result cutCornerResult({Direction direction = Direction.length}) {
  final results = Calculation(
    shape: LRoomShape(
      length: 3000,
      width: 1200,
      notchLength: 1000,
      notchWidth: 400,
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
  expect(results, isNotEmpty, reason: 'the golden fixture must be layable');
  return results.first;
}

// A room with a corner out of each end of it, diagonally across from each
// other: a hall cut out of the near left and a cupboard out of the far right.
//
// Its own golden because it is the first room with *two* inside corners, and
// the drawing takes an inside corner away as a quarter-plane rather than
// clipping against one wall at a time. One such corner was all `clipToFloor`
// had ever been handed; two of them in one room is where a plank comes back as
// something other than a plank or an L if the subtraction is wrong, and no
// amount of area arithmetic says what that looks like.
Result zRoomResult() {
  final results = Calculation(
    shape: CutCornersRoomShape(
      length: 3000,
      width: 1200,
      cut: CornerCut.notch,
      cuts: const {
        RoomCorner.nearLeft: CornerSize(along: 700, across: 400),
        RoomCorner.farRight: CornerSize(along: 1000, across: 400),
      },
    ),
    laminateLength: 1200,
    laminateWidth: 190,
    planksInPack: 8,
    indentFromWall: 10,
    minimumLaminateLength: 300,
    rowOffset: 300,
    direction: Direction.length,
  ).calculate();
  expect(results, isNotEmpty, reason: 'the golden fixture must be layable');
  return results.first;
}

// One variant per plural category so a single golden pins all of them.
Result variantWithPlanks(int totalPlanks) => Result(
      1200,
      RoomShape.rectangle(3000, 1200),
      8,
      totalPlanks,
      [
        Line(totalPlanks, [Plank(1, 1200, 190)])
      ],
      [],
      [],
      laminateWidth: 190,
      direction: Direction.length,
      indentFromWall: 10,
    );

/// The screen under its own settings. A fresh cubit per image, so a golden
/// cannot be changed by whatever the image before it typed.
///
/// Settings and nothing else: both screens here are handed a finished [Result]
/// and read only the units the sizes on it are written in.
Widget wrap(
  Widget child, {
  Locale locale = const Locale('ru'),
  MeasurementSystem system = MeasurementSystem.metric,
}) =>
    BlocProvider<SettingsCubit>(
      create: (_) => SettingsCubit(system: system),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

Future<void> pumpAt(WidgetTester tester, Widget widget, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

void main() {
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

    // A room whose walls differ takes the general path end to end: the rows are
    // walked rather than derived, their ends are cut on the slant the walls
    // lean at, and the walls themselves are drawn corner to corner. Nothing in
    // the four images above can go wrong without one of these going wrong too,
    // but they are the only ones where the outline is not a rectangle.
    testWidgets('rows in a room measured wall by wall', (tester) async {
      await pumpAt(tester, wrap(SchemeScreen(skewedResult(), 1)), const Size(600, 400));
      await expectLater(
        find.byType(SchemeScreen),
        matchesGoldenFile('goldens/scheme_skewed.png'),
      );
    });

    testWidgets('rows at 45° in a room measured wall by wall', (tester) async {
      await pumpAt(
        tester,
        wrap(SchemeScreen(skewedResult(direction: Direction.diagonal), 1)),
        const Size(600, 500),
      );
      await expectLater(
        find.byType(SchemeScreen),
        matchesGoldenFile('goldens/scheme_skewed_diagonal.png'),
      );
    });

    // A room with a corner cut away is the only one whose outline is not
    // convex, and the only one where a plank comes back from the clip with six
    // sides rather than four. These two are where that shows.
    testWidgets('rows in a room with a corner cut away', (tester) async {
      await pumpAt(tester, wrap(SchemeScreen(cutCornerResult(), 1)), const Size(600, 400));
      await expectLater(
        find.byType(SchemeScreen),
        matchesGoldenFile('goldens/scheme_cut_corner.png'),
      );
    });

    testWidgets('rows across a room with a corner cut away', (tester) async {
      await pumpAt(
        tester,
        wrap(SchemeScreen(cutCornerResult(direction: Direction.width), 1)),
        const Size(600, 500),
      );
      await expectLater(
        find.byType(SchemeScreen),
        matchesGoldenFile('goldens/scheme_cut_corner_width.png'),
      );
    });

    testWidgets('rows in a room cut at two corners across from each other',
        (tester) async {
      await pumpAt(tester, wrap(SchemeScreen(zRoomResult(), 1)), const Size(600, 400));
      await expectLater(
        find.byType(SchemeScreen),
        matchesGoldenFile('goldens/scheme_z_room.png'),
      );
    });

    testWidgets('plank sizes are labelled in feet and inches', (tester) async {
      await pumpAt(
        tester,
        wrap(SchemeScreen(schemeResult(), 1), system: MeasurementSystem.imperial),
        const Size(600, 400),
      );
      await expectLater(
        find.byType(SchemeScreen),
        matchesGoldenFile('goldens/scheme_imperial.png'),
      );
    });

    // Feet and inches is where the short walls of a cut-away corner stop
    // fitting their own measurements: "1'-3 3/4''" is eleven characters on a
    // wall 400 mm long, and without the fit-to-the-wall rule it is written
    // across its neighbours.
    testWidgets('a cut-away corner labelled in feet and inches', (tester) async {
      await pumpAt(
        tester,
        wrap(SchemeScreen(cutCornerResult(), 1), system: MeasurementSystem.imperial),
        const Size(600, 400),
      );
      await expectLater(
        find.byType(SchemeScreen),
        matchesGoldenFile('goldens/scheme_cut_corner_imperial.png'),
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
      for (final name in ['Polski', 'Italiano', 'Türkçe', 'Čeština', 'Svenska', 'Български']) {
        expect(find.text(name), findsOneWidget);
      }
    });
  });
}
