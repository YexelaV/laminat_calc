import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:flutter/material.dart';

class Validators {
  Validators._();

  static String? sizeValidator(
      BuildContext context, String value, minValue, maxValue, String measure,
      {bool disabled = false}) {
    final appStrings = AppStrings.of(context);
    // Inch fields carry a fraction ('47 7/8'); every other measure is a plain
    // number, so the measure label is what decides how the value reads.
    final inches = measure == appStrings.inch;
    final parsed = inches ? parseInches(value) : double.tryParse(value.replaceAll(',', '.'));

    final result = emptyValidator(context, value, parsed);
    if (disabled || result != null) {
      return result;
    }
    if (measure == appStrings.mm || measure == appStrings.pcs) {
      if (int.tryParse(value) == null) {
        return appStrings.incorrect_value;
      }
    }
    if (parsed! > maxValue) {
      return ("${appStrings.maximum} ${_bound(maxValue, inches)} $measure");
    }
    if (parsed < minValue) {
      return ("${appStrings.minimum} ${_bound(minValue, inches)} $measure");
    }
    return null;
  }

  static String _bound(num value, bool inches) => inches ? formatInches(value) : '$value';

  static String? emptyValidator(BuildContext context, String value, [double? parsed]) {
    if (value.trim().isEmpty) {
      return AppStrings.of(context).required_field;
    }
    final number = parsed ?? double.tryParse(value.replaceAll(',', '.'));
    if (number == null || number < 0) {
      return AppStrings.of(context).incorrect_value;
    }
    return null;
  }
}
