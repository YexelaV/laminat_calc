# Laminate Calculator

A Flutter app that calculates how much laminate flooring you need for a room and generates an optimal laying scheme.

[Google Play](https://play.google.com/store/apps/details?id=com.floor_calculator.host)

## Features

- Calculates the number of planks and packs required for a room
- Builds several laying layout options, minimizing waste by reusing offcuts
- Respects laying constraints: expansion gap from walls, exact joint offset between rows, minimum plank length
- Plank offset level selection: 1/2, 1/3, 1/4 of the plank length or an exact value
- Laying direction selection: along the room length or width
- Metric and imperial measurement systems (millimeters or feet/inches)
- Visual laying scheme with plank numbering
- Export of the laying scheme to PDF and sharing
- Language selection on first launch (persisted): English, Russian, German, Spanish, French, Italian, Polish, Portuguese, Turkish, Chinese

## How the calculation works

Given the room size, plank dimensions, and laying parameters, the algorithm (`lib/calculate.dart`) lays out the floor row by row:

1. Rows follow an exact staircase pattern: each row's first plank is exactly the configured offset (1/2, 1/3, 1/4 of the plank length or a custom value) shorter than the previous one; when the next step would drop below the minimum plank length, the pattern restarts from the first row's length.
2. The pattern start is chosen so that in every row both the first and the last plank stay at or above the minimum plank length.
3. Offcuts with an intact lock are kept and reused at the start or end of later rows.
4. Several strategies are tried (with/without cutting offcuts, with/without offcut optimization); invalid layouts are filtered out and the remaining options are sorted by total plank count.

## Project structure

```
lib/
  calculate.dart      # Core laying/count algorithm
  models.dart         # Plank, Line, Result models
  cubit/              # BLoC (Cubit) state management
  pages/              # Screens: language selection, parameters input, result, laying scheme
  router/             # auto_route navigation
  di/                 # get_it / injectable dependency injection
  l10n/               # Localization (ru template, plus en, de, es, fr, it, pl, pt, tr, zh)
  utils/, widgets/    # Unit conversion, form validators, shared widgets
test/
  stress_test.dart       # Randomized stress test of algorithm invariants
  row_geometry_test.dart # The geometry the validators derive must match what the algorithm lays out
  l10n_test.dart         # .arb key parity, CLDR plural categories, unit-label collisions
  golden_test.dart       # Rendered result and scheme screens, plural forms, language picker
  goldens/               # Reference images for the golden tests
```

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

# The stress test also runs standalone, without the Flutter test harness
dart test/stress_test.dart
```
