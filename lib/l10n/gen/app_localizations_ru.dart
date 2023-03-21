import 'app_localizations.dart';

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get title => 'Калькулятор Ламината';

  @override
  String get m => 'м';

  @override
  String get mm => 'мм';

  @override
  String get pcs => 'шт';

  @override
  String get room => 'Помещение';

  @override
  String get length_m => 'Длина (м)';

  @override
  String get width_m => 'Ширина (м)';

  @override
  String get laminate => 'Ламинат';

  @override
  String get length_mm => 'Длина (мм)';

  @override
  String get width_mm => 'Ширина (мм)';

  @override
  String get pieces_per_package => 'В упаковке (штук)';

  @override
  String get laying => 'Укладка';

  @override
  String get expansion_gap_mm => 'Отступ от стен (мм)';

  @override
  String get joint_offset_mm => 'Смещение рядов (мм)';

  @override
  String get minimal_piece_length => 'Минимальная длина панели (мм)';

  @override
  String get required_field => 'Обязательное поле';

  @override
  String get incorrect_value => 'Некорректное значение';

  @override
  String get minimum => 'Не менее';

  @override
  String get maximum => 'Не более';

  @override
  String get calculate => 'Рассчитать';

  @override
  String get result => 'Результат расчета';

  @override
  String get packages_required => 'Понадобится упаковок';

  @override
  String get laying_variants => 'Варианты укладки';

  @override
  String get panel_1 => 'панель';

  @override
  String get panel_2_3_4 => 'панели';

  @override
  String get panel_more => 'панелей';

  @override
  String get laying_scheme => 'Схема укладки';

  @override
  String get language => 'Language/Язык';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get next => 'Далее';
}
