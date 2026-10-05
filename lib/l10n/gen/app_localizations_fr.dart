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
  String get choose_units => 'Choisissez le système de mesure';

  @override
  String get metric_system => 'Métrique (mm)';

  @override
  String get imperial_system => 'Impérial (pieds et pouces)';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get room => 'Pièce';

  @override
  String get length => 'Longueur';

  @override
  String get width => 'Largeur';

  @override
  String get laminate => 'Stratifié';

  @override
  String get length_mm => 'Longueur (mm)';

  @override
  String get width_mm => 'Largeur (mm)';

  @override
  String get uneven_walls => 'Murs de longueurs différentes';

  @override
  String wall_length(int number) {
    return 'Longueur $number';
  }

  @override
  String wall_width(int number) {
    return 'Largeur $number';
  }

  @override
  String wall_length_mm(int number) {
    return 'Longueur $number (mm)';
  }

  @override
  String wall_width_mm(int number) {
    return 'Largeur $number (mm)';
  }

  @override
  String get wall_diagonal => 'Diagonale';

  @override
  String get wall_diagonal_mm => 'Diagonale (mm)';

  @override
  String get walls_do_not_close => 'Les murs ne se referment pas';

  @override
  String get room_shape => 'Forme de la pièce';

  @override
  String get shape_rectangle => 'Rectangulaire';

  @override
  String get shape_l => 'En forme de L';

  @override
  String get shape_chamfer => 'Angle coupé';

  @override
  String get shape_chamfer_pair => 'Deux angles coupés';

  @override
  String get shape_t => 'En forme de T';

  @override
  String shoulder(int number) {
    return 'Coupe $number';
  }

  @override
  String shoulder_mm(int number) {
    return 'Coupe $number (mm)';
  }

  @override
  String get chamfer_leg => 'Coupe (45°)';

  @override
  String get chamfer_leg_mm => 'Coupe à 45° (mm)';

  @override
  String notch(int number) {
    return 'Retrait $number';
  }

  @override
  String notch_mm(int number) {
    return 'Retrait $number (mm)';
  }

  @override
  String get cut_depth => 'Profondeur des retraits';

  @override
  String get cut_depth_mm => 'Profondeur des retraits (mm)';

  @override
  String get tap_wall_to_cut => 'Touchez un mur pour déplacer les retraits';

  @override
  String get overall_length => 'Longueur totale';

  @override
  String get overall_width => 'Largeur totale';

  @override
  String get overall_length_mm => 'Longueur totale (mm)';

  @override
  String get overall_width_mm => 'Largeur totale (mm)';

  @override
  String get notch_length => 'Longueur de la découpe';

  @override
  String get notch_width => 'Largeur de la découpe';

  @override
  String get notch_length_mm => 'Longueur de la découpe (mm)';

  @override
  String get notch_width_mm => 'Largeur de la découpe (mm)';

  @override
  String get notch_does_not_fit => 'La découpe ne laisse plus de pièce';

  @override
  String row_steps_at_notch(int number) {
    return 'La rangée $number traverse le coin découpé : les lames de son extrémité sont entaillées autour, voir le dessin';
  }

  @override
  String get tap_corner_to_cut => 'Touchez le coin découpé';

  @override
  String get diagonal_not_for_l_shape =>
      'La pose en diagonale n\'est pas encore prise en charge dans une pièce en L';

  @override
  String get corner_top_left => 'En haut à gauche';

  @override
  String get corner_top_right => 'En haut à droite';

  @override
  String get corner_bottom_right => 'En bas à droite';

  @override
  String get corner_bottom_left => 'En bas à gauche';

  @override
  String get wall_top => 'Mur du haut';

  @override
  String get wall_right => 'Mur de droite';

  @override
  String get wall_bottom => 'Mur du bas';

  @override
  String get wall_left => 'Mur de gauche';

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
  String get diagonally => 'En diagonale';

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

  @override
  String variant(int number) {
    return 'N° $number';
  }

  @override
  String get cut_list => 'Liste de coupe';

  @override
  String row(int number) {
    return 'Rangée $number';
  }

  @override
  String get leftovers => 'Chutes réutilisables';

  @override
  String get waste => 'Déchets';
}
