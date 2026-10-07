// Getting from one screen to the next, and back.
//
// The form is spread over three screens and the way forward is the Next button
// on each. The way back is the arrow in the bar — on every screen that has
// somewhere to go back to, and on no screen that does not: the room is reached
// by replacing the screen that asked for the units, and an arrow there would
// point at nothing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/utils/app_review.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  int backArrows() => find.byType(BackButton).evaluate().length;

  Future<void> next(WidgetTester tester) async {
    // Scrolled to first: the room form is taller than a phone once the shapes
    // are on it, and a tap aimed below the fold lands on nothing.
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, List<String> values) async {
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextField).at(i), values[i]);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('every screen with somewhere to go back to has the arrow',
      (tester) async {
    tester.view.physicalSize = const Size(560, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp(savedLocaleCode: null, savedSystem: null));
    await tester.pumpAndSettle();
    expect(backArrows(), 0, reason: 'the language is the first thing asked');

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(backArrows(), 0, reason: 'the units replace the language, not cover it');

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(backArrows(), 0, reason: 'and the room replaces the units');

    await tester.enterText(find.byType(TextField).at(0), '5000');
    await tester.enterText(find.byType(TextField).at(1), '3000');
    await tester.pumpAndSettle();
    await next(tester);
    expect(find.text('Laminate'), findsOneWidget);
    expect(backArrows(), 1, reason: 'the laminate is pushed on top of the room');

    // And it goes where it says, with the room as it was left.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Room'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text, '5000');
  });

  testWidgets('a floor looked at and come back from is counted', (tester) async {
    // The whole walk, which nothing else in the suite makes: no test has ever
    // pressed Next on the laying screen, so neither the push to the variants
    // nor the way back off a scheme was covered outside the screenshot run.
    //
    // What is being counted is the moment the app has finally done the whole of
    // what it is for — see utils/app_review.dart, which asks for a rating on
    // the second one. Play Services are not here, so the ask itself goes
    // nowhere; the count is the part that has to be right.
    tester.view.physicalSize = const Size(560, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp(savedLocaleCode: 'en', savedSystem: 'metric'));
    await tester.pumpAndSettle();

    await fill(tester, ['5000', '3000']);
    await next(tester);
    await fill(tester, ['1200', '190', '8']);
    await next(tester);
    await fill(tester, ['10', '300']);
    await next(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(find.text('Variant 1'), findsNothing,
        reason: 'the variants are listed by their own label, not this one');
    expect(prefs.getInt(SCHEMES_SEEN_PREF_KEY), isNull,
        reason: 'a list of variants is not a floor anybody has looked at yet');

    // Into the first variant, and straight back out of it.
    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.list_alt), findsOneWidget, reason: 'this is the scheme');
    // The scheme draws its own arrow rather than taking the bar's, because the
    // bar is white and carries three buttons of its own.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect((await SharedPreferences.getInstance()).getInt(SCHEMES_SEEN_PREF_KEY), 1);
  });
}
