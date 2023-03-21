import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @title.
  ///
  /// In ru, this message translates to:
  /// **'Калькулятор Ламината'**
  String get title;

  /// No description provided for @m.
  ///
  /// In ru, this message translates to:
  /// **'м'**
  String get m;

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

  /// No description provided for @room.
  ///
  /// In ru, this message translates to:
  /// **'Помещение'**
  String get room;

  /// No description provided for @length_m.
  ///
  /// In ru, this message translates to:
  /// **'Длина (м)'**
  String get length_m;

  /// No description provided for @width_m.
  ///
  /// In ru, this message translates to:
  /// **'Ширина (м)'**
  String get width_m;

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

  /// No description provided for @expansion_gap_mm.
  ///
  /// In ru, this message translates to:
  /// **'Отступ от стен (мм)'**
  String get expansion_gap_mm;

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

  /// No description provided for @panel_1.
  ///
  /// In ru, this message translates to:
  /// **'панель'**
  String get panel_1;

  /// No description provided for @panel_2_3_4.
  ///
  /// In ru, this message translates to:
  /// **'панели'**
  String get panel_2_3_4;

  /// No description provided for @panel_more.
  ///
  /// In ru, this message translates to:
  /// **'панелей'**
  String get panel_more;

  /// No description provided for @laying_scheme.
  ///
  /// In ru, this message translates to:
  /// **'Схема укладки'**
  String get laying_scheme;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Language/Язык'**
  String get language;

  /// No description provided for @english.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @next.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get next;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
