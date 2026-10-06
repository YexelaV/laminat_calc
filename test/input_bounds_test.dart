// The edges of what the form accepts, driven through the real screens.
//
// The bounds in constants.dart are two kinds of number mixed together: the ones
// the engine or the geometry needs, and the ones that were a guess at what a
// floor looks like. The guesses were refusing laminate that is sold — a
// herringbone block 200 mm long, a strip 50 mm across, a pack of 36 tiles — so
// they came down. This is what keeps them down: the stress suite proves the
// engine lays such a floor, and this proves the form lets one be typed.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> fill(WidgetTester tester, List<String> values) async {
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextField).at(i), values[i]);
      await tester.pumpAndSettle();
    }
  }

  bool nextEnabled(WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Next')).onPressed != null;

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();
  }

  testWidgets('a tile-sized plank, a pack of 36 and the new floors go through',
      (tester) async {
    tester.view.physicalSize = const Size(560, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp(savedLocaleCode: 'en', savedSystem: 'metric'));
    await tester.pumpAndSettle();
    final cubit = cubitIn(tester);

    await fill(tester, ['4000', '3000']);
    await next(tester);

    // Every one of these three was refused before: the plank floors were
    // 300 × 90 and a pack held at most 20.
    await fill(tester, ['$MIN_PLANK_LENGTH', '$MIN_PLANK_WIDTH', '36']);
    expect(find.textContaining('Minimum'), findsNothing);
    expect(find.textContaining('Maximum'), findsNothing);
    expect(nextEnabled(tester), isTrue);
    expect(cubit.state.laminateLength, MIN_PLANK_LENGTH);
    expect(cubit.state.laminateWidth, MIN_PLANK_WIDTH);
    expect(cubit.state.quantityPerPack, 36);
    await next(tester);

    // The expansion gap, then the shortest offcut worth laying at its floor.
    await fill(tester, ['10', '$MIN_MIN_LENGTH']);
    expect(find.textContaining('Minimum'), findsNothing);
    expect(nextEnabled(tester), isTrue);

    // And the exact offset at its floor, which is the one the 1/4 button has
    // been handing the engine all along without asking this field's leave.
    await tester.tap(find.text('exact'));
    await tester.pumpAndSettle();
    await fill(tester, ['10', '$MIN_ROW_OFFSET', '$MIN_MIN_LENGTH']);
    expect(find.textContaining('Minimum'), findsNothing);
    expect(nextEnabled(tester), isTrue);
    expect(cubit.state.rowOffset, MIN_ROW_OFFSET);
    expect(cubit.state.minimumLaminateLength, MIN_MIN_LENGTH);
  });

  testWidgets('a quarter of the shortest plank is still a legal offset',
      (tester) async {
    // The fraction buttons work the offset out from the plank and hand it over
    // without a range check, so the floor under the typed offset has to be at
    // or below what they can produce — otherwise the form is stricter than the
    // button beside it.
    expect(MIN_PLANK_LENGTH ~/ 4, greaterThanOrEqualTo(MIN_ROW_OFFSET));
    // And half the shortest plank, which is the ceiling the offset field shows,
    // has to leave a range to type in at all.
    expect(MIN_PLANK_LENGTH ~/ 2, greaterThan(MIN_ROW_OFFSET));
  });
}

/// The one cubit the app runs on, fetched out of the tree the provider in
/// `main.dart` put it in.
CalculateCubit cubitIn(WidgetTester tester) =>
    BlocProvider.of<CalculateCubit>(tester.element(find.byType(MaterialApp)));
