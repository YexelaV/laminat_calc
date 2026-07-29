// The fraction picker exists because the number keypad has no '/'. That splits
// one value across two controls, and everything else in the form — the
// validators, the Next button, the unit switch — still reads a single string
// off a single controller. These tests pin that seam.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/widgets/inch_field.dart';

void main() {
  late TextEditingController controller;
  late List<String> accepted;

  setUp(() {
    controller = TextEditingController();
    accepted = [];
  });

  Future<void> pump(WidgetTester tester) async {
    // Tall enough for all sixteen marks at once: the open menu is a lazy list,
    // and an item scrolled out of view is not in the tree to be tapped.
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InchField(
          controller: controller,
          focusNode: FocusNode(),
          labelText: 'in',
          validator: (value) => parseInches(value) == null ? 'bad' : null,
          callback: accepted.add,
        ),
      ),
    ));
  }

  Future<void> pickFraction(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('joins the typed inches and the picked fraction', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), '47');
    await tester.pump();
    expect(controller.text, '47');
    expect(accepted, ['47']);

    await pickFraction(tester, '7/8');
    expect(controller.text, '47 7/8');
    expect(accepted.last, '47 7/8');
    expect(parseInches(controller.text), 47.875);
  });

  testWidgets('a fraction alone is a valid value', (tester) async {
    await pump(tester);
    await pickFraction(tester, '1/2');
    expect(controller.text, '1/2');
    expect(accepted.last, '1/2');
  });

  testWidgets('picking back to zero drops the fraction', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), '7');
    await pickFraction(tester, '3/16');
    expect(controller.text, '7 3/16');
    await pickFraction(tester, '0');
    expect(controller.text, '7');
  });

  testWidgets('every keystroke reaches the shared controller, valid or not', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();
    // The Next button is enabled by re-validating this text, so it has to
    // mirror what the user sees even while it is wrong.
    expect(controller.text, 'x');
    expect(accepted, isEmpty);
  });

  testWidgets('a value written from outside is split back into the two controls', (tester) async {
    await pump(tester);
    // This is what switching from millimetres to inches does.
    controller.text = formatInches(316 / MM_PER_INCH);
    await tester.pumpAndSettle();
    expect(controller.text, '12 7/16');
    expect(find.widgetWithText(TextField, '12'), findsOneWidget);
    expect(find.text('7/16'), findsOneWidget, reason: 'the picker follows the controller');
    expect(accepted, isEmpty, reason: 'a programmatic rewrite is not user input');
  });

  testWidgets('clearing from outside empties both controls', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), '9');
    await pickFraction(tester, '5/8');
    controller.clear();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '9'), findsNothing);
    expect(find.text('0'), findsOneWidget);
  });
}
