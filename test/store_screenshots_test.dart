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
import 'package:floor_calculator/room_kind.dart';

// A 414x736 logical phone at 3x. Play wants 16:9 or 9:16 exactly.
const _size = Size(1242, 2208);
const _pixelRatio = 3.0;

// The locales to shoot. Play keeps a separate set of screenshots per store
// listing language, so this is the list of listings being refreshed.
const _locales = ['ru', 'en', 'de', 'es', 'fr', 'it', 'pl', 'pt', 'tr', 'cs', 'sv', 'bg'];

/// The order Play shows them in, which is not the order the app is walked in.
///
/// Play puts the first two or three in the search results themselves, and that
/// is where the install is decided — so they are the room the app is for and
/// the answer it gives, and what has to be typed to get there comes after. The
/// language and the unit screens are gone from the listing altogether: both are
/// settings, both are answered once and never again, and between them they were
/// the whole of what a browsing user used to see.
const _shots = ['room', 'scheme', 'cut_list', 'laminate'];

// Registered as 'Roboto', which is the family every unstyled Text in the app
// resolves to. One face has to cover every alphabet shipped at once: the
// tester's font manager does not fall back to another font for a missing
// glyph, not even to one registered in the same family, so a tile it cannot
// set comes out as empty boxes. Arial Unicode covers them all and goes on
// doing so when a new alphabet arrives, which is worth more here than matching
// Android's own face exactly.
const _uiFont = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';

/// The band above each shot, and the words in it.
///
/// A listing is read by someone scrolling a gallery, and what they read is the
/// captions — the screens underneath are only evidence. Five bare screens left
/// the reader to work out for themselves what the app was giving them.
///
/// The band takes a tenth of the picture, so the screen below it loses that
/// much and the forms scroll a little sooner. No shot loses anything it was
/// showing: what goes under the fold is the Next button, which the gallery is
/// not there to demonstrate.
const _bandHeight = 72.0;
const _bandColour = Colors.blue;
const _captionSize = 19.0;

/// The captions of one listing, in [_shots] order, out of `store/<locale>/`.
///
/// Listing copy rather than app strings, so it lives beside listing.txt and not
/// in the arb files — nothing here is ever shown inside the app.
///
/// A locale with none falls back to English and says so. That is for the middle
/// of a translation round, when the words have been settled in one language and
/// not yet in the rest; shipping in that state would put English captions over
/// twelve listings, so the warning is loud and the test prints it once per run.
List<String> _captions(String locale) {
  final own = File('store/$locale/captions.txt');
  final file = own.existsSync() ? own : File('store/en/captions.txt');
  if (!own.existsSync()) {
    printOnFailure('store/$locale/captions.txt is missing; using English');
    stderr.writeln('!! store/$locale/captions.txt is missing — shot in English');
  }
  final lines = file.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
  if (lines.length != _shots.length) {
    throw StateError('${file.path} has ${lines.length} captions, ${_shots.length} wanted');
  }
  return lines;
}

/// The band, and the running app under it.
///
/// The app is pumped once and walked through screen by screen, so the caption
/// cannot be a constructor argument — changing it would rebuild the app and
/// lose the walk. It arrives through a notifier that only the band listens to.
class _Captioned extends StatelessWidget {
  final ValueNotifier<String> caption;
  final Widget child;

  const _Captioned({required this.caption, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: _bandColour,
        child: Column(
          children: [
            SizedBox(
              height: _bandHeight,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ValueListenableBuilder<String>(
                    valueListenable: caption,
                    builder: (context, text, _) => Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      // The family the tester has a real face for; left to
                      // itself the caption comes out as empty boxes in every
                      // alphabet the test shoots.
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontSize: _captionSize,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

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

      final captions = _captions(locale);
      final caption = ValueNotifier<String>('');
      addTearDown(caption.dispose);

      Future<void> capture(String name) async {
        // Nothing is being typed in a listing picture. The last box filled
        // still holds the cursor, and with it a caret, a drag handle and —
        // since the sketch picks out the measurement under the cursor — one
        // number in a colour the rest are not.
        FocusManager.instance.primaryFocus?.unfocus();
        final shot = _shots.indexOf(name);
        caption.value = captions[shot];
        await tester.pumpAndSettle();
        final index = (shot + 1).toString().padLeft(2, '0');
        await expectLater(
          find.byType(_Captioned),
          matchesGoldenFile('../store/$locale/${index}_$name.png'),
        );
      }

      // Nothing answered yet, so the app opens on the language screen.
      await tester.pumpWidget(_Captioned(
        caption: caption,
        child: const MyApp(savedLocaleCode: null, savedSystem: null),
      ));
      await tester.pumpAndSettle();
      // The ten flags are SVGs that only finish decoding across a real async
      // boundary; a pumpAndSettle alone leaves half of them blank.
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      // The scheme is fitted to the screen, so the room's proportions decide
      // how much of shot 02 it fills. Rows run along the 3 m side and stack up
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

      // The room is Г-shaped, which is what the listing leads on. It costs the
      // first shot nothing — the form still reads as "type your room", there
      // are only two more boxes and a sketch — and it buys the scheme behind it
      // a floor worth looking at.
      // Overall length and width first: the cut's own bounds are worked out
      // from them, so they have to be there before the shape changes.
      await fill(['3000', '6000']);
      await tester.tap(find.byKey(const ValueKey(RoomKind.lShaped)));
      await tester.pumpAndSettle();

      // Length and width of the cut. The corner is the one the form starts on,
      // which is the far one — the cut lands at the bottom of the sketch and of
      // the scheme, clear of both captions.
      await fill(['3000', '6000', '1200', '2000']);
      await tester.pumpAndSettle();
      await capture('room');

      await tapNext();

      // The plank off the carton and the laying under it, which are one screen
      // now. A plain picture, and late in the listing for it — but it is the
      // whole of what a user types after the room, and a listing that skips it
      // reads as though the room were the whole of the input.
      await fill(['1200', '190', '8', '10', '300']);
      await tester.pumpAndSettle();
      await capture('laminate');
      await tapNext();

      // The review is walked through rather than shot: it says back what the
      // two shots before it already showed being typed.

      // The variant list is walked through for the same reason: it is a list
      // of numbers that mean nothing until the scheme behind them is seen.
      await tester.ensureVisible(find.text(
          AppStrings.of(tester.element(find.byType(Scaffold))).calculate));
      await tester.pumpAndSettle();
      await tester.tap(find.text(
          AppStrings.of(tester.element(find.byType(Scaffold))).calculate));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
      await capture('scheme');

      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();
      await capture('cut_list');
    });
  }
}
