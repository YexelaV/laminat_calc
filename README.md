# Laminate Calculator

A Flutter app that calculates how much laminate flooring you need for a room and generates an optimal laying scheme.

[Google Play](https://play.google.com/store/apps/details?id=com.floor_calculator.host)

## Features

- Calculates the number of planks and packs required for a room
- Builds several laying layout options, minimizing waste by reusing offcuts
- Respects laying constraints: expansion gap from walls, exact joint offset between rows, minimum plank length
- Plank offset level selection: 1/2, 1/3, 1/4 of the plank length or an exact value
- Laying direction selection: along the room length, along its width, or at 45°
- Metric and imperial measurement systems (millimeters, or feet and inches down to 1/16")
- Visual laying scheme with plank numbering, drawn large enough to read and panned rather than shrunk onto the screen; rows always run left to right, so laying across the room turns the room instead; a button holds the phone in landscape while the scheme is read
- Text cut list: every row plank by plank, reusable leftovers, waste and its share of the material bought
- Export to PDF: the scheme on a sheet turned to match it, then the cut list; the cut list also shares as plain text
- Language and measurement system are asked once at first launch, persisted, and changed later from the gear on the form; switching the system rewrites the values already typed
- Ten languages: English, Russian, German, Spanish, French, Italian, Polish, Portuguese, Turkish, Chinese
- Runs entirely on the device: the manifest declares no permissions, and there is no network, ad or analytics dependency

## How the calculation works

Given the room size, plank dimensions, and laying parameters, the algorithm (`lib/calculate.dart`) lays out the floor row by row:

1. Rows follow an exact staircase pattern: each row's first plank is exactly the configured offset (1/2, 1/3, 1/4 of the plank length or a custom value) shorter than the previous one; when the next step would drop below the minimum plank length, the pattern restarts from the first row's length.
2. The pattern start is chosen so that in every row both the first and the last plank stay at or above the minimum plank length.
3. Offcuts with an intact lock are kept and reused at the start or end of later rows.
4. Several strategies are tried (with/without cutting offcuts, with/without offcut optimization); invalid layouts are filtered out and the remaining options are sorted by total plank count.

Laying at 45° changes only the shape of the rows (`lib/row_plan.dart`): they grow, hold and shrink across the diagonal of the room instead of all being one length, they start a plank width apart in a staircase that turns once at a corner, and every row ends in a wedge, which costs half a plank width of reach and cannot be reused as a square end. The strip left against the far corner is dropped when it comes to less than 50 mm, being narrower than a plank a fitter can cut and click into place.

## Project structure

```
lib/
  calculate.dart      # Core laying/count algorithm
  row_plan.dart       # The shape of the rows: the only file straight and 45° laying differ in
  models.dart         # Plank, Line, Result models
  scheme_geometry.dart # Result to polygons and label anchors in millimetres of room
  scheme_pdf.dart     # The same geometry on an A4 page, and the cut list after it
  cubit/              # BLoC (Cubit) state management
  pages/              # Screens: language selection, unit system, parameters input, result, laying scheme
  router/             # auto_route navigation
  di/                 # get_it / injectable dependency injection
  l10n/               # Localization (ru template, plus en, de, es, fr, it, pl, pt, tr, zh)
  utils/, widgets/    # Unit conversion, form validators, shared widgets
test/
  stress_test.dart       # Randomized stress test of algorithm invariants
  diagonal_stress_test.dart # The same, for 45° laying: row lengths, bevels, material balance
  row_geometry_test.dart # The geometry the validators derive must match what the algorithm lays out
  row_plan_test.dart     # Row lengths and starts at 45°, against a numeric oracle
  scheme_geometry_test.dart # The drawn planks cover the floor, stay inside the walls and are labelled
  scheme_pdf_test.dart   # The pages save, the sheet turns with the drawing, and every alphabet prints
  l10n_test.dart         # .arb key parity, CLDR plural categories, unit-label collisions
  cut_list_test.dart     # Grouping and waste arithmetic, plus the lines the cut list renders
  units_test.dart        # Inch fractions: formatting, parsing and the round trip through millimetres
  inch_field_test.dart   # The whole-inch field and its fraction picker stay one value
  imperial_form_test.dart # What the imperial form accepts, and the millimetres it stores
  measurement_system_test.dart # The system picked at launch reaches the calculation and the disk
  settings_test.dart     # The gear sheet: relocalising in place, and switching units under typed values
  golden_test.dart       # Rendered result and scheme screens, plural forms, language picker
  goldens/               # Reference images for the golden tests
  store_screenshots_test.dart # Walks the app to shoot the Play listing images
assets/
  *.svg               # Flags for the language picker
  fonts/              # Roboto, for the PDF only: the pdf package cannot reach the app's fonts
store/                # Play listing assets: feature graphic and screenshots per locale, listing text
```

The PDF is set in Roboto (Apache 2.0, `assets/fonts/LICENSE.txt`), which covers every language the
app is translated into except Chinese. The cut list is left off the page when the font cannot set it,
rather than printed as empty boxes; it still shares as text.

## Tech stack

Flutter, flutter_bloc, auto_route, get_it + injectable, pdf, share_plus, shared_preferences, flutter_svg, intl.

## Development

```bash
flutter pub get
flutter run

# Regenerate code (routes, DI)
flutter pub run build_runner build --delete-conflicting-outputs

# Regenerate localizations (settings come from l10n.yaml, so pass no arguments)
flutter gen-l10n

# Run every test
flutter test

# Update the reference images after an intentional visual change
flutter test --update-goldens test/golden_test.dart

# Reshoot the Play listing screenshots into store/<locale>/ (1242x2208, 9:16)
flutter test --update-goldens test/store_screenshots_test.dart

# The stress test also runs standalone, without the Flutter test harness
dart test/stress_test.dart
```
