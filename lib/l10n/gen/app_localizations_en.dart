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
  String get uneven_walls => 'Walls of different lengths';

  @override
  String get wall_length_near => 'Length (top)';

  @override
  String get wall_length_far => 'Length (bottom)';

  @override
  String get wall_width_left => 'Width (left)';

  @override
  String get wall_width_right => 'Width (right)';

  @override
  String get wall_length_near_mm => 'Length (top) mm';

  @override
  String get wall_length_far_mm => 'Length (bottom) mm';

  @override
  String get wall_width_left_mm => 'Width (left) mm';

  @override
  String get wall_width_right_mm => 'Width (right) mm';

  @override
  String get wall_diagonal => 'Diagonal';

  @override
  String get wall_diagonal_mm => 'Diagonal (mm)';

  @override
  String get walls_do_not_close => 'The walls do not close';

  @override
  String get room_shape => 'Room shape';

  @override
  String get shape_rectangle => 'Rectangular';

  @override
  String get shape_l => 'L-shaped';

  @override
  String get shape_chamfer => 'Cut corner';

  @override
  String get shape_chamfer_pair => 'Two cut corners';

  @override
  String get shape_t => 'T-shaped';

  @override
  String get shape_z => 'Z-shaped';

  @override
  String get shape_u => 'U-shaped';

  @override
  String get chamfer_leg => 'Cut length';

  @override
  String get chamfer_leg_mm => 'Cut length (mm)';

  @override
  String get chamfer_leg_left => 'Left cut';

  @override
  String get chamfer_leg_left_mm => 'Left cut (mm)';

  @override
  String get chamfer_leg_right => 'Right cut';

  @override
  String get chamfer_leg_right_mm => 'Right cut (mm)';

  @override
  String get chamfer_leg_near => 'Top cut';

  @override
  String get chamfer_leg_near_mm => 'Top cut (mm)';

  @override
  String get chamfer_leg_far => 'Bottom cut';

  @override
  String get chamfer_leg_far_mm => 'Bottom cut (mm)';

  @override
  String get tap_wall_to_cut => 'Tap a wall to move the cuts';

  @override
  String get tap_wall_notch => 'Tap the wall the notch is in';

  @override
  String get notch_depth => 'Notch depth';

  @override
  String get notch_depth_mm => 'Notch depth (mm)';

  @override
  String get overall_length => 'Overall length';

  @override
  String get overall_width => 'Overall width';

  @override
  String get overall_length_mm => 'Overall length (mm)';

  @override
  String get overall_width_mm => 'Overall width (mm)';

  @override
  String get notch_length => 'Notch length';

  @override
  String get notch_width => 'Notch width';

  @override
  String get notch_length_mm => 'Notch length (mm)';

  @override
  String get notch_width_mm => 'Notch width (mm)';

  @override
  String notch_length_n(int number) {
    return 'Notch $number length';
  }

  @override
  String notch_length_n_mm(int number) {
    return 'Notch $number length (mm)';
  }

  @override
  String notch_width_n(int number) {
    return 'Notch $number width';
  }

  @override
  String get symmetric_cut => 'Symmetrical';

  @override
  String get stub_length => 'Stem length';

  @override
  String get stub_length_mm => 'Stem length (mm)';

  @override
  String get stub_width => 'Stem width';

  @override
  String get stub_width_mm => 'Stem width (mm)';

  @override
  String stub_length_n(int number) {
    return 'Stem length $number';
  }

  @override
  String stub_length_n_mm(int number) {
    return 'Stem length $number (mm)';
  }

  @override
  String stub_width_n(int number) {
    return 'Stem width $number';
  }

  @override
  String stub_width_n_mm(int number) {
    return 'Stem width $number (mm)';
  }

  @override
  String notch_width_n_mm(int number) {
    return 'Notch $number width (mm)';
  }

  @override
  String get notch_does_not_fit => 'The notch leaves no room';

  @override
  String get notches_overlap => 'The notches overlap each other';

  @override
  String row_steps_at_notch(int number) {
    return 'Row $number crosses the cut-away corner: the planks at its end are notched round it, see the drawing for the shape';
  }

  @override
  String get tap_corner_to_cut => 'Tap the corner that is cut away';

  @override
  String get tap_corner_notched => 'Tap the corner that is notched';

  @override
  String get tap_corner_to_move => 'Tap a corner to move the notches';

  @override
  String get tap_wall_stem => 'Tap the wall the stem stands on';

  @override
  String get diagonal_not_for_notch =>
      'Diagonal laying is not supported in a room with a notched corner yet';

  @override
  String get direction_across_notch_only =>
      'A room with a notch in a wall can only be laid across that wall';

  @override
  String get corner_top_left => 'Top left';

  @override
  String get corner_top_right => 'Top right';

  @override
  String get corner_bottom_right => 'Bottom right';

  @override
  String get corner_bottom_left => 'Bottom left';

  @override
  String get wall_top => 'Top wall';

  @override
  String get wall_right => 'Right wall';

  @override
  String get wall_bottom => 'Bottom wall';

  @override
  String get wall_left => 'Left wall';

  @override
  String get pieces_per_package => 'Pieces per package';

  @override
  String get laying => 'Laying';

  @override
  String get along_length => 'Along length';

  @override
  String get along_width => 'Along width';

  @override
  String get diagonally => 'Diagonal';

  @override
  String get expansion_gap_mm => 'Expansion gap (mm)';

  @override
  String get joint_offset => 'Joint offset';

  @override
  String get laying_direction => 'Laying direction';

  @override
  String get expansion_gap => 'Expansion gap';

  @override
  String get min_piece_length => 'Minimum plank length';

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
  String whole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'whole',
      one: 'whole',
    );
    return '$_temp0';
  }

  @override
  String get leftovers => 'Leftovers';

  @override
  String get waste => 'Waste';
}
