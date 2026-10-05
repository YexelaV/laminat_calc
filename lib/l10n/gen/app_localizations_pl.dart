// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get title => 'Kalkulator Laminatu';

  @override
  String get mm => 'mm';

  @override
  String get pcs => 'szt.';

  @override
  String get ft => 'ft';

  @override
  String get inch => 'cal';

  @override
  String get choose_units => 'Wybierz system miar';

  @override
  String get metric_system => 'Metryczny (mm)';

  @override
  String get imperial_system => 'Imperialny (stopy i cale)';

  @override
  String get settings => 'Ustawienia';

  @override
  String get language => 'Język';

  @override
  String get room => 'Pomieszczenie';

  @override
  String get length => 'Długość';

  @override
  String get width => 'Szerokość';

  @override
  String get laminate => 'Laminat';

  @override
  String get length_mm => 'Długość (mm)';

  @override
  String get width_mm => 'Szerokość (mm)';

  @override
  String get uneven_walls => 'Ściany o różnej długości';

  @override
  String wall_length(int number) {
    return 'Długość $number';
  }

  @override
  String wall_width(int number) {
    return 'Szerokość $number';
  }

  @override
  String wall_length_mm(int number) {
    return 'Długość $number (mm)';
  }

  @override
  String wall_width_mm(int number) {
    return 'Szerokość $number (mm)';
  }

  @override
  String get wall_diagonal => 'Przekątna';

  @override
  String get wall_diagonal_mm => 'Przekątna (mm)';

  @override
  String get walls_do_not_close => 'Ściany się nie domykają';

  @override
  String get room_shape => 'Kształt pomieszczenia';

  @override
  String get shape_rectangle => 'Prostokątne';

  @override
  String get shape_l => 'W kształcie litery L';

  @override
  String get shape_chamfer => 'Ścięty narożnik';

  @override
  String get shape_chamfer_pair => 'Dwa ścięcia';

  @override
  String get shape_t => 'W kształcie litery T';

  @override
  String shoulder(int number) {
    return 'Ścięcie $number';
  }

  @override
  String shoulder_mm(int number) {
    return 'Ścięcie $number (mm)';
  }

  @override
  String get chamfer_leg => 'Ścięcie (45°)';

  @override
  String get chamfer_leg_mm => 'Ścięcie pod 45° (mm)';

  @override
  String notch(int number) {
    return 'Wcięcie $number';
  }

  @override
  String notch_mm(int number) {
    return 'Wcięcie $number (mm)';
  }

  @override
  String get cut_depth => 'Głębokość wcięć';

  @override
  String get cut_depth_mm => 'Głębokość wcięć (mm)';

  @override
  String get tap_wall_to_cut => 'Dotknij ściany, aby przenieść wcięcia';

  @override
  String get overall_length => 'Długość całkowita';

  @override
  String get overall_width => 'Szerokość całkowita';

  @override
  String get overall_length_mm => 'Długość całkowita (mm)';

  @override
  String get overall_width_mm => 'Szerokość całkowita (mm)';

  @override
  String get notch_length => 'Długość wcięcia';

  @override
  String get notch_width => 'Szerokość wcięcia';

  @override
  String get notch_length_mm => 'Długość wcięcia (mm)';

  @override
  String get notch_width_mm => 'Szerokość wcięcia (mm)';

  @override
  String get notch_does_not_fit => 'Wcięcie nie zostawia pomieszczenia';

  @override
  String row_steps_at_notch(int number) {
    return 'Rząd $number przechodzi przez wycięty narożnik: panele na jego końcu wycina się wokół niego, kształt na rysunku';
  }

  @override
  String get tap_corner_to_cut => 'Dotknij wyciętego narożnika';

  @override
  String get diagonal_not_for_l_shape =>
      'Układanie po skosie nie jest jeszcze obsługiwane w pomieszczeniu w kształcie litery L';

  @override
  String get corner_top_left => 'Lewy górny';

  @override
  String get corner_top_right => 'Prawy górny';

  @override
  String get corner_bottom_right => 'Prawy dolny';

  @override
  String get corner_bottom_left => 'Lewy dolny';

  @override
  String get wall_top => 'Górna ściana';

  @override
  String get wall_right => 'Prawa ściana';

  @override
  String get wall_bottom => 'Dolna ściana';

  @override
  String get wall_left => 'Lewa ściana';

  @override
  String get pieces_per_package => 'Sztuk w paczce';

  @override
  String get laying => 'Układanie';

  @override
  String get laying_direction => 'Kierunek układania';

  @override
  String get along_length => 'Wzdłuż długości';

  @override
  String get along_width => 'Wzdłuż szerokości';

  @override
  String get diagonally => 'Po skosie';

  @override
  String get expansion_gap_mm => 'Szczelina dylatacyjna (mm)';

  @override
  String get joint_offset => 'Przesunięcie spoin';

  @override
  String get exact_offset => 'dokładnie';

  @override
  String get joint_offset_mm => 'Przesunięcie spoin (mm)';

  @override
  String get minimal_piece_length => 'Minimalna długość panelu (mm)';

  @override
  String get expansion_gap_in => 'Szczelina dylatacyjna (cal)';

  @override
  String get joint_offset_in => 'Przesunięcie spoin (cal)';

  @override
  String get minimal_piece_length_in => 'Minimalna długość panelu (cal)';

  @override
  String get required_field => 'Pole obowiązkowe';

  @override
  String get incorrect_value => 'Nieprawidłowa wartość';

  @override
  String get minimum => 'Nie mniej niż';

  @override
  String get maximum => 'Nie więcej niż';

  @override
  String get calculate => 'Oblicz';

  @override
  String get result => 'Wynik obliczeń';

  @override
  String get packages_required => 'Potrzebne paczki';

  @override
  String get laying_variants => 'Warianty układania';

  @override
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'panela',
      many: 'paneli',
      few: 'panele',
      one: 'panel',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Schemat układania';

  @override
  String get next => 'Dalej';

  @override
  String get no_laying_variants =>
      'Układanie z podanymi parametrami jest niemożliwe. Spróbuj zmienić przesunięcie spoin lub minimalną długość panelu';

  @override
  String variant(int number) {
    return 'nr $number';
  }

  @override
  String get cut_list => 'Lista cięć';

  @override
  String row(int number) {
    return 'Rząd $number';
  }

  @override
  String get leftovers => 'Pozostałości';

  @override
  String get waste => 'Odpady';
}
