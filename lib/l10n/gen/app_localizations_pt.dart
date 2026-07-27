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
  String get units => 'Sistema de medidas';

  @override
  String get metric_units => 'mm';

  @override
  String get imperial_units => 'ft / in';

  @override
  String get room => 'Ambiente';

  @override
  String get length => 'Comprimento';

  @override
  String get width => 'Largura';

  @override
  String get length_in => 'Comprimento (in)';

  @override
  String get width_in => 'Largura (in)';

  @override
  String get laminate => 'Laminado';

  @override
  String get length_mm => 'Comprimento (mm)';

  @override
  String get width_mm => 'Largura (mm)';

  @override
  String get pieces_per_package => 'Peças por pacote';

  @override
  String get laying => 'Instalação';

  @override
  String get laying_direction => 'Direção de instalação';

  @override
  String get along_length => 'No comprimento';

  @override
  String get along_width => 'Na largura';

  @override
  String get expansion_gap_mm => 'Junta de dilatação (mm)';

  @override
  String get joint_offset_mm => 'Desalinhamento das juntas (mm)';

  @override
  String get minimal_piece_length => 'Comprimento mínimo da régua (mm)';

  @override
  String get expansion_gap_in => 'Junta de dilatação (in)';

  @override
  String get joint_offset_in => 'Desalinhamento das juntas (in)';

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
  String get panel_1 => 'réguas';

  @override
  String get panel_2_3_4 => 'réguas';

  @override
  String get panel_more => 'réguas';

  @override
  String get laying_scheme => 'Esquema de instalação';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get next => 'Avançar';

  @override
  String get no_laying_variants =>
      'Não é possível instalar com esses parâmetros. Tente alterar o desalinhamento das juntas ou o comprimento mínimo da régua';
}
