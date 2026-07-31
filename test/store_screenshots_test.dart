// Generates the Google Play listing screenshots by walking the real app, one
// locale at a time:
//
//   flutter test --update-goldens test/store_screenshots_test.dart
//
// The output lands in store/<locale>/ at 1242x2208, which is exactly 9:16 and
// inside Play's 320..3840 px per side. Without --update-goldens the test
// compares instead of writing, so a screen that has visibly changed since the
// last listing update shows up as a failure.
//
// Real fonts are loaded from the Flutter cache first: the tester's own font
// draws every glyph as an identical box, which is fine for the geometry
// goldens in golden_test.dart and useless for a store listing.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/main.dart';

// A 414x736 logical phone at 3x. Play wants 16:9 or 9:16 exactly.
const _size = Size(1242, 2208);
const _pixelRatio = 3.0;

// The locales to shoot. Play keeps a separate set of screenshots per store
// listing language, so this is the list of listings being refreshed.
const _locales = ['ru', 'en', 'de', 'es', 'fr', 'it', 'pl', 'pt', 'tr', 'zh'];

// Registered as 'Roboto', which is the family every unstyled Text in the app
// resolves to. The real Roboto would be the faithful choice, but it has no CJK
// and the '中文' tile on the language screen then renders as two empty boxes:
// the tester's font manager does not fall back to another font for a missing
// glyph, not even to one registered in the same family. One font that covers
// all ten languages beats a font that matches Android and drops glyphs.
const _uiFont = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT is unset; run through `flutter test`');

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(File(file).readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  }

  await load('Roboto', [_uiFont]);
  await load('MaterialIcons', ['$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
}

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<CalculateCubit>(CalculateCubit());
  });
  tearDown(getIt.reset);

  for (final locale in _locales) {
    testWidgets('screenshots for $locale', (tester) async {
      tester.view.physicalSize = _size;
      tester.view.devicePixelRatio = _pixelRatio;
      tester.platformDispatcher.localesTestValue = [Locale(locale)];
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      var shot = 0;
      Future<void> capture(String name) async {
        shot++;
        final index = shot.toString().padLeft(2, '0');
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../store/$locale/${index}_$name.png'),
        );
      }

      // Nothing answered yet, so the app opens on the language screen.
      await tester.pumpWidget(const MyApp(savedLocaleCode: null, savedSystem: null));
      await tester.pumpAndSettle();
      // The ten flags are SVGs that only finish decoding across a real async
      // boundary; a pumpAndSettle alone leaves half of them blank.
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      await tester.pumpAndSettle();
      await capture('language');

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      await capture('units');

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      // The scheme is fitted to the screen, so the room's proportions decide
      // how much of shot 07 it fills. Rows run along the 3 m side and stack up
      // the 6 m one, which is the only way it comes out portrait.
      Future<void> fill(List<String> values) async {
        final fields = find.byType(TextField);
        for (var i = 0; i < values.length; i++) {
          await tester.enterText(fields.at(i), values[i]);
          await tester.pumpAndSettle();
        }
      }

      // The 'next' button carries no key, and by the laying screen the page holds
      // several TextButtons, so it is found by its label — read out of the running
      // app rather than listed here, so a new locale costs nothing.
      Finder next() => find.text(AppStrings.of(tester.element(find.byType(Scaffold))).next);

      // Room length, room width, plank length, plank width, planks per pack.
      await fill(['3000', '6000', '1200', '190', '8']);
      await tester.pumpAndSettle();
      await capture('room');

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      await tester.pumpAndSettle();
      await capture('settings');
      // Dismissed by tapping the barrier, the way the sheet is meant to close.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(next());
      await tester.pumpAndSettle();

      // Expansion gap, then the shortest offcut worth laying.
      await fill(['10', '300']);
      await tester.pumpAndSettle();
      await capture('laying');

      await tester.tap(next());
      await tester.pumpAndSettle();
      await capture('variants');

      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
      await capture('scheme');

      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();
      await capture('cut_list');
    });
  }
}
