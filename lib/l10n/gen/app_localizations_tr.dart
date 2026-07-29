// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get title => 'Laminat Hesaplayıcı';

  @override
  String get mm => 'mm';

  @override
  String get pcs => 'adet';

  @override
  String get ft => 'ft';

  @override
  String get inch => 'inç';

  @override
  String get choose_units => 'Ölçü sistemini seçin';

  @override
  String get metric_system => 'Metrik (mm)';

  @override
  String get imperial_system => 'Emperyal (fit ve inç)';

  @override
  String get settings => 'Ayarlar';

  @override
  String get language => 'Dil';

  @override
  String get room => 'Oda';

  @override
  String get length => 'Uzunluk';

  @override
  String get width => 'Genişlik';

  @override
  String get laminate => 'Laminat';

  @override
  String get length_mm => 'Uzunluk (mm)';

  @override
  String get width_mm => 'Genişlik (mm)';

  @override
  String get pieces_per_package => 'Paketteki adet';

  @override
  String get laying => 'Döşeme';

  @override
  String get laying_direction => 'Döşeme yönü';

  @override
  String get along_length => 'Uzunluk boyunca';

  @override
  String get along_width => 'Genişlik boyunca';

  @override
  String get expansion_gap_mm => 'Genleşme boşluğu (mm)';

  @override
  String get joint_offset => 'Ek yeri kaydırması';

  @override
  String get exact_offset => 'tam';

  @override
  String get joint_offset_mm => 'Ek yeri kaydırması (mm)';

  @override
  String get minimal_piece_length => 'Minimum parça uzunluğu (mm)';

  @override
  String get expansion_gap_in => 'Genleşme boşluğu (inç)';

  @override
  String get joint_offset_in => 'Ek yeri kaydırması (inç)';

  @override
  String get minimal_piece_length_in => 'Minimum parça uzunluğu (inç)';

  @override
  String get required_field => 'Zorunlu alan';

  @override
  String get incorrect_value => 'Geçersiz değer';

  @override
  String get minimum => 'En az';

  @override
  String get maximum => 'En fazla';

  @override
  String get calculate => 'Hesapla';

  @override
  String get result => 'Hesaplama sonucu';

  @override
  String get packages_required => 'Gereken paket sayısı';

  @override
  String get laying_variants => 'Döşeme seçenekleri';

  @override
  String panels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'parça',
      one: 'parça',
    );
    return '$_temp0';
  }

  @override
  String get laying_scheme => 'Döşeme şeması';

  @override
  String get next => 'İleri';

  @override
  String get no_laying_variants =>
      'Bu parametrelerle döşeme mümkün değil. Ek yeri kaydırmasını veya minimum parça uzunluğunu değiştirmeyi deneyin';

  @override
  String variant(int number) {
    return 'No. $number';
  }

  @override
  String get cut_list => 'Kesim listesi';

  @override
  String row(int number) {
    return 'Sıra $number';
  }

  @override
  String get leftovers => 'Artan parçalar';

  @override
  String get waste => 'Fire';
}
