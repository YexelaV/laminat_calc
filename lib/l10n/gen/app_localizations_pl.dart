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
  String get units => 'System miar';

  @override
  String get metric_units => 'mm';

  @override
  String get imperial_units => 'ft / cal';

  @override
  String get room => 'Pomieszczenie';

  @override
  String get length => 'Długość';

  @override
  String get width => 'Szerokość';

  @override
  String get length_in => 'Długość (cal)';

  @override
  String get width_in => 'Szerokość (cal)';

  @override
  String get laminate => 'Laminat';

  @override
  String get length_mm => 'Długość (mm)';

  @override
  String get width_mm => 'Szerokość (mm)';

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
}
