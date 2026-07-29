import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/utils/languages.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two answers given on the onboarding screens, offered again once the user
/// is in the form. Both are applied and written to disk as they are picked, so
/// the sheet has nothing to confirm and can simply be dismissed.
///
/// [onSystemChanged] lets the form rewrite its fields: they hold text in the
/// old unit, and the state behind them holds millimetres.
class SettingsSheet extends StatefulWidget {
  final void Function(MeasurementSystem) onSystemChanged;

  const SettingsSheet({super.key, required this.onSystemChanged});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  Future<void> _pickLanguage(String code) async {
    MyApp.of(context)?.setLocale(Locale(code));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LOCALE_PREF_KEY, code);
  }

  Future<void> _pickSystem(MeasurementSystem system) async {
    widget.onSystemChanged(system);
    setState(() {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SYSTEM_PREF_KEY, system.name);
  }

  Widget sectionTitle(String text) => Align(
        alignment: Alignment.centerLeft,
        child:
            Text(text, style: TextStyle(fontSize: 16, color: Colors.black.withValues(alpha: 0.8))),
      );

  Widget systemOption(MeasurementSystem system, String label) {
    final selected = system == getIt.get<CalculateCubit>().state.system;
    return GestureDetector(
      onTap: () => _pickSystem(system),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.blue : Colors.black26,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
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
            Expanded(child: Text(label, style: TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings.of(context);
    final current = Localizations.localeOf(context).languageCode;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(appStrings.settings,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ),
              SizedBox(height: 20),
              sectionTitle(appStrings.language),
              SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final lang in appLanguages)
                    GestureDetector(
                      onTap: () => _pickLanguage(lang.code),
                      child: Container(
                        width: 76,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: lang.code == current ? Colors.blue : Colors.black26,
                            width: lang.code == current ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: lang.code == current
                              ? Color.alphaBlend(Colors.blue.withValues(alpha: 0.12), Colors.white)
                              : Colors.white,
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SvgPicture.asset(lang.flagAsset, width: 40, height: 30),
                            ),
                            SizedBox(height: 6),
                            Text(
                              lang.name,
                              style: TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 24),
              sectionTitle(appStrings.choose_units),
              SizedBox(height: 12),
              systemOption(MeasurementSystem.metric, appStrings.metric_system),
              SizedBox(height: 12),
              systemOption(MeasurementSystem.imperial, appStrings.imperial_system),
            ],
          ),
        ),
      ),
    );
  }
}
