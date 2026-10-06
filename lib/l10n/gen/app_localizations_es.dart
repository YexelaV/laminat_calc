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
  String get choose_units => 'Elige el sistema de medida';

  @override
  String get metric_system => 'Métrico (mm)';

  @override
  String get imperial_system => 'Imperial (pies y pulgadas)';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get room => 'Habitación';

  @override
  String get length => 'Longitud';

  @override
  String get width => 'Ancho';

  @override
  String get laminate => 'Laminado';

  @override
  String get length_mm => 'Longitud (mm)';

  @override
  String get width_mm => 'Ancho (mm)';

  @override
  String get uneven_walls => 'Paredes de distinta longitud';

  @override
  String wall_length(int number) {
    return 'Longitud $number';
  }

  @override
  String wall_width(int number) {
    return 'Ancho $number';
  }

  @override
  String wall_length_mm(int number) {
    return 'Longitud $number (mm)';
  }

  @override
  String wall_width_mm(int number) {
    return 'Ancho $number (mm)';
  }

  @override
  String get wall_diagonal => 'Diagonal';

  @override
  String get wall_diagonal_mm => 'Diagonal (mm)';

  @override
  String get walls_do_not_close => 'Las paredes no cierran';

  @override
  String get room_shape => 'Forma de la habitación';

  @override
  String get shape_rectangle => 'Rectangular';

  @override
  String get shape_l => 'En forma de L';

  @override
  String get shape_chamfer => 'Esquina cortada';

  @override
  String get shape_chamfer_pair => 'Dos esquinas cortadas';

  @override
  String get shape_t => 'En forma de T';

  @override
  String shoulder(int number) {
    return 'Corte $number';
  }

  @override
  String shoulder_mm(int number) {
    return 'Corte $number (mm)';
  }

  @override
  String get chamfer_leg => 'Corte (45°)';

  @override
  String get chamfer_leg_mm => 'Corte a 45° (mm)';

  @override
  String notch(int number) {
    return 'Hueco $number';
  }

  @override
  String notch_mm(int number) {
    return 'Hueco $number (mm)';
  }

  @override
  String get cut_depth => 'Profundidad de los huecos';

  @override
  String get cut_depth_mm => 'Profundidad de los huecos (mm)';

  @override
  String get tap_wall_to_cut => 'Toca una pared para mover los huecos';

  @override
  String get overall_length => 'Longitud total';

  @override
  String get overall_width => 'Ancho total';

  @override
  String get overall_length_mm => 'Longitud total (mm)';

  @override
  String get overall_width_mm => 'Ancho total (mm)';

  @override
  String get notch_length => 'Longitud del hueco';

  @override
  String get notch_width => 'Ancho del hueco';

  @override
  String get notch_length_mm => 'Longitud del hueco (mm)';

  @override
  String get notch_width_mm => 'Ancho del hueco (mm)';

  @override
  String get notch_does_not_fit => 'El hueco no deja habitación';

  @override
  String row_steps_at_notch(int number) {
    return 'La fila $number cruza la esquina recortada: las lamas de su extremo se recortan alrededor, consulte el dibujo';
  }

  @override
  String get tap_corner_to_cut => 'Toque la esquina recortada';

  @override
  String get diagonal_not_for_l_shape =>
      'La colocación en diagonal aún no se admite en una habitación en forma de L';

  @override
  String get corner_top_left => 'Superior izquierda';

  @override
  String get corner_top_right => 'Superior derecha';

  @override
  String get corner_bottom_right => 'Inferior derecha';

  @override
  String get corner_bottom_left => 'Inferior izquierda';

  @override
  String get wall_top => 'Pared superior';

  @override
  String get wall_right => 'Pared derecha';

  @override
  String get wall_bottom => 'Pared inferior';

  @override
  String get wall_left => 'Pared izquierda';

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
  String get diagonally => 'En diagonal';

  @override
  String get expansion_gap_mm => 'Junta de dilatación (mm)';

  @override
  String get joint_offset => 'Desfase de juntas';

  @override
  String get exact_offset => 'exacto';

  @override
  String get joint_offset_mm => 'Desfase de juntas (mm)';

  @override
  String get minimal_piece_length => 'Longitud mínima del panel (mm)';

  @override
  String get expansion_gap_in => 'Junta de dilatación (in)';

  @override
  String get joint_offset_in => 'Desfase de juntas (in)';

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
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paneles',
      one: 'panel',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Esquema de instalación';

  @override
  String get next => 'Siguiente';

  @override
  String get no_laying_variants =>
      'No es posible la instalación con estos parámetros. Intente cambiar el desfase de juntas o la longitud mínima del panel';

  @override
  String variant(int number) {
    return 'N.º $number';
  }

  @override
  String get cut_list => 'Lista de cortes';

  @override
  String row(int number) {
    return 'Fila $number';
  }

  @override
  String get whole => 'enteras';

  @override
  String get leftovers => 'Sobrantes';

  @override
  String get waste => 'Desperdicio';
}
