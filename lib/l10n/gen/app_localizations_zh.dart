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
