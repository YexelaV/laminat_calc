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
  String get choose_units => 'Выберите систему измерений';

  @override
  String get metric_system => 'Метрическая (мм)';

  @override
  String get imperial_system => 'Имперская (футы и дюймы)';

  @override
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get room => 'Помещение';

  @override
  String get length => 'Длина';

  @override
  String get width => 'Ширина';

  @override
  String get laminate => 'Ламинат';

  @override
  String get length_mm => 'Длина (мм)';

  @override
  String get width_mm => 'Ширина (мм)';

  @override
  String get uneven_walls => 'Стены разной длины';

  @override
  String get wall_length_near => 'Длина (верх)';

  @override
  String get wall_length_far => 'Длина (низ)';

  @override
  String get wall_width_left => 'Ширина (слева)';

  @override
  String get wall_width_right => 'Ширина (справа)';

  @override
  String get wall_length_near_mm => 'Длина (верх) мм';

  @override
  String get wall_length_far_mm => 'Длина (низ) мм';

  @override
  String get wall_width_left_mm => 'Ширина (слева) мм';

  @override
  String get wall_width_right_mm => 'Ширина (справа) мм';

  @override
  String get wall_diagonal => 'Диагональ';

  @override
  String get wall_diagonal_mm => 'Диагональ (мм)';

  @override
  String get walls_do_not_close => 'Стены не сходятся';

  @override
  String get room_shape => 'Форма помещения';

  @override
  String get shape_rectangle => 'Прямоугольное';

  @override
  String get shape_l => 'Г-образное';

  @override
  String get shape_chamfer => 'Срезанный угол';

  @override
  String get shape_chamfer_pair => 'Два среза';

  @override
  String get shape_t => 'Т-образное';

  @override
  String get shape_z => 'Z-образное';

  @override
  String get shape_u => 'П-образное';

  @override
  String get chamfer_leg => 'Длина среза';

  @override
  String get chamfer_leg_mm => 'Длина среза (мм)';

  @override
  String get chamfer_leg_left => 'Срез слева';

  @override
  String get chamfer_leg_left_mm => 'Срез слева (мм)';

  @override
  String get chamfer_leg_right => 'Срез справа';

  @override
  String get chamfer_leg_right_mm => 'Срез справа (мм)';

  @override
  String get chamfer_leg_near => 'Срез сверху';

  @override
  String get chamfer_leg_near_mm => 'Срез сверху (мм)';

  @override
  String get chamfer_leg_far => 'Срез снизу';

  @override
  String get chamfer_leg_far_mm => 'Срез снизу (мм)';

  @override
  String get tap_wall_to_cut => 'Коснитесь стены, чтобы перенести вырезы';

  @override
  String get tap_wall_notch => 'Коснитесь стены, в которой вырез';

  @override
  String get notch_depth => 'Глубина выреза';

  @override
  String get notch_depth_mm => 'Глубина выреза (мм)';

  @override
  String get overall_length => 'Общая длина';

  @override
  String get overall_width => 'Общая ширина';

  @override
  String get overall_length_mm => 'Общая длина (мм)';

  @override
  String get overall_width_mm => 'Общая ширина (мм)';

  @override
  String get notch_length => 'Длина выреза';

  @override
  String get notch_width => 'Ширина выреза';

  @override
  String get notch_length_mm => 'Длина выреза (мм)';

  @override
  String get notch_width_mm => 'Ширина выреза (мм)';

  @override
  String notch_length_n(int number) {
    return 'Длина выреза $number';
  }

  @override
  String notch_length_n_mm(int number) {
    return 'Длина выреза $number (мм)';
  }

  @override
  String notch_width_n(int number) {
    return 'Ширина выреза $number';
  }

  @override
  String get symmetric_cut => 'Симметрично';

  @override
  String get stub_length => 'Длина выступа';

  @override
  String get stub_length_mm => 'Длина выступа (мм)';

  @override
  String get stub_width => 'Ширина выступа';

  @override
  String get stub_width_mm => 'Ширина выступа (мм)';

  @override
  String stub_length_n(int number) {
    return 'Длина выступа $number';
  }

  @override
  String stub_length_n_mm(int number) {
    return 'Длина выступа $number (мм)';
  }

  @override
  String stub_width_n(int number) {
    return 'Ширина выступа $number';
  }

  @override
  String stub_width_n_mm(int number) {
    return 'Ширина выступа $number (мм)';
  }

  @override
  String notch_width_n_mm(int number) {
    return 'Ширина выреза $number (мм)';
  }

  @override
  String get notch_does_not_fit => 'Вырез не оставляет помещения';

  @override
  String get notches_overlap => 'Вырезы перекрывают друг друга';

  @override
  String row_steps_at_notch(int number) {
    return 'Ряд $number идёт через угол выреза: крайние панели режутся по ступеньке, размер по схеме';
  }

  @override
  String get tap_corner_to_cut => 'Нажмите на угол, который срезан';

  @override
  String get tap_corner_notched => 'Нажмите на угол, который вырезан';

  @override
  String get tap_corner_to_move => 'Нажмите на угол, чтобы перенести вырезы';

  @override
  String get tap_wall_stem => 'Нажмите на стену с выступом';

  @override
  String get diagonal_not_for_notch =>
      'Диагональная укладка в помещении с вырезом пока не поддерживается';

  @override
  String get direction_across_notch_only =>
      'В помещении с вырезом в стене укладка возможна только поперёк этой стены';

  @override
  String get corner_top_left => 'Верхний левый';

  @override
  String get corner_top_right => 'Верхний правый';

  @override
  String get corner_bottom_right => 'Нижний правый';

  @override
  String get corner_bottom_left => 'Нижний левый';

  @override
  String get wall_top => 'Верхняя стена';

  @override
  String get wall_right => 'Правая стена';

  @override
  String get wall_bottom => 'Нижняя стена';

  @override
  String get wall_left => 'Левая стена';

  @override
  String get pieces_per_package => 'В упаковке (штук)';

  @override
  String get laying => 'Укладка';

  @override
  String get along_length => 'По длине';

  @override
  String get along_width => 'По ширине';

  @override
  String get diagonally => 'По диагонали';

  @override
  String get expansion_gap_mm => 'Отступ от стен (мм)';

  @override
  String get joint_offset => 'Смещение стыков';

  @override
  String get laying_direction => 'Направление укладки';

  @override
  String get expansion_gap => 'Отступ от стен';

  @override
  String get min_piece_length => 'Минимальная длина панели';

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

  @override
  String variant(int number) {
    return '№$number';
  }

  @override
  String get cut_list => 'Список раскроя';

  @override
  String row(int number) {
    return 'Ряд $number';
  }

  @override
  String whole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'целые',
      one: 'целая',
    );
    return '$_temp0';
  }

  @override
  String get leftovers => 'Остатки';

  @override
  String get waste => 'Отходы';
}
