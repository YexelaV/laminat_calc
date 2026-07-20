# Laminate Calculator

A Flutter app that calculates how much laminate flooring you need for a room and generates an optimal laying scheme.

[Google Play](https://play.google.com/store/apps/details?id=com.floor_calculator.host)

## Features

- Calculates the number of planks and packs required for a room
- Builds several laying layout options, minimizing waste by reusing offcuts
- Respects laying constraints: expansion gap from walls, minimum joint offset between rows, minimum plank length
- Visual laying scheme with plank numbering
- Export of the laying scheme to PDF and sharing
- Localization: English and Russian

## How the calculation works

Given the room size, plank dimensions, and laying parameters, the algorithm (`lib/calculate.dart`) lays out the floor row by row:

1. The first plank of each row is cut so that it is not shorter than the minimum plank length, the joint offset relative to the previous row is at least the configured value, and the last plank of the row also stays above the minimum.
2. Offcuts with an intact lock are kept and reused at the start or end of later rows.
3. Several strategies are tried (with/without cutting offcuts, with/without offcut optimization); invalid layouts are filtered out and the remaining options are sorted by total plank count.

## Project structure

```
lib/
  calculate.dart      # Core laying/count algorithm
  models.dart         # Plank, Line, Result models
  cubit/              # BLoC (Cubit) state management
  pages/              # Screens: parameters input, result, laying scheme
  router/             # auto_route navigation
  di/                 # get_it / injectable dependency injection
  l10n/               # Localization (en, ru)
  utils/, widgets/    # Form validators, shared widgets
test/
  stress_test.dart    # Randomized stress test of algorithm invariants
```

## Tech stack

Flutter, flutter_bloc, auto_route, get_it + injectable, pdf, share_plus, intl.

## Development

```bash
flutter pub get
flutter run

# Regenerate code (routes, DI, localization)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the algorithm stress test
dart test/stress_test.dart
```
