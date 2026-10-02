// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get title => '强化地板计算器';

  @override
  String get mm => '毫米';

  @override
  String get pcs => '块';

  @override
  String get ft => '英尺';

  @override
  String get inch => '英寸';

  @override
  String get choose_units => '选择计量单位';

  @override
  String get metric_system => '公制（毫米）';

  @override
  String get imperial_system => '英制（英尺和英寸）';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get room => '房间';

  @override
  String get length => '长度';

  @override
  String get width => '宽度';

  @override
  String get laminate => '强化地板';

  @override
  String get length_mm => '长度（毫米）';

  @override
  String get width_mm => '宽度（毫米）';

  @override
  String get uneven_walls => '墙长不一';

  @override
  String wall_length(int number) {
    return '长度 $number';
  }

  @override
  String wall_width(int number) {
    return '宽度 $number';
  }

  @override
  String wall_length_mm(int number) {
    return '长度 $number（毫米）';
  }

  @override
  String wall_width_mm(int number) {
    return '宽度 $number（毫米）';
  }

  @override
  String get wall_diagonal => '对角线';

  @override
  String get wall_diagonal_mm => '对角线（毫米）';

  @override
  String get walls_do_not_close => '墙无法闭合';

  @override
  String get room_shape => '房间形状';

  @override
  String get shape_rectangle => '矩形';

  @override
  String get shape_l => 'L 形';

  @override
  String get overall_length => '总长度';

  @override
  String get overall_width => '总宽度';

  @override
  String get overall_length_mm => '总长度（毫米）';

  @override
  String get overall_width_mm => '总宽度（毫米）';

  @override
  String get notch_length => '缺口长度';

  @override
  String get notch_width => '缺口宽度';

  @override
  String get notch_length_mm => '缺口长度（毫米）';

  @override
  String get notch_width_mm => '缺口宽度（毫米）';

  @override
  String get notch_does_not_fit => '缺口过大，房间无处可铺';

  @override
  String row_steps_at_notch(int number) {
    return '第 $number 行穿过被切掉的角：该行末端的板材需沿缺口开槽，形状见图';
  }

  @override
  String get tap_corner_to_cut => '点按被切掉的那个角';

  @override
  String get diagonal_not_for_l_shape => 'L 形房间暂不支持斜铺';

  @override
  String get corner_top_left => '左上';

  @override
  String get corner_top_right => '右上';

  @override
  String get corner_bottom_right => '右下';

  @override
  String get corner_bottom_left => '左下';

  @override
  String get pieces_per_package => '每包块数';

  @override
  String get laying => '铺设';

  @override
  String get laying_direction => '铺设方向';

  @override
  String get along_length => '沿长度';

  @override
  String get along_width => '沿宽度';

  @override
  String get diagonally => '斜铺';

  @override
  String get expansion_gap_mm => '伸缩缝（毫米）';

  @override
  String get joint_offset => '接缝错位';

  @override
  String get exact_offset => '精确';

  @override
  String get joint_offset_mm => '接缝错位（毫米）';

  @override
  String get minimal_piece_length => '地板最短长度（毫米）';

  @override
  String get expansion_gap_in => '伸缩缝（英寸）';

  @override
  String get joint_offset_in => '接缝错位（英寸）';

  @override
  String get minimal_piece_length_in => '地板最短长度（英寸）';

  @override
  String get required_field => '必填项';

  @override
  String get incorrect_value => '数值无效';

  @override
  String get minimum => '最小';

  @override
  String get maximum => '最大';

  @override
  String get calculate => '计算';

  @override
  String get result => '计算结果';

  @override
  String get packages_required => '所需包数';

  @override
  String get laying_variants => '铺设方案';

  @override
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '块',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => '铺设图';

  @override
  String get next => '下一步';

  @override
  String get no_laying_variants => '无法按这些参数铺设。请尝试修改接缝错位或地板最短长度';

  @override
  String variant(int number) {
    return '$number号';
  }

  @override
  String get cut_list => '裁切清单';

  @override
  String row(int number) {
    return '第$number排';
  }

  @override
  String get leftovers => '剩余可用料';

  @override
  String get waste => '废料';
}
