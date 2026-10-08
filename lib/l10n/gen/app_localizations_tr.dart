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
  String get uneven_walls => 'Farklı uzunlukta duvarlar';

  @override
  String get wall_length_near => 'Uzunluk (üst)';

  @override
  String get wall_length_far => 'Uzunluk (alt)';

  @override
  String get wall_width_left => 'Genişlik (sol)';

  @override
  String get wall_width_right => 'Genişlik (sağ)';

  @override
  String get wall_length_near_mm => 'Uzunluk (üst) mm';

  @override
  String get wall_length_far_mm => 'Uzunluk (alt) mm';

  @override
  String get wall_width_left_mm => 'Genişlik (sol) mm';

  @override
  String get wall_width_right_mm => 'Genişlik (sağ) mm';

  @override
  String get wall_diagonal => 'Köşegen';

  @override
  String get wall_diagonal_mm => 'Köşegen (mm)';

  @override
  String get walls_do_not_close => 'Duvarlar kapanmıyor';

  @override
  String get room_shape => 'Oda şekli';

  @override
  String get shape_rectangle => 'Dikdörtgen';

  @override
  String get shape_l => 'L şeklinde';

  @override
  String get shape_chamfer => 'Pahlı köşe';

  @override
  String get shape_chamfer_pair => 'İki pahlı köşe';

  @override
  String get shape_t => 'T biçiminde';

  @override
  String get shape_z => 'Z biçiminde';

  @override
  String get shape_u => 'U biçiminde';

  @override
  String get chamfer_leg => 'Pah uzunluğu';

  @override
  String get chamfer_leg_mm => 'Pah uzunluğu (mm)';

  @override
  String get chamfer_leg_left => 'Soldaki pah';

  @override
  String get chamfer_leg_left_mm => 'Soldaki pah (mm)';

  @override
  String get chamfer_leg_right => 'Sağdaki pah';

  @override
  String get chamfer_leg_right_mm => 'Sağdaki pah (mm)';

  @override
  String get chamfer_leg_near => 'Üstteki pah';

  @override
  String get chamfer_leg_near_mm => 'Üstteki pah (mm)';

  @override
  String get chamfer_leg_far => 'Alttaki pah';

  @override
  String get chamfer_leg_far_mm => 'Alttaki pah (mm)';

  @override
  String get tap_wall_to_cut => 'Girintileri taşımak için bir duvara dokunun';

  @override
  String get tap_wall_notch => 'Girintinin bulunduğu duvara dokunun';

  @override
  String get notch_depth => 'Girinti derinliği';

  @override
  String get notch_depth_mm => 'Girinti derinliği (mm)';

  @override
  String get overall_length => 'Toplam uzunluk';

  @override
  String get overall_width => 'Toplam genişlik';

  @override
  String get overall_length_mm => 'Toplam uzunluk (mm)';

  @override
  String get overall_width_mm => 'Toplam genişlik (mm)';

  @override
  String get notch_length => 'Girinti uzunluğu';

  @override
  String get notch_width => 'Girinti genişliği';

  @override
  String get notch_length_mm => 'Girinti uzunluğu (mm)';

  @override
  String get notch_width_mm => 'Girinti genişliği (mm)';

  @override
  String notch_length_n(int number) {
    return 'Girinti $number uzunluğu';
  }

  @override
  String notch_length_n_mm(int number) {
    return 'Girinti $number uzunluğu (mm)';
  }

  @override
  String notch_width_n(int number) {
    return 'Girinti $number genişliği';
  }

  @override
  String get symmetric_cut => 'Simetrik';

  @override
  String get stub_length => 'Çıkıntı uzunluğu';

  @override
  String get stub_length_mm => 'Çıkıntı uzunluğu (mm)';

  @override
  String get stub_width => 'Çıkıntı genişliği';

  @override
  String get stub_width_mm => 'Çıkıntı genişliği (mm)';

  @override
  String stub_length_n(int number) {
    return 'Çıkıntı uzunluğu $number';
  }

  @override
  String stub_length_n_mm(int number) {
    return 'Çıkıntı uzunluğu $number (mm)';
  }

  @override
  String stub_width_n(int number) {
    return 'Çıkıntı genişliği $number';
  }

  @override
  String stub_width_n_mm(int number) {
    return 'Çıkıntı genişliği $number (mm)';
  }

  @override
  String notch_width_n_mm(int number) {
    return 'Girinti $number genişliği (mm)';
  }

  @override
  String get notch_does_not_fit => 'Girinti odadan yer bırakmıyor';

  @override
  String get notches_overlap => 'Girintiler üst üste biniyor';

  @override
  String row_steps_at_notch(int number) {
    return '$number. sıra kesilen köşeden geçiyor: ucundaki paneller köşenin etrafından kesilir, şekli çizimde';
  }

  @override
  String get tap_corner_to_cut => 'Kesilen köşeye dokunun';

  @override
  String get tap_corner_notched => 'Girintili köşeye dokunun';

  @override
  String get tap_corner_to_move =>
      'Girintileri taşımak için bir köşeye dokunun';

  @override
  String get tap_wall_stem => 'Çıkıntının bulunduğu duvara dokunun';

  @override
  String get diagonal_not_for_notch =>
      'Köşesi girintili odada çapraz döşeme henüz desteklenmiyor';

  @override
  String get direction_across_notch_only =>
      'Duvarında girinti olan bir oda yalnızca o duvara dik olarak döşenebilir';

  @override
  String get corner_top_left => 'Sol üst';

  @override
  String get corner_top_right => 'Sağ üst';

  @override
  String get corner_bottom_right => 'Sağ alt';

  @override
  String get corner_bottom_left => 'Sol alt';

  @override
  String get wall_top => 'Üst duvar';

  @override
  String get wall_right => 'Sağ duvar';

  @override
  String get wall_bottom => 'Alt duvar';

  @override
  String get wall_left => 'Sol duvar';

  @override
  String get pieces_per_package => 'Paketteki adet';

  @override
  String get laying => 'Döşeme';

  @override
  String get along_length => 'Uzunluk boyunca';

  @override
  String get along_width => 'Genişlik boyunca';

  @override
  String get diagonally => 'Çapraz';

  @override
  String get expansion_gap_mm => 'Genleşme boşluğu (mm)';

  @override
  String get joint_offset => 'Ek yeri kaydırması';

  @override
  String get laying_direction => 'Döşeme yönü';

  @override
  String get expansion_gap => 'Genleşme boşluğu';

  @override
  String get min_piece_length => 'Asgari lamel uzunluğu';

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
  String whole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tam',
      one: 'tam',
    );
    return '$_temp0';
  }

  @override
  String get leftovers => 'Artan parçalar';

  @override
  String get waste => 'Fire';
}
