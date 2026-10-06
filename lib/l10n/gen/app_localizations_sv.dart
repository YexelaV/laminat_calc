// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get title => 'Laminatkalkylator';

  @override
  String get mm => 'mm';

  @override
  String get pcs => 'st';

  @override
  String get ft => 'fot';

  @override
  String get inch => 'tum';

  @override
  String get choose_units => 'Välj måttsystem';

  @override
  String get metric_system => 'Metriskt (mm)';

  @override
  String get imperial_system => 'Imperiellt (fot och tum)';

  @override
  String get settings => 'Inställningar';

  @override
  String get language => 'Språk';

  @override
  String get room => 'Rum';

  @override
  String get length => 'Längd';

  @override
  String get width => 'Bredd';

  @override
  String get laminate => 'Laminat';

  @override
  String get length_mm => 'Längd (mm)';

  @override
  String get width_mm => 'Bredd (mm)';

  @override
  String get uneven_walls => 'Väggar av olika längd';

  @override
  String wall_length(int number) {
    return 'Längd $number';
  }

  @override
  String wall_width(int number) {
    return 'Bredd $number';
  }

  @override
  String wall_length_mm(int number) {
    return 'Längd $number (mm)';
  }

  @override
  String wall_width_mm(int number) {
    return 'Bredd $number (mm)';
  }

  @override
  String get wall_diagonal => 'Diagonal';

  @override
  String get wall_diagonal_mm => 'Diagonal (mm)';

  @override
  String get walls_do_not_close => 'Väggarna går inte ihop';

  @override
  String get room_shape => 'Rummets form';

  @override
  String get shape_rectangle => 'Rektangulärt';

  @override
  String get shape_l => 'L-format';

  @override
  String get shape_chamfer => 'Avfasat hörn';

  @override
  String get shape_chamfer_pair => 'Två avfasade hörn';

  @override
  String get shape_t => 'T-format';

  @override
  String shoulder(int number) {
    return 'Snitt $number';
  }

  @override
  String shoulder_mm(int number) {
    return 'Snitt $number (mm)';
  }

  @override
  String get chamfer_leg => 'Avfasning (45°)';

  @override
  String get chamfer_leg_mm => '45°-avfasning (mm)';

  @override
  String notch(int number) {
    return 'Urtag $number';
  }

  @override
  String notch_mm(int number) {
    return 'Urtag $number (mm)';
  }

  @override
  String get cut_depth => 'Urtagens djup';

  @override
  String get cut_depth_mm => 'Urtagens djup (mm)';

  @override
  String get tap_wall_to_cut => 'Tryck på en vägg för att flytta urtagen';

  @override
  String get overall_length => 'Total längd';

  @override
  String get overall_width => 'Total bredd';

  @override
  String get overall_length_mm => 'Total längd (mm)';

  @override
  String get overall_width_mm => 'Total bredd (mm)';

  @override
  String get notch_length => 'Urtagets längd';

  @override
  String get notch_width => 'Urtagets bredd';

  @override
  String get notch_length_mm => 'Urtagets längd (mm)';

  @override
  String get notch_width_mm => 'Urtagets bredd (mm)';

  @override
  String get notch_does_not_fit => 'Urtaget lämnar inget rum';

  @override
  String row_steps_at_notch(int number) {
    return 'Rad $number går förbi urtagets hörn: plankorna i dess ände sågas runt hörnet, mått enligt ritningen';
  }

  @override
  String get tap_corner_to_cut => 'Tryck på hörnet som är urtaget';

  @override
  String get diagonal_not_for_l_shape =>
      'Diagonal läggning stöds ännu inte i ett L-format rum';

  @override
  String get corner_top_left => 'Övre vänstra';

  @override
  String get corner_top_right => 'Övre högra';

  @override
  String get corner_bottom_right => 'Nedre högra';

  @override
  String get corner_bottom_left => 'Nedre vänstra';

  @override
  String get wall_top => 'Övre vägg';

  @override
  String get wall_right => 'Höger vägg';

  @override
  String get wall_bottom => 'Nedre vägg';

  @override
  String get wall_left => 'Vänster vägg';

  @override
  String get pieces_per_package => 'Per paket (st)';

  @override
  String get laying => 'Läggning';

  @override
  String get laying_direction => 'Läggningsriktning';

  @override
  String get along_length => 'Längs längden';

  @override
  String get along_width => 'Längs bredden';

  @override
  String get diagonally => 'Diagonalt';

  @override
  String get expansion_gap_mm => 'Expansionsfog (mm)';

  @override
  String get joint_offset => 'Skarvförskjutning';

  @override
  String get exact_offset => 'exakt';

  @override
  String get joint_offset_mm => 'Radförskjutning (mm)';

  @override
  String get minimal_piece_length => 'Minsta plankelängd (mm)';

  @override
  String get expansion_gap_in => 'Expansionsfog (tum)';

  @override
  String get joint_offset_in => 'Radförskjutning (tum)';

  @override
  String get minimal_piece_length_in => 'Minsta plankelängd (tum)';

  @override
  String get required_field => 'Obligatoriskt fält';

  @override
  String get incorrect_value => 'Ogiltigt värde';

  @override
  String get minimum => 'Minst';

  @override
  String get maximum => 'Högst';

  @override
  String get calculate => 'Beräkna';

  @override
  String get result => 'Beräkningsresultat';

  @override
  String get packages_required => 'Paket som behövs';

  @override
  String get laying_variants => 'Läggningsalternativ';

  @override
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'plankor',
      one: 'planka',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Läggningsschema';

  @override
  String get next => 'Nästa';

  @override
  String get no_laying_variants =>
      'Läggning med dessa värden är inte möjlig. Prova att ändra radförskjutningen eller minsta plankelängd';

  @override
  String variant(int number) {
    return '#$number';
  }

  @override
  String get cut_list => 'Kaplista';

  @override
  String row(int number) {
    return 'Rad $number';
  }

  @override
  String get whole => 'hela';

  @override
  String get leftovers => 'Rester';

  @override
  String get waste => 'Spill';
}
