// The system is asked once and never again, so the answer has to reach both the
// calculation and the disk on the single tap the user gives it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/utils/units.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<CalculateCubit>(CalculateCubit());
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester) async {
    final router = AppRouter();
    await tester.pumpWidget(MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerDelegate: router.delegate(initialRoutes: [MeasurementSystemRoute()]),
      routeInformationParser: router.defaultRouteParser(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the picked system reaches the calculation and the disk', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Imperial (feet and inches)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(getIt.get<CalculateCubit>().state.system, MeasurementSystem.imperial);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SYSTEM_PREF_KEY), MeasurementSystem.imperial.name);
  });

  testWidgets('millimetres are the answer when nothing is picked', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(getIt.get<CalculateCubit>().state.system, MeasurementSystem.metric);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SYSTEM_PREF_KEY), MeasurementSystem.metric.name);
  });
}
