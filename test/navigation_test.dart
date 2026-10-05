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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  int backArrows() => find.byType(BackButton).evaluate().length;

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();
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
}
