import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'di/get_it.dart';

const LOCALE_PREF_KEY = 'locale';
const SYSTEM_PREF_KEY = 'system';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  final prefs = await SharedPreferences.getInstance();
  final savedSystem = prefs.getString(SYSTEM_PREF_KEY);
  if (savedSystem != null) {
    getIt.get<CalculateCubit>().setMeasurementSystem(
          MeasurementSystem.values.firstWhere(
            (system) => system.name == savedSystem,
            orElse: () => MeasurementSystem.metric,
          ),
        );
  }
  runApp(MyApp(
    savedLocaleCode: prefs.getString(LOCALE_PREF_KEY),
    savedSystem: savedSystem,
  ));
}

class MyApp extends StatefulWidget {
  final String? savedLocaleCode;
  final String? savedSystem;

  const MyApp({super.key, required this.savedLocaleCode, required this.savedSystem});

  @override
  MyAppState createState() => MyAppState();

  static MyAppState? of(BuildContext context) => context.findAncestorStateOfType<MyAppState>();
}

class MyAppState extends State<MyApp> {
  final _appRouter = AppRouter();
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    if (widget.savedLocaleCode != null) {
      _locale = Locale(widget.savedLocaleCode!);
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Language first, then the measurement system, each asked once and
      // remembered; a launch that has both answers goes straight to the form.
      routerDelegate: _appRouter.delegate(
        initialRoutes: widget.savedLocaleCode == null
            ? null
            : [
                if (widget.savedSystem == null)
                  MeasurementSystemRoute()
                else
                  RoomAndLaminateParametersRoute()
              ],
      ),
      routeInformationParser: _appRouter.defaultRouteParser(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (_locale != null) {
          return _locale;
        }

        final systemLocale = deviceLocale ?? WidgetsBinding.instance.platformDispatcher.locale;
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == systemLocale.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en');
      },
    );
  }
}
