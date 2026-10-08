import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bg.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bg'),
    Locale('cs'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('sv'),
    Locale('tr')
  ];

  /// No description provided for @title.
  ///
  /// In ru, this message translates to:
  /// **'Калькулятор Ламината'**
  String get title;

  /// No description provided for @mm.
  ///
  /// In ru, this message translates to:
  /// **'мм'**
  String get mm;

  /// No description provided for @pcs.
  ///
  /// In ru, this message translates to:
  /// **'шт'**
  String get pcs;

  /// No description provided for @ft.
  ///
  /// In ru, this message translates to:
  /// **'фут'**
  String get ft;

  /// No description provided for @inch.
  ///
  /// In ru, this message translates to:
  /// **'дюйм'**
  String get inch;

  /// No description provided for @choose_units.
  ///
  /// In ru, this message translates to:
  /// **'Выберите систему измерений'**
  String get choose_units;

  /// No description provided for @metric_system.
  ///
  /// In ru, this message translates to:
  /// **'Метрическая (мм)'**
  String get metric_system;

  /// No description provided for @imperial_system.
  ///
  /// In ru, this message translates to:
  /// **'Имперская (футы и дюймы)'**
  String get imperial_system;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @room.
  ///
  /// In ru, this message translates to:
  /// **'Помещение'**
  String get room;

  /// No description provided for @length.
  ///
  /// In ru, this message translates to:
  /// **'Длина'**
  String get length;

  /// No description provided for @width.
  ///
  /// In ru, this message translates to:
  /// **'Ширина'**
  String get width;

  /// No description provided for @laminate.
  ///
  /// In ru, this message translates to:
  /// **'Ламинат'**
  String get laminate;

  /// No description provided for @length_mm.
  ///
  /// In ru, this message translates to:
  /// **'Длина (мм)'**
  String get length_mm;

  /// No description provided for @width_mm.
  ///
  /// In ru, this message translates to:
  /// **'Ширина (мм)'**
  String get width_mm;

  /// No description provided for @uneven_walls.
  ///
  /// In ru, this message translates to:
  /// **'Стены разной длины'**
  String get uneven_walls;

  /// No description provided for @wall_length_near.
  ///
  /// In ru, this message translates to:
  /// **'Длина (верх)'**
  String get wall_length_near;

  /// No description provided for @wall_length_far.
  ///
  /// In ru, this message translates to:
  /// **'Длина (низ)'**
  String get wall_length_far;

  /// No description provided for @wall_width_left.
  ///
  /// In ru, this message translates to:
  /// **'Ширина (слева)'**
  String get wall_width_left;

  /// No description provided for @wall_width_right.
  ///
  /// In ru, this message translates to:
  /// **'Ширина (справа)'**
  String get wall_width_right;

  /// No description provided for @wall_length_near_mm.
  ///
  /// In ru, this message translates to:
  /// **'Длина (верх) мм'**
  String get wall_length_near_mm;

  /// No description provided for @wall_length_far_mm.
  ///
  /// In ru, this message translates to:
  /// **'Длина (низ) мм'**
  String get wall_length_far_mm;

  /// No description provided for @wall_width_left_mm.
  ///
  /// In ru, this message translates to:
  /// **'Ширина (слева) мм'**
  String get wall_width_left_mm;

  /// No description provided for @wall_width_right_mm.
  ///
  /// In ru, this message translates to:
  /// **'Ширина (справа) мм'**
  String get wall_width_right_mm;

  /// No description provided for @wall_diagonal.
  ///
  /// In ru, this message translates to:
  /// **'Диагональ'**
  String get wall_diagonal;

  /// No description provided for @wall_diagonal_mm.
  ///
  /// In ru, this message translates to:
  /// **'Диагональ (мм)'**
  String get wall_diagonal_mm;

  /// No description provided for @walls_do_not_close.
  ///
  /// In ru, this message translates to:
  /// **'Стены не сходятся'**
  String get walls_do_not_close;

  /// No description provided for @room_shape.
  ///
  /// In ru, this message translates to:
  /// **'Форма помещения'**
  String get room_shape;

  /// No description provided for @shape_rectangle.
  ///
  /// In ru, this message translates to:
  /// **'Прямоугольное'**
  String get shape_rectangle;

  /// No description provided for @shape_l.
  ///
  /// In ru, this message translates to:
  /// **'Г-образное'**
  String get shape_l;

  /// No description provided for @shape_chamfer.
  ///
  /// In ru, this message translates to:
  /// **'Срезанный угол'**
  String get shape_chamfer;

  /// No description provided for @shape_chamfer_pair.
  ///
  /// In ru, this message translates to:
  /// **'Два среза'**
  String get shape_chamfer_pair;

  /// No description provided for @shape_t.
  ///
  /// In ru, this message translates to:
  /// **'Т-образное'**
  String get shape_t;

  /// No description provided for @shape_z.
  ///
  /// In ru, this message translates to:
  /// **'Z-образное'**
  String get shape_z;

  /// No description provided for @shape_u.
  ///
  /// In ru, this message translates to:
  /// **'П-образное'**
  String get shape_u;

  /// No description provided for @chamfer_leg.
  ///
  /// In ru, this message translates to:
  /// **'Длина среза'**
  String get chamfer_leg;

  /// No description provided for @chamfer_leg_mm.
  ///
  /// In ru, this message translates to:
  /// **'Длина среза (мм)'**
  String get chamfer_leg_mm;

  /// No description provided for @chamfer_leg_left.
  ///
  /// In ru, this message translates to:
  /// **'Срез слева'**
  String get chamfer_leg_left;

  /// No description provided for @chamfer_leg_left_mm.
  ///
  /// In ru, this message translates to:
  /// **'Срез слева (мм)'**
  String get chamfer_leg_left_mm;

  /// No description provided for @chamfer_leg_right.
  ///
  /// In ru, this message translates to:
  /// **'Срез справа'**
  String get chamfer_leg_right;

  /// No description provided for @chamfer_leg_right_mm.
  ///
  /// In ru, this message translates to:
  /// **'Срез справа (мм)'**
  String get chamfer_leg_right_mm;

  /// No description provided for @chamfer_leg_near.
  ///
  /// In ru, this message translates to:
  /// **'Срез сверху'**
  String get chamfer_leg_near;

  /// No description provided for @chamfer_leg_near_mm.
  ///
  /// In ru, this message translates to:
  /// **'Срез сверху (мм)'**
  String get chamfer_leg_near_mm;

  /// No description provided for @chamfer_leg_far.
  ///
  /// In ru, this message translates to:
  /// **'Срез снизу'**
  String get chamfer_leg_far;

  /// No description provided for @chamfer_leg_far_mm.
  ///
  /// In ru, this message translates to:
  /// **'Срез снизу (мм)'**
  String get chamfer_leg_far_mm;

  /// No description provided for @tap_wall_to_cut.
  ///
  /// In ru, this message translates to:
  /// **'Коснитесь стены, чтобы перенести вырезы'**
  String get tap_wall_to_cut;

  /// No description provided for @tap_wall_notch.
  ///
  /// In ru, this message translates to:
  /// **'Коснитесь стены, в которой вырез'**
  String get tap_wall_notch;

  /// No description provided for @notch_depth.
  ///
  /// In ru, this message translates to:
  /// **'Глубина выреза'**
  String get notch_depth;

  /// No description provided for @notch_depth_mm.
  ///
  /// In ru, this message translates to:
  /// **'Глубина выреза (мм)'**
  String get notch_depth_mm;

  /// No description provided for @overall_length.
  ///
  /// In ru, this message translates to:
  /// **'Общая длина'**
  String get overall_length;

  /// No description provided for @overall_width.
  ///
  /// In ru, this message translates to:
  /// **'Общая ширина'**
  String get overall_width;

  /// No description provided for @overall_length_mm.
  ///
  /// In ru, this message translates to:
  /// **'Общая длина (мм)'**
  String get overall_length_mm;

  /// No description provided for @overall_width_mm.
  ///
  /// In ru, this message translates to:
  /// **'Общая ширина (мм)'**
  String get overall_width_mm;

  /// No description provided for @notch_length.
  ///
  /// In ru, this message translates to:
  /// **'Длина выреза'**
  String get notch_length;

  /// No description provided for @notch_width.
  ///
  /// In ru, this message translates to:
  /// **'Ширина выреза'**
  String get notch_width;

  /// No description provided for @notch_length_mm.
  ///
  /// In ru, this message translates to:
  /// **'Длина выреза (мм)'**
  String get notch_length_mm;

  /// No description provided for @notch_width_mm.
  ///
  /// In ru, this message translates to:
  /// **'Ширина выреза (мм)'**
  String get notch_width_mm;

  /// No description provided for @notch_length_n.
  ///
  /// In ru, this message translates to:
  /// **'Длина выреза {number}'**
  String notch_length_n(int number);

  /// No description provided for @notch_length_n_mm.
  ///
  /// In ru, this message translates to:
  /// **'Длина выреза {number} (мм)'**
  String notch_length_n_mm(int number);

  /// No description provided for @notch_width_n.
  ///
  /// In ru, this message translates to:
  /// **'Ширина выреза {number}'**
  String notch_width_n(int number);

  /// No description provided for @symmetric_cut.
  ///
  /// In ru, this message translates to:
  /// **'Симметрично'**
  String get symmetric_cut;

  /// No description provided for @stub_length.
  ///
  /// In ru, this message translates to:
  /// **'Длина выступа'**
  String get stub_length;

  /// No description provided for @stub_length_mm.
  ///
  /// In ru, this message translates to:
  /// **'Длина выступа (мм)'**
  String get stub_length_mm;

  /// No description provided for @stub_width.
  ///
  /// In ru, this message translates to:
  /// **'Ширина выступа'**
  String get stub_width;

  /// No description provided for @stub_width_mm.
  ///
  /// In ru, this message translates to:
  /// **'Ширина выступа (мм)'**
  String get stub_width_mm;

  /// No description provided for @stub_length_n.
  ///
  /// In ru, this message translates to:
  /// **'Длина выступа {number}'**
  String stub_length_n(int number);

  /// No description provided for @stub_length_n_mm.
  ///
  /// In ru, this message translates to:
  /// **'Длина выступа {number} (мм)'**
  String stub_length_n_mm(int number);

  /// No description provided for @stub_width_n.
  ///
  /// In ru, this message translates to:
  /// **'Ширина выступа {number}'**
  String stub_width_n(int number);

  /// No description provided for @stub_width_n_mm.
  ///
  /// In ru, this message translates to:
  /// **'Ширина выступа {number} (мм)'**
  String stub_width_n_mm(int number);

  /// No description provided for @notch_width_n_mm.
  ///
  /// In ru, this message translates to:
  /// **'Ширина выреза {number} (мм)'**
  String notch_width_n_mm(int number);

  /// No description provided for @notch_does_not_fit.
  ///
  /// In ru, this message translates to:
  /// **'Вырез не оставляет помещения'**
  String get notch_does_not_fit;

  /// No description provided for @notches_overlap.
  ///
  /// In ru, this message translates to:
  /// **'Вырезы перекрывают друг друга'**
  String get notches_overlap;

  /// No description provided for @row_steps_at_notch.
  ///
  /// In ru, this message translates to:
  /// **'Ряд {number} идёт через угол выреза: крайние панели режутся по ступеньке, размер по схеме'**
  String row_steps_at_notch(int number);

  /// No description provided for @tap_corner_to_cut.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на угол, который срезан'**
  String get tap_corner_to_cut;

  /// No description provided for @tap_corner_notched.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на угол, который вырезан'**
  String get tap_corner_notched;

  /// No description provided for @tap_corner_to_move.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на угол, чтобы перенести вырезы'**
  String get tap_corner_to_move;

  /// No description provided for @tap_wall_stem.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на стену с выступом'**
  String get tap_wall_stem;

  /// No description provided for @diagonal_not_for_notch.
  ///
  /// In ru, this message translates to:
  /// **'Диагональная укладка в помещении с вырезом пока не поддерживается'**
  String get diagonal_not_for_notch;

  /// No description provided for @direction_across_notch_only.
  ///
  /// In ru, this message translates to:
  /// **'В помещении с вырезом в стене укладка возможна только поперёк этой стены'**
  String get direction_across_notch_only;

  /// No description provided for @corner_top_left.
  ///
  /// In ru, this message translates to:
  /// **'Верхний левый'**
  String get corner_top_left;

  /// No description provided for @corner_top_right.
  ///
  /// In ru, this message translates to:
  /// **'Верхний правый'**
  String get corner_top_right;

  /// No description provided for @corner_bottom_right.
  ///
  /// In ru, this message translates to:
  /// **'Нижний правый'**
  String get corner_bottom_right;

  /// No description provided for @corner_bottom_left.
  ///
  /// In ru, this message translates to:
  /// **'Нижний левый'**
  String get corner_bottom_left;

  /// No description provided for @wall_top.
  ///
  /// In ru, this message translates to:
  /// **'Верхняя стена'**
  String get wall_top;

  /// No description provided for @wall_right.
  ///
  /// In ru, this message translates to:
  /// **'Правая стена'**
  String get wall_right;

  /// No description provided for @wall_bottom.
  ///
  /// In ru, this message translates to:
  /// **'Нижняя стена'**
  String get wall_bottom;

  /// No description provided for @wall_left.
  ///
  /// In ru, this message translates to:
  /// **'Левая стена'**
  String get wall_left;

  /// No description provided for @pieces_per_package.
  ///
  /// In ru, this message translates to:
  /// **'В упаковке (штук)'**
  String get pieces_per_package;

  /// No description provided for @laying.
  ///
  /// In ru, this message translates to:
  /// **'Укладка'**
  String get laying;

  /// No description provided for @along_length.
  ///
  /// In ru, this message translates to:
  /// **'По длине'**
  String get along_length;

  /// No description provided for @along_width.
  ///
  /// In ru, this message translates to:
  /// **'По ширине'**
  String get along_width;

  /// No description provided for @diagonally.
  ///
  /// In ru, this message translates to:
  /// **'По диагонали'**
  String get diagonally;

  /// No description provided for @expansion_gap_mm.
  ///
  /// In ru, this message translates to:
  /// **'Отступ от стен (мм)'**
  String get expansion_gap_mm;

  /// No description provided for @joint_offset.
  ///
  /// In ru, this message translates to:
  /// **'Смещение стыков'**
  String get joint_offset;

  /// No description provided for @laying_direction.
  ///
  /// In ru, this message translates to:
  /// **'Направление укладки'**
  String get laying_direction;

  /// No description provided for @expansion_gap.
  ///
  /// In ru, this message translates to:
  /// **'Отступ от стен'**
  String get expansion_gap;

  /// No description provided for @min_piece_length.
  ///
  /// In ru, this message translates to:
  /// **'Минимальная длина панели'**
  String get min_piece_length;

  /// No description provided for @exact_offset.
  ///
  /// In ru, this message translates to:
  /// **'точно'**
  String get exact_offset;

  /// No description provided for @joint_offset_mm.
  ///
  /// In ru, this message translates to:
  /// **'Смещение рядов (мм)'**
  String get joint_offset_mm;

  /// No description provided for @minimal_piece_length.
  ///
  /// In ru, this message translates to:
  /// **'Минимальная длина панели (мм)'**
  String get minimal_piece_length;

  /// No description provided for @expansion_gap_in.
  ///
  /// In ru, this message translates to:
  /// **'Отступ от стен (дюйм)'**
  String get expansion_gap_in;

  /// No description provided for @joint_offset_in.
  ///
  /// In ru, this message translates to:
  /// **'Смещение рядов (дюйм)'**
  String get joint_offset_in;

  /// No description provided for @minimal_piece_length_in.
  ///
  /// In ru, this message translates to:
  /// **'Минимальная длина панели (дюйм)'**
  String get minimal_piece_length_in;

  /// No description provided for @required_field.
  ///
  /// In ru, this message translates to:
  /// **'Обязательное поле'**
  String get required_field;

  /// No description provided for @incorrect_value.
  ///
  /// In ru, this message translates to:
  /// **'Некорректное значение'**
  String get incorrect_value;

  /// No description provided for @minimum.
  ///
  /// In ru, this message translates to:
  /// **'Не менее'**
  String get minimum;

  /// No description provided for @maximum.
  ///
  /// In ru, this message translates to:
  /// **'Не более'**
  String get maximum;

  /// No description provided for @calculate.
  ///
  /// In ru, this message translates to:
  /// **'Рассчитать'**
  String get calculate;

  /// No description provided for @result.
  ///
  /// In ru, this message translates to:
  /// **'Результат расчета'**
  String get result;

  /// No description provided for @packages_required.
  ///
  /// In ru, this message translates to:
  /// **'Понадобится упаковок'**
  String get packages_required;

  /// No description provided for @laying_variants.
  ///
  /// In ru, this message translates to:
  /// **'Варианты укладки'**
  String get laying_variants;

  /// No description provided for @panels.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{панель} few{панели} many{панелей} other{панели}}'**
  String panels(int count);

  /// No description provided for @laying_scheme.
  ///
  /// In ru, this message translates to:
  /// **'Схема укладки'**
  String get laying_scheme;

  /// No description provided for @next.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get next;

  /// No description provided for @no_laying_variants.
  ///
  /// In ru, this message translates to:
  /// **'Укладка с заданными параметрами невозможна. Попробуйте изменить смещение рядов или минимальную длину панели'**
  String get no_laying_variants;

  /// No description provided for @variant.
  ///
  /// In ru, this message translates to:
  /// **'№{number}'**
  String variant(int number);

  /// No description provided for @cut_list.
  ///
  /// In ru, this message translates to:
  /// **'Список раскроя'**
  String get cut_list;

  /// No description provided for @row.
  ///
  /// In ru, this message translates to:
  /// **'Ряд {number}'**
  String row(int number);

  /// No description provided for @whole.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{целая} other{целые}}'**
  String whole(int count);

  /// No description provided for @leftovers.
  ///
  /// In ru, this message translates to:
  /// **'Остатки'**
  String get leftovers;

  /// No description provided for @waste.
  ///
  /// In ru, this message translates to:
  /// **'Отходы'**
  String get waste;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'bg',
        'cs',
        'de',
        'en',
        'es',
        'fr',
        'it',
        'pl',
        'pt',
        'ru',
        'sv',
        'tr'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bg':
      return AppLocalizationsBg();
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
