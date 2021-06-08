import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static Locale preferredLocale;
  static String defaultLanguageCode = 'en';

  String get languageCode => preferredLocale?.languageCode ?? defaultLanguageCode;

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Laminate Calculator',
      'm': 'm',
      'mm': 'mm',
      'pcs': 'pcs',
      'room': 'Room',
      'length_m': 'Length (m)',
      'width_m': 'Width (m)',
      'laminate': 'Laminate',
      'length_mm': 'Length (mm)',
      'width_mm': 'Width (mm)',
      'pieces_per_package': 'Pieces per package',
      'laying': 'Laying',
      'expansion_gap_mm': 'Expansion gap (mm)',
      'joint_offset_mm': 'Joint offset (mm)',
      'minimal_piece_length': 'Minimal piece length (mm)',
      'required_field': 'Required',
      'incorrect_value': 'Incorrect value',
      'minimum': 'Minimum',
      'maximum': 'Maximum',
      'calculate': 'Calculate',
      'result': 'Сalculation result',
      'packages_required': 'Packages required',
      'laying_variants': 'Laying variants',
      'panel_1': 'panels',
      'panel_2_3_4': 'panels',
      'panel_more': 'panels',
      'laying_scheme': 'Laying scheme',
      'language': 'Language/Язык',
      'english': 'English',
      'russian': 'Русский',
    },
    'ru': {
      'title': 'Калькулятор ламината',
      'm': 'м',
      'mm': 'мм',
      'pcs': 'шт',
      'room': 'Помещение',
      'length_m': 'Длина (м)',
      'width_m': 'Ширина (м)',
      'laminate': 'Ламинат',
      'length_mm': 'Длина (мм)',
      'width_mm': 'Ширина (мм)',
      'pieces_per_package': 'В упаковке (штук)',
      'laying': 'Укладка',
      'expansion_gap_mm': 'Отступ от стен (мм)',
      'joint_offset_mm': 'Смещение рядов (мм)',
      'minimal_piece_length': 'Минимальная длина панели (мм)',
      'required_field': 'Обязательное поле',
      'incorrect_value': 'Некорректное значение',
      'minimum': 'Не менее',
      'maximum': 'Не более',
      'calculate': 'Рассчитать',
      'result': 'Результат расчета',
      'packages_required': 'Понадобится упаковок',
      'laying_variants': 'Варианты укладки',
      'panel_1': 'панель',
      'panel_2_3_4': 'панели',
      'panel_more': 'панелей',
      'laying_scheme': 'Схема укладки',
      'language': 'Language/Язык',
      'english': 'English',
      'russian': 'Русский',
    },
  };

  String get title {
    return _localizedValues[languageCode]['title'];
  }

  String get m {
    return _localizedValues[languageCode]['m'];
  }

  String get mm {
    return _localizedValues[languageCode]['mm'];
  }

  String get pcs {
    return _localizedValues[languageCode]['pcs'];
  }

  String get room {
    return _localizedValues[languageCode]['room'];
  }

  String get lenth_m {
    return _localizedValues[languageCode]['length_m'];
  }

  String get width_m {
    return _localizedValues[languageCode]['width_m'];
  }

  String get laminate {
    return _localizedValues[languageCode]['laminate'];
  }

  String get length_mm {
    return _localizedValues[languageCode]['length_mm'];
  }

  String get width_mm {
    return _localizedValues[languageCode]['width_mm'];
  }

  String get pieces_per_package {
    return _localizedValues[languageCode]['pieces_per_package'];
  }

  String get laying {
    return _localizedValues[languageCode]['laying'];
  }

  String get expansion_gap_mm {
    return _localizedValues[languageCode]['expansion_gap_mm'];
  }

  String get joint_offset_mm {
    return _localizedValues[languageCode]['joint_offset_mm'];
  }

  String get minimal_piece_length {
    return _localizedValues[languageCode]['minimal_piece_length'];
  }

  String get required_field {
    return _localizedValues[languageCode]['required_field'];
  }

  String get incorrect_value {
    return _localizedValues[languageCode]['incorrect_value'];
  }

  String get minimum {
    return _localizedValues[languageCode]['minimum'];
  }

  String get maximum {
    return _localizedValues[languageCode]['maximum'];
  }

  String get calculate {
    return _localizedValues[languageCode]['calculate'];
  }

  String get result {
    return _localizedValues[languageCode]['result'];
  }

  String get packages_required {
    return _localizedValues[languageCode]['packages_required'];
  }

  String get laying_variants {
    return _localizedValues[languageCode]['laying_variants'];
  }

  String get panel_1 {
    return _localizedValues[languageCode]['panel_1'];
  }

  String get panel_2_3_4 {
    return _localizedValues[languageCode]['panel_2_3_4'];
  }

  String get panel_more {
    return _localizedValues[languageCode]['panel_more'];
  }

  String get laying_scheme {
    return _localizedValues[languageCode]['laying_scheme'];
  }

  String get language {
    return _localizedValues[languageCode]['language'];
  }

  String get english {
    return _localizedValues[languageCode]['english'];
  }

  String get russian {
    return _localizedValues[languageCode]['russian'];
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    // Returning a SynchronousFuture here because an async "load" operation
    // isn't needed to produce an instance of AppLocalizations.
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
