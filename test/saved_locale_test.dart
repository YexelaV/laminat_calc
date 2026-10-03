// What happens on the launch after a language is taken out of the app.
//
// The preference outlives the release. Chinese was dropped in 1.10.0 and every
// phone that had chosen it still has `locale: zh` on disk, so this is the
// upgrade path for real installs rather than a hypothetical — and before
// MyApp.savedLocale existed it was a null check on a null value before the
// first screen finished building.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/pages/room_and_laminate_parameters_screen.dart';
import 'package:floor_calculator/pages/start_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<CalculateCubit>(CalculateCubit());
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester, String? saved) async {
    tester.view.physicalSize = const Size(560, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MyApp(savedLocaleCode: saved, savedSystem: 'metric'));
    await tester.pumpAndSettle();
  }

  test('a code the app still ships resolves, one it has dropped does not', () {
    expect(MyApp.savedLocale('de'), const Locale('de'));
    expect(MyApp.savedLocale(null), isNull);
    expect(MyApp.savedLocale('zh'), isNull, reason: 'dropped in 1.10.0');
    expect(MyApp.savedLocale('hi'), isNull, reason: 'never shipped');
    for (final locale in AppLocalizations.supportedLocales) {
      expect(MyApp.savedLocale(locale.languageCode), locale);
    }
  });

  testWidgets('a saved language that is gone sends the user back to the picker',
      (tester) async {
    await pump(tester, 'zh');
    // Not a crash, and not a silent move to English either: the question is
    // asked again, because the answer on disk is no longer one of the answers.
    expect(find.byType(StartScreen), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('a saved language that is still here goes straight to the form', (tester) async {
    await pump(tester, 'de');
    expect(find.byType(RoomAndLaminateParametersScreen), findsOneWidget);
    expect(find.text('Raumform'), findsOneWidget);
  });
}
