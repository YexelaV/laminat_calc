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
  String get wall_length_near => 'Longueur (haut)';

  @override
  String get wall_length_far => 'Longueur (bas)';

  @override
  String get wall_width_left => 'Largeur (gauche)';

  @override
  String get wall_width_right => 'Largeur (droite)';

  @override
  String get wall_length_near_mm => 'Longueur (haut) mm';

  @override
  String get wall_length_far_mm => 'Longueur (bas) mm';

  @override
  String get wall_width_left_mm => 'Largeur (gauche) mm';

  @override
  String get wall_width_right_mm => 'Largeur (droite) mm';

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
  String get shape_z => 'En forme de Z';

  @override
  String get shape_u => 'En forme de U';

  @override
  String get chamfer_leg => 'Longueur de la coupe';

  @override
  String get chamfer_leg_mm => 'Longueur de la coupe (mm)';

  @override
  String get chamfer_leg_left => 'Coupe à gauche';

  @override
  String get chamfer_leg_left_mm => 'Coupe à gauche (mm)';

  @override
  String get chamfer_leg_right => 'Coupe à droite';

  @override
  String get chamfer_leg_right_mm => 'Coupe à droite (mm)';

  @override
  String get chamfer_leg_near => 'Coupe en haut';

  @override
  String get chamfer_leg_near_mm => 'Coupe en haut (mm)';

  @override
  String get chamfer_leg_far => 'Coupe en bas';

  @override
  String get chamfer_leg_far_mm => 'Coupe en bas (mm)';

  @override
  String get tap_wall_to_cut => 'Touchez un mur pour déplacer les retraits';

  @override
  String get tap_wall_notch => 'Touchez le mur où se trouve la découpe';

  @override
  String get notch_depth => 'Profondeur de la découpe';

  @override
  String get notch_depth_mm => 'Profondeur de la découpe (mm)';

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
  String notch_length_n(int number) {
    return 'Longueur de la découpe $number';
  }

  @override
  String notch_length_n_mm(int number) {
    return 'Longueur de la découpe $number (mm)';
  }

  @override
  String notch_width_n(int number) {
    return 'Largeur de la découpe $number';
  }

  @override
  String get symmetric_cut => 'Symétrique';

  @override
  String get stub_length => 'Longueur de l’avancée';

  @override
  String get stub_length_mm => 'Longueur de l’avancée (mm)';

  @override
  String get stub_width => 'Largeur de l’avancée';

  @override
  String get stub_width_mm => 'Largeur de l’avancée (mm)';

  @override
  String stub_length_n(int number) {
    return 'Longueur de l’avancée $number';
  }

  @override
  String stub_length_n_mm(int number) {
    return 'Longueur de l’avancée $number (mm)';
  }

  @override
  String stub_width_n(int number) {
    return 'Largeur de l’avancée $number';
  }

  @override
  String stub_width_n_mm(int number) {
    return 'Largeur de l’avancée $number (mm)';
  }

  @override
  String notch_width_n_mm(int number) {
    return 'Largeur de la découpe $number (mm)';
  }

  @override
  String get notch_does_not_fit => 'La découpe ne laisse plus de pièce';

  @override
  String get notches_overlap => 'Les découpes se chevauchent';

  @override
  String row_steps_at_notch(int number) {
    return 'La rangée $number traverse le coin découpé : les lames de son extrémité sont entaillées autour, voir le dessin';
  }

  @override
  String get tap_corner_to_cut => 'Touchez le coin découpé';

  @override
  String get tap_corner_notched => 'Touchez le coin qui est découpé';

  @override
  String get tap_corner_to_move => 'Touchez un coin pour déplacer les découpes';

  @override
  String get tap_wall_stem => 'Touchez le mur où se trouve l’avancée';

  @override
  String get diagonal_not_for_notch =>
      'La pose en diagonale n\'est pas encore prise en charge dans une pièce avec un angle découpé';

  @override
  String get direction_across_notch_only =>
      'Une pièce avec une découpe dans un mur ne se pose que perpendiculairement à ce mur';

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
  String get laying_direction => 'Sens de pose';

  @override
  String get expansion_gap => 'Joint de dilatation';

  @override
  String get min_piece_length => 'Longueur minimale de lame';

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
  String whole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'entières',
      one: 'entière',
    );
    return '$_temp0';
  }

  @override
  String get leftovers => 'Chutes réutilisables';

  @override
  String get waste => 'Déchets';
}
