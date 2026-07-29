// The imperial form is the only path where what the user enters is not what the
// calculation stores. This drives the room screen the way a US installer would
// and checks the millimetres that come out the other end.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/pages/room_and_laminate_parameters_screen.dart';
import 'package:floor_calculator/utils/units.dart';

void main() {
  setUp(() => getIt.registerSingleton<CalculateCubit>(CalculateCubit()));
  tearDown(getIt.reset);

  CalculateCubit cubit() => getIt.get<CalculateCubit>();

  // Field order down the imperial form: room length feet and inches, room
  // width feet and inches, plank length, plank width, planks per pack. Each
  // inch field has a fraction picker, in the same order.
  Finder inches(int index) => find.byType(TextField).at(index);
  Finder fraction(int index) => find.byType(DropdownButton<int>).at(index);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(560, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // The system is chosen on its own screen before the form opens, so the form
    // reads it from the cubit and offers no way to change it.
    cubit().setMeasurementSystem(MeasurementSystem.imperial);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RoomAndLaminateParametersScreen(),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, int index, String label) async {
    await tester.tap(fraction(index));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('feet, inches and a fraction reach the state as millimetres', (tester) async {
    await pump(tester);
    await tester.enterText(inches(0), '12');
    await tester.enterText(inches(1), '4');
    await pick(tester, 0, '1/2');
    // 12'-4 1/2'' is 148.5 inches.
    expect(cubit().state.roomLength, inchToMm(148.5));

    await tester.enterText(inches(4), '47');
    await pick(tester, 2, '7/8');
    expect(cubit().state.laminateLength, inchToMm(47.875));
  });

  testWidgets('the entered size is echoed back as feet and inches', (tester) async {
    await pump(tester);
    await tester.enterText(inches(0), '12');
    await tester.enterText(inches(1), '4');
    await pick(tester, 0, '1/2');
    await tester.pumpAndSettle();
    expect(find.text("= 12'-4 1/2''"), findsOneWidget);
  });

  testWidgets('a fraction inside the bounds is accepted, one outside is not', (tester) async {
    await pump(tester);
    // The shortest plank is 300mm, which is 11 13/16'' once rounded up.
    await tester.enterText(inches(4), '11');
    await pick(tester, 2, '13/16');
    expect(cubit().state.laminateLength, 300);
    // The bound, not the echo above the field, which shows the same number
    // whenever the value is accepted.
    expect(find.textContaining('Minimum 11 13/16'), findsNothing, reason: 'no bound message');

    await pick(tester, 2, '3/4');
    expect(find.textContaining('Minimum 11 13/16'), findsOneWidget, reason: 'below the minimum');
    expect(cubit().state.laminateLength, 300, reason: 'a rejected value is not stored');
  });
}
