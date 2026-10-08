import 'package:floor_calculator/cubit/laminate_cubit.dart';
import 'package:floor_calculator/cubit/laying_cubit.dart';
import 'package:floor_calculator/cubit/room_cubit.dart';
import 'package:floor_calculator/cubit/settings_cubit.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const LOCALE_PREF_KEY = 'locale';
const SYSTEM_PREF_KEY = 'system';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(
    savedLocaleCode: prefs.getString(LOCALE_PREF_KEY),
    savedSystem: prefs.getString(SYSTEM_PREF_KEY),
  ));
}

class MyApp extends StatefulWidget {
  final String? savedLocaleCode;
  final String? savedSystem;

  const MyApp({super.key, required this.savedLocaleCode, required this.savedSystem});

  @override
  MyAppState createState() => MyAppState();

  /// The saved language, or null when the app no longer offers it.
  ///
  /// A language can leave the app between releases and the preference outlives
  /// it — Chinese went in 1.10.0 and every phone that had chosen it still has
  /// `locale: zh` on disk. Handing that to [MaterialApp] gives a locale no
  /// delegate loads, `AppLocalizations.of` then returns null, and the first
  /// `AppStrings.of(context)` is a null check on nothing: the app does not get
  /// past its first screen.
  ///
  /// So a language that is gone counts as never answered. The user meets the
  /// picker again on the next launch and chooses from what there is, which is
  /// one tap and the truth, rather than being moved silently to English.
  static Locale? savedLocale(String? code) {
    if (code == null) return null;
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == code) return locale;
    }
    return null;
  }

  /// The saved measurement system, or metric when nothing was answered.
  ///
  /// Unlike a language, a system cannot disappear between releases — there are
  /// two of them and neither is going anywhere — so an unreadable value falls
  /// back rather than counting as unanswered. Which screen the app opens on is
  /// still decided by whether anything was written at all.
  static MeasurementSystem savedMeasurementSystem(String? name) =>
      MeasurementSystem.values.firstWhere(
        (system) => system.name == name,
        orElse: () => MeasurementSystem.metric,
      );
}

class MyAppState extends State<MyApp> {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    // Above the router, so every screen it shows is inside them — and so are the
    // sheets, which open into that router's own overlay.
    //
    // One cubit per part of the form rather than one for the whole of it, so
    // that a screen can only reach what it collects. They are all up here
    // together even so, and not owned by their screens: the screens are pushed
    // on top of each other, a step back destroys the route along with its
    // [State] and the text controllers in it, and the boxes are filled again
    // from the cubit when the screen comes round a second time. Cubits that
    // lived and died with their screens would turn every step back into a form
    // to retype.
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(
            system: MyApp.savedMeasurementSystem(widget.savedSystem),
            locale: MyApp.savedLocale(widget.savedLocaleCode),
          ),
        ),
        BlocProvider<RoomCubit>(create: (_) => RoomCubit()),
        BlocProvider<LaminateCubit>(create: (_) => LaminateCubit()),
        BlocProvider<LayingCubit>(create: (_) => LayingCubit()),
      ],
      // The language is the one setting the whole app is rebuilt for, so the
      // builder sits here and not inside a screen.
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (was, now) => was.locale != now.locale,
        builder: (context, settings) => _router(settings.locale),
      ),
    );
  }

  Widget _router(Locale? locale) {
    return MaterialApp.router(
      // No bar tints itself when the form scrolls under it.
      //
      // Material 3 lifts an app bar the moment content passes beneath it and
      // paints a surface tint over it to say so. Every bar in this app is
      // transparent on purpose — the orange gradient behind the form is meant
      // to run the whole height of the screen — and the tint put a grey band
      // across the top of it with a seam where the bar ended. `elevation: 0`
      // does not cover it: that is the *resting* elevation, and the one that
      // did this is `scrolledUnderElevation`.
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      // Language first, then the measurement system, each asked once and
      // remembered; a launch that has both answers goes straight to the form.
      routerDelegate: _appRouter.delegate(
        initialRoutes: MyApp.savedLocale(widget.savedLocaleCode) == null
            ? null
            : [
                if (widget.savedSystem == null)
                  MeasurementSystemRoute()
                else
                  RoomParametersRoute()
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
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (locale != null) {
          return locale;
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
