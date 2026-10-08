// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get title => 'Calcolatore Laminato';

  @override
  String get mm => 'mm';

  @override
  String get pcs => 'pz';

  @override
  String get ft => 'ft';

  @override
  String get inch => 'poll.';

  @override
  String get choose_units => 'Scegli il sistema di misura';

  @override
  String get metric_system => 'Metrico (mm)';

  @override
  String get imperial_system => 'Imperiale (piedi e pollici)';

  @override
  String get settings => 'Impostazioni';

  @override
  String get language => 'Lingua';

  @override
  String get room => 'Stanza';

  @override
  String get length => 'Lunghezza';

  @override
  String get width => 'Larghezza';

  @override
  String get laminate => 'Laminato';

  @override
  String get length_mm => 'Lunghezza (mm)';

  @override
  String get width_mm => 'Larghezza (mm)';

  @override
  String get uneven_walls => 'Pareti di lunghezze diverse';

  @override
  String get wall_length_near => 'Lunghezza (alto)';

  @override
  String get wall_length_far => 'Lunghezza (basso)';

  @override
  String get wall_width_left => 'Larghezza (sinistra)';

  @override
  String get wall_width_right => 'Larghezza (destra)';

  @override
  String get wall_length_near_mm => 'Lunghezza (alto) mm';

  @override
  String get wall_length_far_mm => 'Lunghezza (basso) mm';

  @override
  String get wall_width_left_mm => 'Larghezza (sinistra) mm';

  @override
  String get wall_width_right_mm => 'Larghezza (destra) mm';

  @override
  String get wall_diagonal => 'Diagonale';

  @override
  String get wall_diagonal_mm => 'Diagonale (mm)';

  @override
  String get walls_do_not_close => 'Le pareti non si chiudono';

  @override
  String get room_shape => 'Forma della stanza';

  @override
  String get shape_rectangle => 'Rettangolare';

  @override
  String get shape_l => 'A forma di L';

  @override
  String get shape_chamfer => 'Angolo smussato';

  @override
  String get shape_chamfer_pair => 'Due angoli smussati';

  @override
  String get shape_t => 'A forma di T';

  @override
  String get shape_z => 'A forma di Z';

  @override
  String get shape_u => 'A forma di U';

  @override
  String get chamfer_leg => 'Lunghezza dello smusso';

  @override
  String get chamfer_leg_mm => 'Lunghezza dello smusso (mm)';

  @override
  String get chamfer_leg_left => 'Smusso a sinistra';

  @override
  String get chamfer_leg_left_mm => 'Smusso a sinistra (mm)';

  @override
  String get chamfer_leg_right => 'Smusso a destra';

  @override
  String get chamfer_leg_right_mm => 'Smusso a destra (mm)';

  @override
  String get chamfer_leg_near => 'Smusso in alto';

  @override
  String get chamfer_leg_near_mm => 'Smusso in alto (mm)';

  @override
  String get chamfer_leg_far => 'Smusso in basso';

  @override
  String get chamfer_leg_far_mm => 'Smusso in basso (mm)';

  @override
  String get tap_wall_to_cut => 'Tocca una parete per spostare i rientri';

  @override
  String get tap_wall_notch => 'Tocca la parete con il rientro';

  @override
  String get notch_depth => 'Profondità del rientro';

  @override
  String get notch_depth_mm => 'Profondità del rientro (mm)';

  @override
  String get overall_length => 'Lunghezza totale';

  @override
  String get overall_width => 'Larghezza totale';

  @override
  String get overall_length_mm => 'Lunghezza totale (mm)';

  @override
  String get overall_width_mm => 'Larghezza totale (mm)';

  @override
  String get notch_length => 'Lunghezza del rientro';

  @override
  String get notch_width => 'Larghezza del rientro';

  @override
  String get notch_length_mm => 'Lunghezza del rientro (mm)';

  @override
  String get notch_width_mm => 'Larghezza del rientro (mm)';

  @override
  String notch_length_n(int number) {
    return 'Lunghezza del rientro $number';
  }

  @override
  String notch_length_n_mm(int number) {
    return 'Lunghezza del rientro $number (mm)';
  }

  @override
  String notch_width_n(int number) {
    return 'Larghezza del rientro $number';
  }

  @override
  String get symmetric_cut => 'Simmetrico';

  @override
  String get stub_length => 'Lunghezza della sporgenza';

  @override
  String get stub_length_mm => 'Lunghezza della sporgenza (mm)';

  @override
  String get stub_width => 'Larghezza della sporgenza';

  @override
  String get stub_width_mm => 'Larghezza della sporgenza (mm)';

  @override
  String stub_length_n(int number) {
    return 'Lunghezza della sporgenza $number';
  }

  @override
  String stub_length_n_mm(int number) {
    return 'Lunghezza della sporgenza $number (mm)';
  }

  @override
  String stub_width_n(int number) {
    return 'Larghezza della sporgenza $number';
  }

  @override
  String stub_width_n_mm(int number) {
    return 'Larghezza della sporgenza $number (mm)';
  }

  @override
  String notch_width_n_mm(int number) {
    return 'Larghezza del rientro $number (mm)';
  }

  @override
  String get notch_does_not_fit => 'Il rientro non lascia stanza';

  @override
  String get notches_overlap => 'I rientri si sovrappongono';

  @override
  String row_steps_at_notch(int number) {
    return 'La fila $number attraversa l\'angolo tagliato: le doghe alla sua estremità vanno intagliate attorno, vedi il disegno';
  }

  @override
  String get tap_corner_to_cut => 'Tocca l\'angolo tagliato';

  @override
  String get tap_corner_notched => 'Tocca l’angolo che è rientrato';

  @override
  String get tap_corner_to_move => 'Tocca un angolo per spostare i rientri';

  @override
  String get tap_wall_stem => 'Tocca la parete con la sporgenza';

  @override
  String get diagonal_not_for_notch =>
      'La posa in diagonale non è ancora supportata in una stanza con un angolo rientrante';

  @override
  String get direction_across_notch_only =>
      'Una stanza con un rientro in una parete si posa solo perpendicolarmente a quella parete';

  @override
  String get corner_top_left => 'In alto a sinistra';

  @override
  String get corner_top_right => 'In alto a destra';

  @override
  String get corner_bottom_right => 'In basso a destra';

  @override
  String get corner_bottom_left => 'In basso a sinistra';

  @override
  String get wall_top => 'Parete superiore';

  @override
  String get wall_right => 'Parete destra';

  @override
  String get wall_bottom => 'Parete inferiore';

  @override
  String get wall_left => 'Parete sinistra';

  @override
  String get pieces_per_package => 'Pezzi per confezione';

  @override
  String get laying => 'Posa';

  @override
  String get along_length => 'Lungo la lunghezza';

  @override
  String get along_width => 'Lungo la larghezza';

  @override
  String get diagonally => 'In diagonale';

  @override
  String get expansion_gap_mm => 'Giunto di dilatazione (mm)';

  @override
  String get joint_offset => 'Sfalsamento giunzioni';

  @override
  String get laying_direction => 'Senso di posa';

  @override
  String get expansion_gap => 'Fuga perimetrale';

  @override
  String get min_piece_length => 'Lunghezza minima doga';

  @override
  String get exact_offset => 'esatto';

  @override
  String get joint_offset_mm => 'Sfalsamento giunzioni (mm)';

  @override
  String get minimal_piece_length => 'Lunghezza minima doga (mm)';

  @override
  String get expansion_gap_in => 'Giunto di dilatazione (poll.)';

  @override
  String get joint_offset_in => 'Sfalsamento giunzioni (poll.)';

  @override
  String get minimal_piece_length_in => 'Lunghezza minima doga (poll.)';

  @override
  String get required_field => 'Campo obbligatorio';

  @override
  String get incorrect_value => 'Valore non valido';

  @override
  String get minimum => 'Non meno di';

  @override
  String get maximum => 'Non più di';

  @override
  String get calculate => 'Calcola';

  @override
  String get result => 'Risultato del calcolo';

  @override
  String get packages_required => 'Confezioni necessarie';

  @override
  String get laying_variants => 'Varianti di posa';

  @override
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'doghe',
      one: 'doga',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Schema di posa';

  @override
  String get next => 'Avanti';

  @override
  String get no_laying_variants =>
      'La posa con questi parametri non è possibile. Prova a modificare lo sfalsamento delle giunzioni o la lunghezza minima della doga';

  @override
  String variant(int number) {
    return 'N. $number';
  }

  @override
  String get cut_list => 'Lista di taglio';

  @override
  String row(int number) {
    return 'Fila $number';
  }

  @override
  String whole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'intere',
      one: 'intera',
    );
    return '$_temp0';
  }

  @override
  String get leftovers => 'Sfridi riutilizzabili';

  @override
  String get waste => 'Scarto';
}
