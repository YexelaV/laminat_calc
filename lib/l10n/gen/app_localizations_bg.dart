// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get title => 'Калкулатор за ламинат';

  @override
  String get mm => 'мм';

  @override
  String get pcs => 'бр.';

  @override
  String get ft => 'фут';

  @override
  String get inch => 'инч';

  @override
  String get choose_units => 'Изберете мерни единици';

  @override
  String get metric_system => 'Метрична (мм)';

  @override
  String get imperial_system => 'Имперска (футове и инчове)';

  @override
  String get settings => 'Настройки';

  @override
  String get language => 'Език';

  @override
  String get room => 'Помещение';

  @override
  String get length => 'Дължина';

  @override
  String get width => 'Широчина';

  @override
  String get laminate => 'Ламинат';

  @override
  String get length_mm => 'Дължина (мм)';

  @override
  String get width_mm => 'Широчина (мм)';

  @override
  String get uneven_walls => 'Стени с различна дължина';

  @override
  String wall_length(int number) {
    return 'Дължина $number';
  }

  @override
  String wall_width(int number) {
    return 'Широчина $number';
  }

  @override
  String wall_length_mm(int number) {
    return 'Дължина $number (мм)';
  }

  @override
  String wall_width_mm(int number) {
    return 'Широчина $number (мм)';
  }

  @override
  String get wall_diagonal => 'Диагонал';

  @override
  String get wall_diagonal_mm => 'Диагонал (мм)';

  @override
  String get walls_do_not_close => 'Стените не се затварят';

  @override
  String get room_shape => 'Форма на помещението';

  @override
  String get shape_rectangle => 'Правоъгълно';

  @override
  String get shape_l => 'Г-образно';

  @override
  String get overall_length => 'Обща дължина';

  @override
  String get overall_width => 'Обща широчина';

  @override
  String get overall_length_mm => 'Обща дължина (мм)';

  @override
  String get overall_width_mm => 'Обща широчина (мм)';

  @override
  String get notch_length => 'Дължина на изреза';

  @override
  String get notch_width => 'Широчина на изреза';

  @override
  String get notch_length_mm => 'Дължина на изреза (мм)';

  @override
  String get notch_width_mm => 'Широчина на изреза (мм)';

  @override
  String get notch_does_not_fit => 'Изрезът не оставя помещение';

  @override
  String row_steps_at_notch(int number) {
    return 'Ред $number минава през ъгъла на изреза: крайните ламели се изрязват на стъпало, размерът е по схемата';
  }

  @override
  String get tap_corner_to_cut => 'Докоснете ъгъла, който е изрязан';

  @override
  String get diagonal_not_for_l_shape =>
      'Диагонално полагане в Г-образно помещение още не се поддържа';

  @override
  String get corner_top_left => 'Горен ляв';

  @override
  String get corner_top_right => 'Горен десен';

  @override
  String get corner_bottom_right => 'Долен десен';

  @override
  String get corner_bottom_left => 'Долен ляв';

  @override
  String get pieces_per_package => 'В опаковка (броя)';

  @override
  String get laying => 'Полагане';

  @override
  String get laying_direction => 'Посока на полагане';

  @override
  String get along_length => 'По дължина';

  @override
  String get along_width => 'По широчина';

  @override
  String get diagonally => 'Диагонално';

  @override
  String get expansion_gap_mm => 'Дилатационна фуга (мм)';

  @override
  String get joint_offset => 'Разместване на фугите';

  @override
  String get exact_offset => 'точно';

  @override
  String get joint_offset_mm => 'Изместване на редовете (мм)';

  @override
  String get minimal_piece_length => 'Мин. дължина на ламела (мм)';

  @override
  String get expansion_gap_in => 'Дилатационна фуга (инч)';

  @override
  String get joint_offset_in => 'Изместване на редовете (инч)';

  @override
  String get minimal_piece_length_in => 'Мин. дължина на ламела (инч)';

  @override
  String get required_field => 'Задължително поле';

  @override
  String get incorrect_value => 'Некоректна стойност';

  @override
  String get minimum => 'Не по-малко от';

  @override
  String get maximum => 'Не повече от';

  @override
  String get calculate => 'Изчисли';

  @override
  String get result => 'Резултат от изчислението';

  @override
  String get packages_required => 'Необходими опаковки';

  @override
  String get laying_variants => 'Варианти на полагане';

  @override
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ламели',
      one: 'ламела',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Схема на полагане';

  @override
  String get next => 'Напред';

  @override
  String get no_laying_variants =>
      'Полагане със зададените параметри е невъзможно. Опитайте да промените изместването на редовете или минималната дължина на ламелата';

  @override
  String variant(int number) {
    return '№$number';
  }

  @override
  String get cut_list => 'Списък за разкрой';

  @override
  String row(int number) {
    return 'Ред $number';
  }

  @override
  String get leftovers => 'Остатъци';

  @override
  String get waste => 'Отпадъци';
}
