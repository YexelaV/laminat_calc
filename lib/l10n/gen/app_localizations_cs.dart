// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get title => 'Kalkulačka laminátu';

  @override
  String get mm => 'mm';

  @override
  String get pcs => 'ks';

  @override
  String get ft => 'stopa';

  @override
  String get inch => 'palec';

  @override
  String get choose_units => 'Vyberte soustavu měr';

  @override
  String get metric_system => 'Metrická (mm)';

  @override
  String get imperial_system => 'Imperiální (stopy a palce)';

  @override
  String get settings => 'Nastavení';

  @override
  String get language => 'Jazyk';

  @override
  String get room => 'Místnost';

  @override
  String get length => 'Délka';

  @override
  String get width => 'Šířka';

  @override
  String get laminate => 'Laminát';

  @override
  String get length_mm => 'Délka (mm)';

  @override
  String get width_mm => 'Šířka (mm)';

  @override
  String get uneven_walls => 'Stěny různé délky';

  @override
  String wall_length(int number) {
    return 'Délka $number';
  }

  @override
  String wall_width(int number) {
    return 'Šířka $number';
  }

  @override
  String wall_length_mm(int number) {
    return 'Délka $number (mm)';
  }

  @override
  String wall_width_mm(int number) {
    return 'Šířka $number (mm)';
  }

  @override
  String get wall_diagonal => 'Úhlopříčka';

  @override
  String get wall_diagonal_mm => 'Úhlopříčka (mm)';

  @override
  String get walls_do_not_close => 'Stěny se neuzavírají';

  @override
  String get room_shape => 'Tvar místnosti';

  @override
  String get shape_rectangle => 'Obdélníková';

  @override
  String get shape_l => 'Tvar L';

  @override
  String get shape_chamfer => 'Zkosený roh';

  @override
  String get shape_chamfer_pair => 'Dva zkosené rohy';

  @override
  String get shape_t => 'Ve tvaru T';

  @override
  String shoulder(int number) {
    return 'Řez $number';
  }

  @override
  String shoulder_mm(int number) {
    return 'Řez $number (mm)';
  }

  @override
  String get chamfer_leg => 'Zkosení (45°)';

  @override
  String get chamfer_leg_mm => 'Zkosení 45° (mm)';

  @override
  String notch(int number) {
    return 'Výřez $number';
  }

  @override
  String notch_mm(int number) {
    return 'Výřez $number (mm)';
  }

  @override
  String get cut_depth => 'Hloubka výřezů';

  @override
  String get cut_depth_mm => 'Hloubka výřezů (mm)';

  @override
  String get tap_wall_to_cut => 'Klepnutím na stěnu přesunete výřezy';

  @override
  String get overall_length => 'Celková délka';

  @override
  String get overall_width => 'Celková šířka';

  @override
  String get overall_length_mm => 'Celková délka (mm)';

  @override
  String get overall_width_mm => 'Celková šířka (mm)';

  @override
  String get notch_length => 'Délka výřezu';

  @override
  String get notch_width => 'Šířka výřezu';

  @override
  String get notch_length_mm => 'Délka výřezu (mm)';

  @override
  String get notch_width_mm => 'Šířka výřezu (mm)';

  @override
  String get notch_does_not_fit => 'Výřez nenechává žádnou plochu';

  @override
  String row_steps_at_notch(int number) {
    return 'Řada $number prochází rohem výřezu: krajní lamely se řežou do schodu, rozměr podle schématu';
  }

  @override
  String get tap_corner_to_cut => 'Klepněte na roh, který je vyříznutý';

  @override
  String get diagonal_not_for_l_shape =>
      'Diagonální pokládka v místnosti tvaru L zatím není podporována';

  @override
  String get corner_top_left => 'Vlevo nahoře';

  @override
  String get corner_top_right => 'Vpravo nahoře';

  @override
  String get corner_bottom_right => 'Vpravo dole';

  @override
  String get corner_bottom_left => 'Vlevo dole';

  @override
  String get wall_top => 'Horní stěna';

  @override
  String get wall_right => 'Pravá stěna';

  @override
  String get wall_bottom => 'Dolní stěna';

  @override
  String get wall_left => 'Levá stěna';

  @override
  String get pieces_per_package => 'V balení (ks)';

  @override
  String get laying => 'Pokládka';

  @override
  String get laying_direction => 'Směr pokládky';

  @override
  String get along_length => 'Po délce';

  @override
  String get along_width => 'Po šířce';

  @override
  String get diagonally => 'Diagonálně';

  @override
  String get expansion_gap_mm => 'Dilatační spára (mm)';

  @override
  String get joint_offset => 'Převazba spár';

  @override
  String get exact_offset => 'přesně';

  @override
  String get joint_offset_mm => 'Posun řad (mm)';

  @override
  String get minimal_piece_length => 'Min. délka lamely (mm)';

  @override
  String get expansion_gap_in => 'Dilatační spára (palce)';

  @override
  String get joint_offset_in => 'Posun řad (palce)';

  @override
  String get minimal_piece_length_in => 'Min. délka lamely (palce)';

  @override
  String get required_field => 'Povinné pole';

  @override
  String get incorrect_value => 'Neplatná hodnota';

  @override
  String get minimum => 'Nejméně';

  @override
  String get maximum => 'Nejvýše';

  @override
  String get calculate => 'Spočítat';

  @override
  String get result => 'Výsledek výpočtu';

  @override
  String get packages_required => 'Potřebná balení';

  @override
  String get laying_variants => 'Varianty pokládky';

  @override
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lamel',
      many: 'lamely',
      few: 'lamely',
      one: 'lamela',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Schéma pokládky';

  @override
  String get next => 'Dále';

  @override
  String get no_laying_variants =>
      'Pokládka se zadanými parametry není možná. Zkuste změnit posun řad nebo minimální délku lamely';

  @override
  String variant(int number) {
    return 'č.$number';
  }

  @override
  String get cut_list => 'Seznam řezů';

  @override
  String row(int number) {
    return 'Řada $number';
  }

  @override
  String get whole => 'celé';

  @override
  String get leftovers => 'Zbytky';

  @override
  String get waste => 'Odpad';
}
