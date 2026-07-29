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
  String get choose_units => 'Choose a measurement system';

  @override
  String get metric_system => 'Metric (mm)';

  @override
  String get imperial_system => 'Imperial (feet and inches)';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get room => 'Room';

  @override
  String get length => 'Length';

  @override
  String get width => 'Width';

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
  String get result => 'Calculation result';

  @override
  String get packages_required => 'Packages required';

  @override
  String get laying_variants => 'Laying variants';

  @override
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'panels',
      one: 'panel',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Laying scheme';

  @override
  String get next => 'Next';

  @override
  String get no_laying_variants =>
      'No laying variant is possible with these parameters. Try changing the joint offset or the minimal piece length';

  @override
  String variant(int number) {
    return '#$number';
  }

  @override
  String get cut_list => 'Cut list';

  @override
  String row(int number) {
    return 'Row $number';
  }

  @override
  String get leftovers => 'Leftovers';

  @override
  String get waste => 'Waste';
}
