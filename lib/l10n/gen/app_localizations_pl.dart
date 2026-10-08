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
  String get wall_length_near => 'Długość (góra)';

  @override
  String get wall_length_far => 'Długość (dół)';

  @override
  String get wall_width_left => 'Szerokość (lewa)';

  @override
  String get wall_width_right => 'Szerokość (prawa)';

  @override
  String get wall_length_near_mm => 'Długość (góra) mm';

  @override
  String get wall_length_far_mm => 'Długość (dół) mm';

  @override
  String get wall_width_left_mm => 'Szerokość (lewa) mm';

  @override
  String get wall_width_right_mm => 'Szerokość (prawa) mm';

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
  String get shape_z => 'W kształcie litery Z';

  @override
  String get shape_u => 'W kształcie litery U';

  @override
  String get chamfer_leg => 'Długość ścięcia';

  @override
  String get chamfer_leg_mm => 'Długość ścięcia (mm)';

  @override
  String get chamfer_leg_left => 'Ścięcie z lewej';

  @override
  String get chamfer_leg_left_mm => 'Ścięcie z lewej (mm)';

  @override
  String get chamfer_leg_right => 'Ścięcie z prawej';

  @override
  String get chamfer_leg_right_mm => 'Ścięcie z prawej (mm)';

  @override
  String get chamfer_leg_near => 'Ścięcie u góry';

  @override
  String get chamfer_leg_near_mm => 'Ścięcie u góry (mm)';

  @override
  String get chamfer_leg_far => 'Ścięcie u dołu';

  @override
  String get chamfer_leg_far_mm => 'Ścięcie u dołu (mm)';

  @override
  String get tap_wall_to_cut => 'Dotknij ściany, aby przenieść wcięcia';

  @override
  String get tap_wall_notch => 'Dotknij ściany z wcięciem';

  @override
  String get notch_depth => 'Głębokość wcięcia';

  @override
  String get notch_depth_mm => 'Głębokość wcięcia (mm)';

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
  String notch_length_n(int number) {
    return 'Długość wcięcia $number';
  }

  @override
  String notch_length_n_mm(int number) {
    return 'Długość wcięcia $number (mm)';
  }

  @override
  String notch_width_n(int number) {
    return 'Szerokość wcięcia $number';
  }

  @override
  String get symmetric_cut => 'Symetrycznie';

  @override
  String get stub_length => 'Długość występu';

  @override
  String get stub_length_mm => 'Długość występu (mm)';

  @override
  String get stub_width => 'Szerokość występu';

  @override
  String get stub_width_mm => 'Szerokość występu (mm)';

  @override
  String stub_length_n(int number) {
    return 'Długość występu $number';
  }

  @override
  String stub_length_n_mm(int number) {
    return 'Długość występu $number (mm)';
  }

  @override
  String stub_width_n(int number) {
    return 'Szerokość występu $number';
  }

  @override
  String stub_width_n_mm(int number) {
    return 'Szerokość występu $number (mm)';
  }

  @override
  String notch_width_n_mm(int number) {
    return 'Szerokość wcięcia $number (mm)';
  }

  @override
  String get notch_does_not_fit => 'Wcięcie nie zostawia pomieszczenia';

  @override
  String get notches_overlap => 'Wcięcia nachodzą na siebie';

  @override
  String row_steps_at_notch(int number) {
    return 'Rząd $number przechodzi przez wycięty narożnik: panele na jego końcu wycina się wokół niego, kształt na rysunku';
  }

  @override
  String get tap_corner_to_cut => 'Dotknij wyciętego narożnika';

  @override
  String get tap_corner_notched => 'Dotknij narożnika, który jest wycięty';

  @override
  String get tap_corner_to_move => 'Dotknij narożnika, aby przenieść wcięcia';

  @override
  String get tap_wall_stem => 'Dotknij ściany z występem';

  @override
  String get diagonal_not_for_notch =>
      'Układanie po skosie nie jest jeszcze obsługiwane w pomieszczeniu z wciętym narożnikiem';

  @override
  String get direction_across_notch_only =>
      'Pomieszczenie z wcięciem w ścianie można układać tylko w poprzek tej ściany';

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
  String get laying_direction => 'Kierunek układania';

  @override
  String get expansion_gap => 'Szczelina dylatacyjna';

  @override
  String get min_piece_length => 'Minimalna długość panela';

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
  String whole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'całe',
      one: 'cały',
    );
    return '$_temp0';
  }

  @override
  String get leftovers => 'Pozostałości';

  @override
  String get waste => 'Odpady';
}
