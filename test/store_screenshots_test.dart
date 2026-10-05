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

import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/main.dart';

// A 414x736 logical phone at 3x. Play wants 16:9 or 9:16 exactly.
const _size = Size(1242, 2208);
const _pixelRatio = 3.0;

// The locales to shoot. Play keeps a separate set of screenshots per store
// listing language, so this is the list of listings being refreshed.
const _locales = ['ru', 'en', 'de', 'es', 'fr', 'it', 'pl', 'pt', 'tr', 'cs', 'sv', 'bg'];

// Registered as 'Roboto', which is the family every unstyled Text in the app
// resolves to. One face has to cover every alphabet shipped at once: the
// tester's font manager does not fall back to another font for a missing
// glyph, not even to one registered in the same family, so a tile it cannot
// set comes out as empty boxes. Arial Unicode covers them all and goes on
// doing so when a new alphabet arrives, which is worth more here than matching
// Android's own face exactly.
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

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final locale in _locales) {
    testWidgets('screenshots for $locale', (tester) async {
      tester.view.physicalSize = _size;
      tester.view.devicePixelRatio = _pixelRatio;
      tester.platformDispatcher.localesTestValue = [Locale(locale)];
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      var shot = 0;
      Future<void> capture(String name) async {
        // Nothing is being typed in a listing picture. The last box filled
        // still holds the cursor, and with it a caret, a drag handle and —
        // since the sketch picks out the measurement under the cursor — one
        // number in a colour the rest are not.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
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

      // Scrolled to before it is pressed. The room form is taller than the
      // phone once the shapes are on it, and a tap aimed below the fold lands
      // on nothing — silently, leaving the next screen's answers to be typed
      // into this one's boxes.
      Future<void> tapNext() async {
        await tester.ensureVisible(next());
        await tester.pumpAndSettle();
        await tester.tap(next());
        await tester.pumpAndSettle();
      }

      // The room is Г-shaped, which is what the listing leads on and what no
      // shot used to show. It costs nothing to show it here: Play takes eight
      // phone screenshots and there are eight, so a ninth is not an option and
      // the room shot is the one that can carry it. The form still reads as
      // "type your room" — there are two more boxes and a sketch — and the
      // scheme in shot 07 comes out more worth looking at for it.
      // Overall length and width first: the cut's own bounds are worked out
      // from them, so they have to be there before the shape changes.
      await fill(['3000', '6000']);
      await tester.tap(find.byKey(const ValueKey('shape-lShaped')));
      await tester.pumpAndSettle();

      // Length and width of the cut. The corner is the one the form starts on,
      // which is the far one — the cut lands at the bottom of the sketch and of
      // the scheme, clear of both captions.
      await fill(['3000', '6000', '1200', '2000']);
      await tester.pumpAndSettle();
      await capture('room');

      await tapNext();

      // The laminate: plank, plank, pack, copied off the side of the carton.
      // Three boxes make a plain picture, but it is the second of the three
      // things a user has to type, and a listing that skips it reads as though
      // the room were the whole of the input. Play takes eight phone
      // screenshots and there are eight; this one has the settings sheet's
      // place, which was showing a list of languages the listing already names
      // and a unit switch shot 02 already asks about.
      await fill(['1200', '190', '8']);
      await capture('laminate');
      await tapNext();

      // Expansion gap, then the shortest offcut worth laying.
      await fill(['10', '300']);
      await tester.pumpAndSettle();
      await capture('laying');

      await tapNext();
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
