// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get title => 'Calculadora de Laminado';

  @override
  String get mm => 'mm';

  @override
  String get pcs => 'uds';

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
  String get room => 'Habitación';

  @override
  String get length => 'Longitud';

  @override
  String get width => 'Ancho';

  @override
  String get length_in => 'Longitud (in)';

  @override
  String get width_in => 'Ancho (in)';

  @override
  String get laminate => 'Laminado';

  @override
  String get length_mm => 'Longitud (mm)';

  @override
  String get width_mm => 'Ancho (mm)';

  @override
  String get pieces_per_package => 'Piezas por paquete';

  @override
  String get laying => 'Instalación';

  @override
  String get laying_direction => 'Dirección de instalación';

  @override
  String get along_length => 'A lo largo';

  @override
  String get along_width => 'A lo ancho';

  @override
  String get expansion_gap_mm => 'Junta de dilatación (mm)';

  @override
  String get joint_offset => 'Desfase de juntas';

  @override
  String get exact_offset => 'exacto';

  @override
  String get joint_offset_mm => 'Desplazamiento de juntas (mm)';

  @override
  String get minimal_piece_length => 'Longitud mínima del panel (mm)';

  @override
  String get expansion_gap_in => 'Junta de dilatación (in)';

  @override
  String get joint_offset_in => 'Desplazamiento de juntas (in)';

  @override
  String get minimal_piece_length_in => 'Longitud mínima del panel (in)';

  @override
  String get required_field => 'Campo obligatorio';

  @override
  String get incorrect_value => 'Valor incorrecto';

  @override
  String get minimum => 'Mínimo';

  @override
  String get maximum => 'Máximo';

  @override
  String get calculate => 'Calcular';

  @override
  String get result => 'Resultado del cálculo';

  @override
  String get packages_required => 'Paquetes necesarios';

  @override
  String get laying_variants => 'Variantes de instalación';

  @override
  String get panel_1 => 'paneles';

  @override
  String get panel_2_3_4 => 'paneles';

  @override
  String get panel_more => 'paneles';

  @override
  String get laying_scheme => 'Esquema de instalación';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get next => 'Siguiente';

  @override
  String get no_laying_variants =>
      'No es posible la instalación con estos parámetros. Intente cambiar el desplazamiento de juntas o la longitud mínima del panel';
}
