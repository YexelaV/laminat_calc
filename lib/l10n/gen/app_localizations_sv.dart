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
  String get wall_length_near => 'Längd (upptill)';

  @override
  String get wall_length_far => 'Längd (nedtill)';

  @override
  String get wall_width_left => 'Bredd (vänster)';

  @override
  String get wall_width_right => 'Bredd (höger)';

  @override
  String get wall_length_near_mm => 'Längd (upptill) mm';

  @override
  String get wall_length_far_mm => 'Längd (nedtill) mm';

  @override
  String get wall_width_left_mm => 'Bredd (vänster) mm';

  @override
  String get wall_width_right_mm => 'Bredd (höger) mm';

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
  String get shape_z => 'Z-format';

  @override
  String get shape_u => 'U-format';

  @override
  String get chamfer_leg => 'Avfasningens längd';

  @override
  String get chamfer_leg_mm => 'Avfasningens längd (mm)';

  @override
  String get chamfer_leg_left => 'Avfasning vänster';

  @override
  String get chamfer_leg_left_mm => 'Avfasning vänster (mm)';

  @override
  String get chamfer_leg_right => 'Avfasning höger';

  @override
  String get chamfer_leg_right_mm => 'Avfasning höger (mm)';

  @override
  String get chamfer_leg_near => 'Avfasning upptill';

  @override
  String get chamfer_leg_near_mm => 'Avfasning upptill (mm)';

  @override
  String get chamfer_leg_far => 'Avfasning nedtill';

  @override
  String get chamfer_leg_far_mm => 'Avfasning nedtill (mm)';

  @override
  String get tap_wall_to_cut => 'Tryck på en vägg för att flytta urtagen';

  @override
  String get tap_wall_notch => 'Tryck på väggen med urtaget';

  @override
  String get notch_depth => 'Urtagets djup';

  @override
  String get notch_depth_mm => 'Urtagets djup (mm)';

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
  String notch_length_n(int number) {
    return 'Längd för urtag $number';
  }

  @override
  String notch_length_n_mm(int number) {
    return 'Längd för urtag $number (mm)';
  }

  @override
  String notch_width_n(int number) {
    return 'Bredd för urtag $number';
  }

  @override
  String get symmetric_cut => 'Symmetriskt';

  @override
  String get stub_length => 'Utsprångets längd';

  @override
  String get stub_length_mm => 'Utsprångets längd (mm)';

  @override
  String get stub_width => 'Utsprångets bredd';

  @override
  String get stub_width_mm => 'Utsprångets bredd (mm)';

  @override
  String stub_length_n(int number) {
    return 'Utsprångets längd $number';
  }

  @override
  String stub_length_n_mm(int number) {
    return 'Utsprångets längd $number (mm)';
  }

  @override
  String stub_width_n(int number) {
    return 'Utsprångets bredd $number';
  }

  @override
  String stub_width_n_mm(int number) {
    return 'Utsprångets bredd $number (mm)';
  }

  @override
  String notch_width_n_mm(int number) {
    return 'Bredd för urtag $number (mm)';
  }

  @override
  String get notch_does_not_fit => 'Urtaget lämnar inget rum';

  @override
  String get notches_overlap => 'Urtagen överlappar varandra';

  @override
  String row_steps_at_notch(int number) {
    return 'Rad $number går förbi urtagets hörn: plankorna i dess ände sågas runt hörnet, mått enligt ritningen';
  }

  @override
  String get tap_corner_to_cut => 'Tryck på hörnet som är urtaget';

  @override
  String get tap_corner_notched => 'Tryck på hörnet som är urtaget';

  @override
  String get tap_corner_to_move => 'Tryck på ett hörn för att flytta urtagen';

  @override
  String get tap_wall_stem => 'Tryck på väggen där utsprånget sitter';

  @override
  String get diagonal_not_for_notch =>
      'Diagonal läggning stöds ännu inte i ett rum med ett urtaget hörn';

  @override
  String get direction_across_notch_only =>
      'Ett rum med ett urtag i en vägg kan bara läggas tvärs den väggen';

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
  String get laying_direction => 'Läggningsriktning';

  @override
  String get expansion_gap => 'Rörelsefog';

  @override
  String get min_piece_length => 'Minsta planklängd';

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
  String whole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hela',
      one: 'hel',
    );
    return '$_temp0';
  }

  @override
  String get leftovers => 'Rester';

  @override
  String get waste => 'Spill';
}
