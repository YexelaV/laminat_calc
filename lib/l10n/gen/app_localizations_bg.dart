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
  String get wall_length_near => 'Дължина (горе)';

  @override
  String get wall_length_far => 'Дължина (долу)';

  @override
  String get wall_width_left => 'Широчина (ляво)';

  @override
  String get wall_width_right => 'Широчина (дясно)';

  @override
  String get wall_length_near_mm => 'Дължина (горе) мм';

  @override
  String get wall_length_far_mm => 'Дължина (долу) мм';

  @override
  String get wall_width_left_mm => 'Широчина (ляво) мм';

  @override
  String get wall_width_right_mm => 'Широчина (дясно) мм';

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
  String get shape_chamfer => 'Отрязан ъгъл';

  @override
  String get shape_chamfer_pair => 'Два отрязани ъгъла';

  @override
  String get shape_t => 'Т-образно';

  @override
  String get shape_z => 'Z-образно';

  @override
  String get shape_u => 'П-образно';

  @override
  String get chamfer_leg => 'Дължина на отрязването';

  @override
  String get chamfer_leg_mm => 'Дължина на отрязването (мм)';

  @override
  String get chamfer_leg_left => 'Отрязване отляво';

  @override
  String get chamfer_leg_left_mm => 'Отрязване отляво (мм)';

  @override
  String get chamfer_leg_right => 'Отрязване отдясно';

  @override
  String get chamfer_leg_right_mm => 'Отрязване отдясно (мм)';

  @override
  String get chamfer_leg_near => 'Отрязване отгоре';

  @override
  String get chamfer_leg_near_mm => 'Отрязване отгоре (мм)';

  @override
  String get chamfer_leg_far => 'Отрязване отдолу';

  @override
  String get chamfer_leg_far_mm => 'Отрязване отдолу (мм)';

  @override
  String get tap_wall_to_cut =>
      'Докоснете стена, за да преместите изрязванията';

  @override
  String get tap_wall_notch => 'Докоснете стената с изреза';

  @override
  String get notch_depth => 'Дълбочина на изреза';

  @override
  String get notch_depth_mm => 'Дълбочина на изреза (мм)';

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
  String notch_length_n(int number) {
    return 'Дължина на изрез $number';
  }

  @override
  String notch_length_n_mm(int number) {
    return 'Дължина на изрез $number (мм)';
  }

  @override
  String notch_width_n(int number) {
    return 'Широчина на изрез $number';
  }

  @override
  String get symmetric_cut => 'Симетрично';

  @override
  String get stub_length => 'Дължина на издатината';

  @override
  String get stub_length_mm => 'Дължина на издатината (мм)';

  @override
  String get stub_width => 'Широчина на издатината';

  @override
  String get stub_width_mm => 'Широчина на издатината (мм)';

  @override
  String stub_length_n(int number) {
    return 'Дължина на издатината $number';
  }

  @override
  String stub_length_n_mm(int number) {
    return 'Дължина на издатината $number (мм)';
  }

  @override
  String stub_width_n(int number) {
    return 'Широчина на издатината $number';
  }

  @override
  String stub_width_n_mm(int number) {
    return 'Широчина на издатината $number (мм)';
  }

  @override
  String notch_width_n_mm(int number) {
    return 'Широчина на изрез $number (мм)';
  }

  @override
  String get notch_does_not_fit => 'Изрезът не оставя помещение';

  @override
  String get notches_overlap => 'Изрезите се застъпват';

  @override
  String row_steps_at_notch(int number) {
    return 'Ред $number минава през ъгъла на изреза: крайните ламели се изрязват на стъпало, размерът е по схемата';
  }

  @override
  String get tap_corner_to_cut => 'Докоснете ъгъла, който е изрязан';

  @override
  String get tap_corner_notched => 'Докоснете ъгъла, който е изрязан';

  @override
  String get tap_corner_to_move => 'Докоснете ъгъл, за да преместите изрезите';

  @override
  String get tap_wall_stem => 'Докоснете стената с издатината';

  @override
  String get diagonal_not_for_notch =>
      'Диагонално полагане в помещение с изрез още не се поддържа';

  @override
  String get direction_across_notch_only =>
      'Помещение с изрез в стена може да се полага само напречно на тази стена';

  @override
  String get corner_top_left => 'Горен ляв';

  @override
  String get corner_top_right => 'Горен десен';

  @override
  String get corner_bottom_right => 'Долен десен';

  @override
  String get corner_bottom_left => 'Долен ляв';

  @override
  String get wall_top => 'Горна стена';

  @override
  String get wall_right => 'Дясна стена';

  @override
  String get wall_bottom => 'Долна стена';

  @override
  String get wall_left => 'Лява стена';

  @override
  String get pieces_per_package => 'В опаковка (броя)';

  @override
  String get laying => 'Полагане';

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
  String get laying_direction => 'Посока на полагане';

  @override
  String get expansion_gap => 'Фуга до стените';

  @override
  String get min_piece_length => 'Минимална дължина на дъска';

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
  String whole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'цели',
      one: 'цяла',
    );
    return '$_temp0';
  }

  @override
  String get leftovers => 'Остатъци';

  @override
  String get waste => 'Отпадъци';
}
