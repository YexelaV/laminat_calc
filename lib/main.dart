import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'di/get_it.dart';

const LOCALE_PREF_KEY = 'locale';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(savedLocaleCode: prefs.getString(LOCALE_PREF_KEY)));
}

class MyApp extends StatefulWidget {
  final String? savedLocaleCode;

  MyApp({Key? key, this.savedLocaleCode}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
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
      routerDelegate: _appRouter.delegate(
        initialRoutes: widget.savedLocaleCode == null
            ? null
            : [RoomAndLaminateParametersRoute()],
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
      supportedLocales: const [
        Locale('ru', ''),
        Locale('en', ''),
        Locale('de', ''),
        Locale('es', ''),
        Locale('fr', ''),
        Locale('pt', ''),
        Locale('zh', ''),
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (_locale != null) {
          return _locale;
        }
        
        final systemLocale =
            deviceLocale ?? WidgetsBinding.instance.platformDispatcher.locale;
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
