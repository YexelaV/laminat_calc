import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asked once, right after the language, and remembered: a US installer never
/// switches to millimetres and the form has no room for a control nobody
/// touches twice.
class MeasurementSystemScreen extends StatefulWidget {
  const MeasurementSystemScreen({super.key});

  @override
  State<MeasurementSystemScreen> createState() => _MeasurementSystemScreenState();
}

class _MeasurementSystemScreenState extends State<MeasurementSystemScreen> {
  MeasurementSystem _selected = MeasurementSystem.metric;

  Widget option(MeasurementSystem system, String label) {
    final selected = system == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = system),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.blue : Colors.black26,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          // Opaque: a translucent tint would pick up the orange behind it and
          // read as brown.
          color: selected
              ? Color.alphaBlend(Colors.blue.withValues(alpha: 0.12), Colors.white)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? Colors.blue : Colors.black45,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 18))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings.of(context);
    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(appStrings.title, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                appStrings.choose_units,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20).copyWith(color: Colors.blue),
              ),
              SizedBox(height: 20),
              option(MeasurementSystem.metric, appStrings.metric_system),
              SizedBox(height: 12),
              option(MeasurementSystem.imperial, appStrings.imperial_system),
              SizedBox(height: 30),
              TextButton(
                onPressed: () async {
                  final router = context.router;
                  getIt.get<CalculateCubit>().setMeasurementSystem(_selected);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(SYSTEM_PREF_KEY, _selected.name);
                  if (!mounted) return;
                  router.replace(RoomAndLaminateParametersRoute());
                },
                child: Container(
                  alignment: Alignment.center,
                  width: 140,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.blue,
                  ),
                  child: Text(
                    appStrings.next,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
