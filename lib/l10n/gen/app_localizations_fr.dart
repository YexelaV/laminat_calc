// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get title => 'Calculateur de Stratifié';

  @override
  String get mm => 'mm';

  @override
  String get pcs => 'pcs';

  @override
  String get ft => 'ft';

  @override
  String get inch => 'in';

  @override
  String get units => 'Système de mesure';

  @override
  String get metric_units => 'mm';

  @override
  String get imperial_units => 'ft / in';

  @override
  String get room => 'Pièce';

  @override
  String get length => 'Longueur';

  @override
  String get width => 'Largeur';

  @override
  String get length_in => 'Longueur (in)';

  @override
  String get width_in => 'Largeur (in)';

  @override
  String get laminate => 'Stratifié';

  @override
  String get length_mm => 'Longueur (mm)';

  @override
  String get width_mm => 'Largeur (mm)';

  @override
  String get pieces_per_package => 'Pièces par paquet';

  @override
  String get laying => 'Pose';

  @override
  String get laying_direction => 'Sens de pose';

  @override
  String get along_length => 'Dans la longueur';

  @override
  String get along_width => 'Dans la largeur';

  @override
  String get expansion_gap_mm => 'Joint de dilatation (mm)';

  @override
  String get joint_offset => 'Décalage des joints';

  @override
  String get exact_offset => 'exact';

  @override
  String get joint_offset_mm => 'Décalage des joints (mm)';

  @override
  String get minimal_piece_length => 'Longueur minimale de lame (mm)';

  @override
  String get expansion_gap_in => 'Joint de dilatation (in)';

  @override
  String get joint_offset_in => 'Décalage des joints (in)';

  @override
  String get minimal_piece_length_in => 'Longueur minimale de lame (in)';

  @override
  String get required_field => 'Champ obligatoire';

  @override
  String get incorrect_value => 'Valeur incorrecte';

  @override
  String get minimum => 'Minimum';

  @override
  String get maximum => 'Maximum';

  @override
  String get calculate => 'Calculer';

  @override
  String get result => 'Résultat du calcul';

  @override
  String get packages_required => 'Paquets nécessaires';

  @override
  String get laying_variants => 'Variantes de pose';

  @override
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lames',
      one: 'lame',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Plan de pose';

  @override
  String get next => 'Suivant';

  @override
  String get no_laying_variants =>
      'Aucune pose n\'est possible avec ces paramètres. Essayez de modifier le décalage des joints ou la longueur minimale de lame';
}
