// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get title => 'Laminat-Rechner';

  @override
  String get mm => 'mm';

  @override
  String get pcs => 'Stk.';

  @override
  String get ft => 'ft';

  @override
  String get inch => 'in';

  @override
  String get choose_units => 'Maßsystem wählen';

  @override
  String get metric_system => 'Metrisch (mm)';

  @override
  String get imperial_system => 'Imperial (Fuß und Zoll)';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get room => 'Raum';

  @override
  String get length => 'Länge';

  @override
  String get width => 'Breite';

  @override
  String get laminate => 'Laminat';

  @override
  String get length_mm => 'Länge (mm)';

  @override
  String get width_mm => 'Breite (mm)';

  @override
  String get uneven_walls => 'Wände unterschiedlicher Länge';

  @override
  String get wall_length_near => 'Länge (oben)';

  @override
  String get wall_length_far => 'Länge (unten)';

  @override
  String get wall_width_left => 'Breite (links)';

  @override
  String get wall_width_right => 'Breite (rechts)';

  @override
  String get wall_length_near_mm => 'Länge (oben) mm';

  @override
  String get wall_length_far_mm => 'Länge (unten) mm';

  @override
  String get wall_width_left_mm => 'Breite (links) mm';

  @override
  String get wall_width_right_mm => 'Breite (rechts) mm';

  @override
  String get wall_diagonal => 'Diagonale';

  @override
  String get wall_diagonal_mm => 'Diagonale (mm)';

  @override
  String get walls_do_not_close => 'Die Wände schließen nicht';

  @override
  String get room_shape => 'Raumform';

  @override
  String get shape_rectangle => 'Rechteckig';

  @override
  String get shape_l => 'L-förmig';

  @override
  String get shape_chamfer => 'Ecke abgeschrägt';

  @override
  String get shape_chamfer_pair => 'Zwei Abschrägungen';

  @override
  String get shape_t => 'T-förmig';

  @override
  String get shape_z => 'Z-förmig';

  @override
  String get shape_u => 'U-förmig';

  @override
  String get chamfer_leg => 'Länge der Abschrägung';

  @override
  String get chamfer_leg_mm => 'Länge der Abschrägung (mm)';

  @override
  String get chamfer_leg_left => 'Abschrägung links';

  @override
  String get chamfer_leg_left_mm => 'Abschrägung links (mm)';

  @override
  String get chamfer_leg_right => 'Abschrägung rechts';

  @override
  String get chamfer_leg_right_mm => 'Abschrägung rechts (mm)';

  @override
  String get chamfer_leg_near => 'Abschrägung oben';

  @override
  String get chamfer_leg_near_mm => 'Abschrägung oben (mm)';

  @override
  String get chamfer_leg_far => 'Abschrägung unten';

  @override
  String get chamfer_leg_far_mm => 'Abschrägung unten (mm)';

  @override
  String get tap_wall_to_cut =>
      'Auf eine Wand tippen, um die Aussparungen zu versetzen';

  @override
  String get tap_wall_notch => 'Tippen Sie auf die Wand mit der Aussparung';

  @override
  String get notch_depth => 'Tiefe der Aussparung';

  @override
  String get notch_depth_mm => 'Tiefe der Aussparung (mm)';

  @override
  String get overall_length => 'Gesamtlänge';

  @override
  String get overall_width => 'Gesamtbreite';

  @override
  String get overall_length_mm => 'Gesamtlänge (mm)';

  @override
  String get overall_width_mm => 'Gesamtbreite (mm)';

  @override
  String get notch_length => 'Länge der Aussparung';

  @override
  String get notch_width => 'Breite der Aussparung';

  @override
  String get notch_length_mm => 'Länge der Aussparung (mm)';

  @override
  String get notch_width_mm => 'Breite der Aussparung (mm)';

  @override
  String notch_length_n(int number) {
    return 'Länge der Aussparung $number';
  }

  @override
  String notch_length_n_mm(int number) {
    return 'Länge der Aussparung $number (mm)';
  }

  @override
  String notch_width_n(int number) {
    return 'Breite der Aussparung $number';
  }

  @override
  String get symmetric_cut => 'Symmetrisch';

  @override
  String get stub_length => 'Länge des Vorsprungs';

  @override
  String get stub_length_mm => 'Länge des Vorsprungs (mm)';

  @override
  String get stub_width => 'Breite des Vorsprungs';

  @override
  String get stub_width_mm => 'Breite des Vorsprungs (mm)';

  @override
  String stub_length_n(int number) {
    return 'Länge des Vorsprungs $number';
  }

  @override
  String stub_length_n_mm(int number) {
    return 'Länge des Vorsprungs $number (mm)';
  }

  @override
  String stub_width_n(int number) {
    return 'Breite des Vorsprungs $number';
  }

  @override
  String stub_width_n_mm(int number) {
    return 'Breite des Vorsprungs $number (mm)';
  }

  @override
  String notch_width_n_mm(int number) {
    return 'Breite der Aussparung $number (mm)';
  }

  @override
  String get notch_does_not_fit => 'Die Aussparung lässt keinen Raum übrig';

  @override
  String get notches_overlap => 'Die Aussparungen überschneiden sich';

  @override
  String row_steps_at_notch(int number) {
    return 'Reihe $number verläuft über die ausgesparte Ecke: die Dielen an ihrem Ende werden um die Ecke ausgeklinkt, Form siehe Zeichnung';
  }

  @override
  String get tap_corner_to_cut => 'Tippen Sie auf die ausgesparte Ecke';

  @override
  String get tap_corner_notched => 'Tippen Sie auf die ausgesparte Ecke';

  @override
  String get tap_corner_to_move =>
      'Tippen Sie auf eine Ecke, um die Aussparungen zu versetzen';

  @override
  String get tap_wall_stem => 'Tippen Sie auf die Wand mit dem Vorsprung';

  @override
  String get diagonal_not_for_notch =>
      'Diagonale Verlegung wird in einem Raum mit ausgesparter Ecke noch nicht unterstützt';

  @override
  String get direction_across_notch_only =>
      'Ein Raum mit einer Aussparung in der Wand lässt sich nur quer zu dieser Wand verlegen';

  @override
  String get corner_top_left => 'Oben links';

  @override
  String get corner_top_right => 'Oben rechts';

  @override
  String get corner_bottom_right => 'Unten rechts';

  @override
  String get corner_bottom_left => 'Unten links';

  @override
  String get wall_top => 'Obere Wand';

  @override
  String get wall_right => 'Rechte Wand';

  @override
  String get wall_bottom => 'Untere Wand';

  @override
  String get wall_left => 'Linke Wand';

  @override
  String get pieces_per_package => 'Stück pro Paket';

  @override
  String get laying => 'Verlegung';

  @override
  String get along_length => 'Längs';

  @override
  String get along_width => 'Quer';

  @override
  String get diagonally => 'Diagonal';

  @override
  String get expansion_gap_mm => 'Dehnungsfuge (mm)';

  @override
  String get joint_offset => 'Fugenversatz';

  @override
  String get laying_direction => 'Verlegerichtung';

  @override
  String get expansion_gap => 'Dehnungsfuge';

  @override
  String get min_piece_length => 'Mindestlänge der Diele';

  @override
  String get exact_offset => 'genau';

  @override
  String get joint_offset_mm => 'Fugenversatz (mm)';

  @override
  String get minimal_piece_length => 'Minimale Paneellänge (mm)';

  @override
  String get expansion_gap_in => 'Dehnungsfuge (in)';

  @override
  String get joint_offset_in => 'Fugenversatz (in)';

  @override
  String get minimal_piece_length_in => 'Minimale Paneellänge (in)';

  @override
  String get required_field => 'Pflichtfeld';

  @override
  String get incorrect_value => 'Ungültiger Wert';

  @override
  String get minimum => 'Mindestens';

  @override
  String get maximum => 'Höchstens';

  @override
  String get calculate => 'Berechnen';

  @override
  String get result => 'Berechnungsergebnis';

  @override
  String get packages_required => 'Benötigte Pakete';

  @override
  String get laying_variants => 'Verlegevarianten';

  @override
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Paneele',
      one: 'Paneel',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Verlegeplan';

  @override
  String get next => 'Weiter';

  @override
  String get no_laying_variants =>
      'Mit diesen Parametern ist keine Verlegung möglich. Versuchen Sie, den Fugenversatz oder die minimale Paneellänge zu ändern';

  @override
  String variant(int number) {
    return 'Nr. $number';
  }

  @override
  String get cut_list => 'Zuschnittliste';

  @override
  String row(int number) {
    return 'Reihe $number';
  }

  @override
  String whole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ganz',
      one: 'ganz',
    );
    return '$_temp0';
  }

  @override
  String get leftovers => 'Reststücke';

  @override
  String get waste => 'Verschnitt';
}
