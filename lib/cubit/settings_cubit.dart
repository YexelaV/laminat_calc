import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:floor_calculator/utils/units.dart';

/// The two answers that are not about this floor: what language the app speaks
/// and what units it counts in.
///
/// Apart from the form, and above it. Both are asked once on the onboarding
/// screens, kept on disk, and offered again from the gear on every form screen;
/// both are read by screens that collect nothing — the scheme writes plank
/// sizes in the user's units, and every screen in the app is written in their
/// language. They used to ride along in the form's own state, which made the
/// one field every screen genuinely needed a field of the thing most screens
/// needed nothing from.
class SettingsState extends Equatable {
  final MeasurementSystem system;

  /// The language, or null while the user has not chosen one and the device's
  /// own is good enough. Null is not a default to be filled in: it is what
  /// tells [MaterialApp] to go on resolving against the device, and the first
  /// screen of the app exists to turn it into a choice.
  final Locale? locale;

  const SettingsState({
    this.system = MeasurementSystem.metric,
    this.locale,
  });

  SettingsState copyWith({MeasurementSystem? system, Locale? locale}) =>
      SettingsState(
        system: system ?? this.system,
        locale: locale ?? this.locale,
      );

  @override
  List<Object?> get props => [system, locale];
}

/// Holds the two settings; writing them to disk is the caller's business.
///
/// The screens that change a setting write it to [SharedPreferences] themselves,
/// where they always did. A cubit that also owned the storage would have to be
/// awaited before the value took effect, and the value taking effect is what the
/// user is looking at.
class SettingsCubit extends Cubit<SettingsState> {
  /// Both answers exist before the first frame — they come off disk in `main` —
  /// so the state starts with them rather than being corrected by an emit
  /// nobody is listening to yet.
  SettingsCubit({
    MeasurementSystem system = MeasurementSystem.metric,
    Locale? locale,
  }) : super(SettingsState(system: system, locale: locale));

  void setSystem(MeasurementSystem system) {
    emit(state.copyWith(system: system));
  }

  void setLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
  }
}
