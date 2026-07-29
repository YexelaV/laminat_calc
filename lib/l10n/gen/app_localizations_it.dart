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
