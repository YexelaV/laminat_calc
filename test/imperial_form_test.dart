// The imperial form is the only path where what the user enters is not what the
// calculation stores. This drives the room and laminate screens the way a US
// installer would and checks the millimetres that come out the other end.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/pages/laminate_parameters_screen.dart';
import 'package:floor_calculator/pages/room_parameters_screen.dart';
import 'package:floor_calculator/utils/units.dart';

void main() {
  late CalculateCubit cubit;

  // Field order down the room screen: length feet and inches, width feet and
  // inches. Down the laminate screen: plank length, plank width, planks per
  // pack. Each inch field has a fraction picker, in the same order.
  Finder inches(int index) => find.byType(TextField).at(index);
  Finder fraction(int index) => find.byType(DropdownButton<int>).at(index);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(560, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // The system is chosen on its own screen before the form opens, so the
    // form reads it off the cubit it is given and offers no way to change it.
    cubit = CalculateCubit(system: MeasurementSystem.imperial);
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<CalculateCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RoomParametersScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  // The laminate moved to a screen of its own, so its boxes are reached on
  // their own too — with the same cubit, which is what carries the answers
  // from one screen to the next in the running app.
  Future<void> pumpLaminate(WidgetTester tester) async {
    tester.view.physicalSize = const Size(560, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    cubit = CalculateCubit(system: MeasurementSystem.imperial);
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<CalculateCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LaminateParametersScreen(),
      ),
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
    expect(cubit.state.roomLength, inchToMm(148.5));
  });

  testWidgets('a plank is typed in inches and stored in millimetres', (tester) async {
    await pumpLaminate(tester);
    await tester.enterText(inches(0), '47');
    await pick(tester, 0, '7/8');
    expect(cubit.state.laminateLength, inchToMm(47.875));
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
    await pumpLaminate(tester);
    // The shortest plank is 200mm, which is 7 7/8'' once rounded up.
    await tester.enterText(inches(0), '7');
    await pick(tester, 0, '7/8');
    expect(cubit.state.laminateLength, 200);
    // The bound, not the echo above the field, which shows the same number
    // whenever the value is accepted.
    expect(find.textContaining('Minimum 7 7/8'), findsNothing, reason: 'no bound message');

    // One sixteenth under, which is the smallest step the picker offers.
    await pick(tester, 0, '13/16');
    expect(find.textContaining('Minimum 7 7/8'), findsOneWidget, reason: 'below the minimum');
    expect(cubit.state.laminateLength, 200, reason: 'a rejected value is not stored');
  });
}
