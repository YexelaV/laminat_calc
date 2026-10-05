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
  String wall_length(int number) {
    return 'Lunghezza $number';
  }

  @override
  String wall_width(int number) {
    return 'Larghezza $number';
  }

  @override
  String wall_length_mm(int number) {
    return 'Lunghezza $number (mm)';
  }

  @override
  String wall_width_mm(int number) {
    return 'Larghezza $number (mm)';
  }

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
  String shoulder(int number) {
    return 'Taglio $number';
  }

  @override
  String shoulder_mm(int number) {
    return 'Taglio $number (mm)';
  }

  @override
  String get chamfer_leg => 'Smusso (45°)';

  @override
  String get chamfer_leg_mm => 'Smusso a 45° (mm)';

  @override
  String notch(int number) {
    return 'Rientro $number';
  }

  @override
  String notch_mm(int number) {
    return 'Rientro $number (mm)';
  }

  @override
  String get cut_depth => 'Profondità dei rientri';

  @override
  String get cut_depth_mm => 'Profondità dei rientri (mm)';

  @override
  String get tap_wall_to_cut => 'Tocca una parete per spostare i rientri';

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
  String get notch_does_not_fit => 'Il rientro non lascia stanza';

  @override
  String row_steps_at_notch(int number) {
    return 'La fila $number attraversa l\'angolo tagliato: le doghe alla sua estremità vanno intagliate attorno, vedi il disegno';
  }

  @override
  String get tap_corner_to_cut => 'Tocca l\'angolo tagliato';

  @override
  String get diagonal_not_for_l_shape =>
      'La posa in diagonale non è ancora supportata in una stanza a forma di L';

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
  String get laying_direction => 'Senso di posa';

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
  String get leftovers => 'Sfridi riutilizzabili';

  @override
  String get waste => 'Scarto';
}
