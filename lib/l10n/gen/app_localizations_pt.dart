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
  String get joint_offset => 'Defasagem das juntas';

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
  String get leftovers => 'Sobras';

  @override
  String get waste => 'Descarte';
}
