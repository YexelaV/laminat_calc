// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Laminate Calculator';

  @override
  String get mm => 'mm';

  @override
  String get pcs => 'pcs';

  @override
  String get ft => 'ft';

  @override
  String get inch => 'in';

  @override
  String get units => 'Measurement system';

  @override
  String get metric_units => 'mm';

  @override
  String get imperial_units => 'ft / in';

  @override
  String get room => 'Room';

  @override
  String get length => 'Length';

  @override
  String get width => 'Width';

  @override
  String get length_in => 'Length (in)';

  @override
  String get width_in => 'Width (in)';

  @override
  String get laminate => 'Laminate';

  @override
  String get length_mm => 'Length (mm)';

  @override
  String get width_mm => 'Width (mm)';

  @override
  String get pieces_per_package => 'Pieces per package';

  @override
  String get laying => 'Laying';

  @override
  String get laying_direction => 'Laying direction';

  @override
  String get along_length => 'Along length';

  @override
  String get along_width => 'Along width';

  @override
  String get expansion_gap_mm => 'Expansion gap (mm)';

  @override
  String get joint_offset => 'Joint offset';

  @override
  String get exact_offset => 'exact';

  @override
  String get joint_offset_mm => 'Joint offset (mm)';

  @override
  String get minimal_piece_length => 'Minimal piece length (mm)';

  @override
  String get expansion_gap_in => 'Expansion gap (in)';

  @override
  String get joint_offset_in => 'Joint offset (in)';

  @override
  String get minimal_piece_length_in => 'Minimal piece length (in)';

  @override
  String get required_field => 'Required';

  @override
  String get incorrect_value => 'Incorrect value';

  @override
  String get minimum => 'Minimum';

  @override
  String get maximum => 'Maximum';

  @override
  String get calculate => 'Calculate';

  @override
  String get result => 'Сalculation result';

  @override
  String get packages_required => 'Packages required';

  @override
  String get laying_variants => 'Laying variants';

  @override
  String get panel_1 => 'panels';

  @override
  String get panel_2_3_4 => 'panels';

  @override
  String get panel_more => 'panels';

  @override
  String get laying_scheme => 'Laying scheme';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get next => 'Next';

  @override
  String get no_laying_variants =>
      'No laying variant is possible with these parameters. Try changing the joint offset or the minimal piece length';
}
