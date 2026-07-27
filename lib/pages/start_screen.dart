import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Language {
  final String code;
  final String flagAsset;
  final String name;
  const _Language(this.code, this.flagAsset, this.name);
}

const _languages = [
  _Language('ru', 'assets/ru.svg', 'Русский'),
  _Language('en', 'assets/gb.svg', 'English'),
  _Language('de', 'assets/de.svg', 'Deutsch'),
  _Language('es', 'assets/es.svg', 'Español'),
  _Language('fr', 'assets/fr.svg', 'Français'),
  _Language('pt', 'assets/pt.svg', 'Português'),
  _Language('zh', 'assets/cn.svg', '中文'),
];

class StartScreen extends StatefulWidget {
  StartScreen({Key? key}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String? _detectedCode;
  String? _selectedCode;

  @override
  Widget build(BuildContext context) {
    _detectedCode ??= Localizations.localeOf(context).languageCode;
    final selected = _selectedCode ?? _detectedCode;

    final ordered = [..._languages];
    final detectedIndex = ordered.indexWhere((lang) => lang.code == _detectedCode);
    if (detectedIndex > 0) {
      ordered.insert(0, ordered.removeAt(detectedIndex));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(AppStrings.of(context).title, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final lang in ordered)
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedCode = lang.code);
                        MyApp.of(context)?.setLocale(Locale(lang.code));
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: lang.code == selected ? Colors.blue : Colors.black26,
                            width: lang.code == selected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                          color: lang.code == selected
                              ? Colors.blue.withOpacity(0.15)
                              : Colors.black12,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SvgPicture.asset(lang.flagAsset, width: 48, height: 36),
                            ),
                            SizedBox(height: 8),
                            Text(lang.name, style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 30),
              TextButton(
                child: Container(
                  alignment: Alignment.center,
                  width: 140,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.blue,
                  ),
                  child: Text(
                    AppStrings.of(context).next,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                onPressed: () async {
                  final code = _selectedCode ?? _detectedCode;
                  if (code != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(LOCALE_PREF_KEY, code);
                  }
                  if (!mounted) return;
                  context.router.replace(RoomAndLaminateParametersRoute());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
