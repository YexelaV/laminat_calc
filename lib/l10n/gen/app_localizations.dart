import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh')
  ];

  /// No description provided for @title.
  ///
  /// In ru, this message translates to:
  /// **'Калькулятор Ламината'**
  String get title;

  /// No description provided for @mm.
  ///
  /// In ru, this message translates to:
  /// **'мм'**
  String get mm;

  /// No description provided for @pcs.
  ///
  /// In ru, this message translates to:
  /// **'шт'**
  String get pcs;

  /// No description provided for @ft.
  ///
  /// In ru, this message translates to:
  /// **'фут'**
  String get ft;

  /// No description provided for @inch.
  ///
  /// In ru, this message translates to:
  /// **'дюйм'**
  String get inch;

  /// No description provided for @units.
  ///
  /// In ru, this message translates to:
  /// **'Система измерений'**
  String get units;

  /// No description provided for @metric_units.
  ///
  /// In ru, this message translates to:
  /// **'мм'**
  String get metric_units;

  /// No description provided for @imperial_units.
  ///
  /// In ru, this message translates to:
  /// **'фут / дюйм'**
  String get imperial_units;

  /// No description provided for @room.
  ///
  /// In ru, this message translates to:
  /// **'Помещение'**
  String get room;

  /// No description provided for @length.
  ///
  /// In ru, this message translates to:
  /// **'Длина'**
  String get length;

  /// No description provided for @width.
  ///
  /// In ru, this message translates to:
  /// **'Ширина'**
  String get width;

  /// No description provided for @length_in.
  ///
  /// In ru, this message translates to:
  /// **'Длина (дюйм)'**
  String get length_in;

  /// No description provided for @width_in.
  ///
  /// In ru, this message translates to:
  /// **'Ширина (дюйм)'**
  String get width_in;

  /// No description provided for @laminate.
  ///
  /// In ru, this message translates to:
  /// **'Ламинат'**
  String get laminate;

  /// No description provided for @length_mm.
  ///
  /// In ru, this message translates to:
  /// **'Длина (мм)'**
  String get length_mm;

  /// No description provided for @width_mm.
  ///
  /// In ru, this message translates to:
  /// **'Ширина (мм)'**
  String get width_mm;

  /// No description provided for @pieces_per_package.
  ///
  /// In ru, this message translates to:
  /// **'В упаковке (штук)'**
  String get pieces_per_package;

  /// No description provided for @laying.
  ///
  /// In ru, this message translates to:
  /// **'Укладка'**
  String get laying;

  /// No description provided for @laying_direction.
  ///
  /// In ru, this message translates to:
  /// **'Направление укладки'**
  String get laying_direction;

  /// No description provided for @along_length.
  ///
  /// In ru, this message translates to:
  /// **'По длине'**
  String get along_length;

  /// No description provided for @along_width.
  ///
  /// In ru, this message translates to:
  /// **'По ширине'**
  String get along_width;

  /// No description provided for @expansion_gap_mm.
  ///
  /// In ru, this message translates to:
  /// **'Отступ от стен (мм)'**
  String get expansion_gap_mm;

  /// No description provided for @joint_offset.
  ///
  /// In ru, this message translates to:
  /// **'Смещение стыков'**
  String get joint_offset;

  /// No description provided for @exact_offset.
  ///
  /// In ru, this message translates to:
  /// **'точно'**
  String get exact_offset;

  /// No description provided for @joint_offset_mm.
  ///
  /// In ru, this message translates to:
  /// **'Смещение рядов (мм)'**
  String get joint_offset_mm;

  /// No description provided for @minimal_piece_length.
  ///
  /// In ru, this message translates to:
  /// **'Минимальная длина панели (мм)'**
  String get minimal_piece_length;

  /// No description provided for @expansion_gap_in.
  ///
  /// In ru, this message translates to:
  /// **'Отступ от стен (дюйм)'**
  String get expansion_gap_in;

  /// No description provided for @joint_offset_in.
  ///
  /// In ru, this message translates to:
  /// **'Смещение рядов (дюйм)'**
  String get joint_offset_in;

  /// No description provided for @minimal_piece_length_in.
  ///
  /// In ru, this message translates to:
  /// **'Минимальная длина панели (дюйм)'**
  String get minimal_piece_length_in;

  /// No description provided for @required_field.
  ///
  /// In ru, this message translates to:
  /// **'Обязательное поле'**
  String get required_field;

  /// No description provided for @incorrect_value.
  ///
  /// In ru, this message translates to:
  /// **'Некорректное значение'**
  String get incorrect_value;

  /// No description provided for @minimum.
  ///
  /// In ru, this message translates to:
  /// **'Не менее'**
  String get minimum;

  /// No description provided for @maximum.
  ///
  /// In ru, this message translates to:
  /// **'Не более'**
  String get maximum;

  /// No description provided for @calculate.
  ///
  /// In ru, this message translates to:
  /// **'Рассчитать'**
  String get calculate;

  /// No description provided for @result.
  ///
  /// In ru, this message translates to:
  /// **'Результат расчета'**
  String get result;

  /// No description provided for @packages_required.
  ///
  /// In ru, this message translates to:
  /// **'Понадобится упаковок'**
  String get packages_required;

  /// No description provided for @laying_variants.
  ///
  /// In ru, this message translates to:
  /// **'Варианты укладки'**
  String get laying_variants;

  /// No description provided for @panels.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{панель} few{панели} many{панелей} other{панели}}'**
  String panels(int count);

  /// No description provided for @laying_scheme.
  ///
  /// In ru, this message translates to:
  /// **'Схема укладки'**
  String get laying_scheme;

  /// No description provided for @next.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get next;

  /// No description provided for @no_laying_variants.
  ///
  /// In ru, this message translates to:
  /// **'Укладка с заданными параметрами невозможна. Попробуйте изменить смещение рядов или минимальную длину панели'**
  String get no_laying_variants;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'pl',
        'pt',
        'ru',
        'tr',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
