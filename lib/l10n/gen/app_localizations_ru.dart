// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get title => 'Калькулятор Ламината';

  @override
  String get mm => 'мм';

  @override
  String get pcs => 'шт';

  @override
  String get ft => 'фут';

  @override
  String get inch => 'дюйм';

  @override
  String get units => 'Система измерений';

  @override
  String get metric_units => 'мм';

  @override
  String get imperial_units => 'фут / дюйм';

  @override
  String get room => 'Помещение';

  @override
  String get length => 'Длина';

  @override
  String get width => 'Ширина';

  @override
  String get length_in => 'Длина (дюйм)';

  @override
  String get width_in => 'Ширина (дюйм)';

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
  String get laying_direction => 'Направление укладки';

  @override
  String get along_length => 'По длине';

  @override
  String get along_width => 'По ширине';

  @override
  String get expansion_gap_mm => 'Отступ от стен (мм)';

  @override
  String get joint_offset => 'Смещение стыков';

  @override
  String get exact_offset => 'точно';

  @override
  String get joint_offset_mm => 'Смещение рядов (мм)';

  @override
  String get minimal_piece_length => 'Минимальная длина панели (мм)';

  @override
  String get expansion_gap_in => 'Отступ от стен (дюйм)';

  @override
  String get joint_offset_in => 'Смещение рядов (дюйм)';

  @override
  String get minimal_piece_length_in => 'Минимальная длина панели (дюйм)';

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
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'панели',
      many: 'панелей',
      few: 'панели',
      one: 'панель',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Схема укладки';

  @override
  String get next => 'Далее';

  @override
  String get no_laying_variants =>
      'Укладка с заданными параметрами невозможна. Попробуйте изменить смещение рядов или минимальную длину панели';
}
