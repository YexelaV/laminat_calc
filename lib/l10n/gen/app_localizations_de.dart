// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get title => 'Laminat-Rechner';

  @override
  String get mm => 'mm';

  @override
  String get pcs => 'Stk';

  @override
  String get ft => 'ft';

  @override
  String get inch => 'in';

  @override
  String get units => 'Maßsystem';

  @override
  String get metric_units => 'mm';

  @override
  String get imperial_units => 'ft / in';

  @override
  String get room => 'Raum';

  @override
  String get length => 'Länge';

  @override
  String get width => 'Breite';

  @override
  String get length_in => 'Länge (in)';

  @override
  String get width_in => 'Breite (in)';

  @override
  String get laminate => 'Laminat';

  @override
  String get length_mm => 'Länge (mm)';

  @override
  String get width_mm => 'Breite (mm)';

  @override
  String get pieces_per_package => 'Stück pro Paket';

  @override
  String get laying => 'Verlegung';

  @override
  String get laying_direction => 'Verlegerichtung';

  @override
  String get along_length => 'Längs';

  @override
  String get along_width => 'Quer';

  @override
  String get expansion_gap_mm => 'Wandabstand (mm)';

  @override
  String get joint_offset => 'Fugenversatz';

  @override
  String get exact_offset => 'genau';

  @override
  String get joint_offset_mm => 'Fugenversatz (mm)';

  @override
  String get minimal_piece_length => 'Minimale Paneellänge (mm)';

  @override
  String get expansion_gap_in => 'Wandabstand (in)';

  @override
  String get joint_offset_in => 'Fugenversatz (in)';

  @override
  String get minimal_piece_length_in => 'Minimale Paneellänge (in)';

  @override
  String get required_field => 'Pflichtfeld';

  @override
  String get incorrect_value => 'Ungültiger Wert';

  @override
  String get minimum => 'Mindestens';

  @override
  String get maximum => 'Höchstens';

  @override
  String get calculate => 'Berechnen';

  @override
  String get result => 'Berechnungsergebnis';

  @override
  String get packages_required => 'Benötigte Pakete';

  @override
  String get laying_variants => 'Verlegevarianten';

  @override
  String get panel_1 => 'Paneele';

  @override
  String get panel_2_3_4 => 'Paneele';

  @override
  String get panel_more => 'Paneele';

  @override
  String get laying_scheme => 'Verlegeplan';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get next => 'Weiter';

  @override
  String get no_laying_variants =>
      'Mit diesen Parametern ist keine Verlegung möglich. Versuchen Sie, den Fugenversatz oder die minimale Paneellänge zu ändern';
}
