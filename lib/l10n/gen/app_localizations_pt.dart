// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get title => 'Calculadora de Laminado';

  @override
  String get mm => 'mm';

  @override
  String get pcs => 'pçs';

  @override
  String get ft => 'ft';

  @override
  String get inch => 'in';

  @override
  String get choose_units => 'Escolha o sistema de medida';

  @override
  String get metric_system => 'Métrico (mm)';

  @override
  String get imperial_system => 'Imperial (pés e polegadas)';

  @override
  String get settings => 'Definições';

  @override
  String get language => 'Idioma';

  @override
  String get room => 'Ambiente';

  @override
  String get length => 'Comprimento';

  @override
  String get width => 'Largura';

  @override
  String get laminate => 'Laminado';

  @override
  String get length_mm => 'Comprimento (mm)';

  @override
  String get width_mm => 'Largura (mm)';

  @override
  String get uneven_walls => 'Paredes de comprimentos diferentes';

  @override
  String get wall_length_near => 'Comprimento (cima)';

  @override
  String get wall_length_far => 'Comprimento (baixo)';

  @override
  String get wall_width_left => 'Largura (esquerda)';

  @override
  String get wall_width_right => 'Largura (direita)';

  @override
  String get wall_length_near_mm => 'Comprimento (cima) mm';

  @override
  String get wall_length_far_mm => 'Comprimento (baixo) mm';

  @override
  String get wall_width_left_mm => 'Largura (esquerda) mm';

  @override
  String get wall_width_right_mm => 'Largura (direita) mm';

  @override
  String get wall_diagonal => 'Diagonal';

  @override
  String get wall_diagonal_mm => 'Diagonal (mm)';

  @override
  String get walls_do_not_close => 'As paredes não fecham';

  @override
  String get room_shape => 'Formato da divisão';

  @override
  String get shape_rectangle => 'Retangular';

  @override
  String get shape_l => 'Em forma de L';

  @override
  String get shape_chamfer => 'Canto cortado';

  @override
  String get shape_chamfer_pair => 'Dois cantos cortados';

  @override
  String get shape_t => 'Em forma de T';

  @override
  String get shape_z => 'Em forma de Z';

  @override
  String get shape_u => 'Em forma de U';

  @override
  String get chamfer_leg => 'Comprimento do corte';

  @override
  String get chamfer_leg_mm => 'Comprimento do corte (mm)';

  @override
  String get chamfer_leg_left => 'Corte à esquerda';

  @override
  String get chamfer_leg_left_mm => 'Corte à esquerda (mm)';

  @override
  String get chamfer_leg_right => 'Corte à direita';

  @override
  String get chamfer_leg_right_mm => 'Corte à direita (mm)';

  @override
  String get chamfer_leg_near => 'Corte em cima';

  @override
  String get chamfer_leg_near_mm => 'Corte em cima (mm)';

  @override
  String get chamfer_leg_far => 'Corte em baixo';

  @override
  String get chamfer_leg_far_mm => 'Corte em baixo (mm)';

  @override
  String get tap_wall_to_cut => 'Toque numa parede para mover os recortes';

  @override
  String get tap_wall_notch => 'Toque na parede com o recorte';

  @override
  String get notch_depth => 'Profundidade do recorte';

  @override
  String get notch_depth_mm => 'Profundidade do recorte (mm)';

  @override
  String get overall_length => 'Comprimento total';

  @override
  String get overall_width => 'Largura total';

  @override
  String get overall_length_mm => 'Comprimento total (mm)';

  @override
  String get overall_width_mm => 'Largura total (mm)';

  @override
  String get notch_length => 'Comprimento do recorte';

  @override
  String get notch_width => 'Largura do recorte';

  @override
  String get notch_length_mm => 'Comprimento do recorte (mm)';

  @override
  String get notch_width_mm => 'Largura do recorte (mm)';

  @override
  String notch_length_n(int number) {
    return 'Comprimento do recorte $number';
  }

  @override
  String notch_length_n_mm(int number) {
    return 'Comprimento do recorte $number (mm)';
  }

  @override
  String notch_width_n(int number) {
    return 'Largura do recorte $number';
  }

  @override
  String get symmetric_cut => 'Simétrico';

  @override
  String get stub_length => 'Comprimento da saliência';

  @override
  String get stub_length_mm => 'Comprimento da saliência (mm)';

  @override
  String get stub_width => 'Largura da saliência';

  @override
  String get stub_width_mm => 'Largura da saliência (mm)';

  @override
  String stub_length_n(int number) {
    return 'Comprimento da saliência $number';
  }

  @override
  String stub_length_n_mm(int number) {
    return 'Comprimento da saliência $number (mm)';
  }

  @override
  String stub_width_n(int number) {
    return 'Largura da saliência $number';
  }

  @override
  String stub_width_n_mm(int number) {
    return 'Largura da saliência $number (mm)';
  }

  @override
  String notch_width_n_mm(int number) {
    return 'Largura do recorte $number (mm)';
  }

  @override
  String get notch_does_not_fit => 'O recorte não deixa divisão';

  @override
  String get notches_overlap => 'Os recortes sobrepõem-se';

  @override
  String row_steps_at_notch(int number) {
    return 'A fileira $number atravessa o canto recortado: as réguas na ponta são recortadas em volta, veja o desenho';
  }

  @override
  String get tap_corner_to_cut => 'Toque no canto recortado';

  @override
  String get tap_corner_notched => 'Toque no canto que está recortado';

  @override
  String get tap_corner_to_move => 'Toque num canto para mover os recortes';

  @override
  String get tap_wall_stem => 'Toque na parede onde está a saliência';

  @override
  String get diagonal_not_for_notch =>
      'A colocação na diagonal ainda não é suportada numa divisão com um canto recortado';

  @override
  String get direction_across_notch_only =>
      'Uma divisão com um recorte numa parede só pode ser assente perpendicularmente a essa parede';

  @override
  String get corner_top_left => 'Superior esquerdo';

  @override
  String get corner_top_right => 'Superior direito';

  @override
  String get corner_bottom_right => 'Inferior direito';

  @override
  String get corner_bottom_left => 'Inferior esquerdo';

  @override
  String get wall_top => 'Parede superior';

  @override
  String get wall_right => 'Parede direita';

  @override
  String get wall_bottom => 'Parede inferior';

  @override
  String get wall_left => 'Parede esquerda';

  @override
  String get pieces_per_package => 'Peças por pacote';

  @override
  String get laying => 'Instalação';

  @override
  String get along_length => 'No comprimento';

  @override
  String get along_width => 'Na largura';

  @override
  String get diagonally => 'Na diagonal';

  @override
  String get expansion_gap_mm => 'Junta de dilatação (mm)';

  @override
  String get joint_offset => 'Defasagem das juntas';

  @override
  String get laying_direction => 'Sentido de assentamento';

  @override
  String get expansion_gap => 'Junta de dilatação';

  @override
  String get min_piece_length => 'Comprimento mínimo da régua';

  @override
  String get exact_offset => 'exato';

  @override
  String get joint_offset_mm => 'Defasagem das juntas (mm)';

  @override
  String get minimal_piece_length => 'Comprimento mínimo da régua (mm)';

  @override
  String get expansion_gap_in => 'Junta de dilatação (in)';

  @override
  String get joint_offset_in => 'Defasagem das juntas (in)';

  @override
  String get minimal_piece_length_in => 'Comprimento mínimo da régua (in)';

  @override
  String get required_field => 'Campo obrigatório';

  @override
  String get incorrect_value => 'Valor incorreto';

  @override
  String get minimum => 'Mínimo';

  @override
  String get maximum => 'Máximo';

  @override
  String get calculate => 'Calcular';

  @override
  String get result => 'Resultado do cálculo';

  @override
  String get packages_required => 'Pacotes necessários';

  @override
  String get laying_variants => 'Variantes de instalação';

  @override
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'réguas',
      one: 'régua',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Esquema de instalação';

  @override
  String get next => 'Avançar';

  @override
  String get no_laying_variants =>
      'Não é possível instalar com esses parâmetros. Tente alterar a defasagem das juntas ou o comprimento mínimo da régua';

  @override
  String variant(int number) {
    return 'N.º $number';
  }

  @override
  String get cut_list => 'Lista de cortes';

  @override
  String row(int number) {
    return 'Fileira $number';
  }

  @override
  String whole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'inteiras',
      one: 'inteira',
    );
    return '$_temp0';
  }

  @override
  String get leftovers => 'Sobras';

  @override
  String get waste => 'Descarte';
}
