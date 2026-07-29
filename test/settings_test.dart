// The settings sheet is the only way back to the two answers given during
// onboarding, and the only place where the unit system changes while the form
// already holds typed values.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/utils/units.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<CalculateCubit>(CalculateCubit());
  });
  tearDown(getIt.reset);

  // Both answers already given, so the app opens straight on the form.
  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp(savedLocaleCode: 'en', savedSystem: 'metric'));
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
  }

  testWidgets('switching to feet keeps the room size already typed', (tester) async {
    await pumpForm(tester);
    await tester.enterText(find.byType(TextField).first, '3772');
    await tester.pumpAndSettle();
    expect(getIt.get<CalculateCubit>().state.roomLength, 3772);

    await openSettings(tester);
    await tester.tap(find.text('Imperial (feet and inches)'));
    await tester.pumpAndSettle();
    // Dismissed by tapping the barrier, the way the sheet is meant to close.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // 3772 mm is 148.5'', which is 12'-4 1/2''.
    expect(find.widgetWithText(TextField, '12'), findsOneWidget);
    expect(find.widgetWithText(TextField, '4'), findsOneWidget);
    expect(find.text('1/2'), findsWidgets, reason: 'the fraction comes across too');
    expect(getIt.get<CalculateCubit>().state.roomLength, 3772, reason: 'the state is millimetres');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SYSTEM_PREF_KEY), MeasurementSystem.imperial.name);
  });

  testWidgets('the language changes under the open sheet', (tester) async {
    await pumpForm(tester);
    await openSettings(tester);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(find.text('Einstellungen'), findsOneWidget, reason: 'the sheet is relocalised in place');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LOCALE_PREF_KEY), 'de');
  });
}
