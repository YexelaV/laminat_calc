import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class Validators {
  Validators._();

  static String? sizeValidator(
      BuildContext context, String value, minValue, maxValue, String measure,
      {bool disabled = false}) {
    var result = emptyValidator(context, value);
    if (disabled || result != null) {
      return result;
    }
    if (measure == AppStrings.of(context).mm || measure == AppStrings.of(context).pcs) {
      try {
        int.parse(value);
      } catch (e) {
        return AppStrings.of(context).incorrect_value;
      }
    }
    if (result != null) {
      return result;
    }
    if (double.parse(value) > maxValue) {
      return ("${AppStrings.of(context).maximum} $maxValue $measure");
    }
    if (double.parse(value) < minValue) {
      return ("${AppStrings.of(context).minimum} $minValue $measure");
    }
    return null;
  }

  static String? emptyValidator(BuildContext context, String value) {
    try {
      if (value.isEmpty) {
        return AppStrings.of(context).required_field;
      }
      if (double.parse(value) < 0) {
        return AppStrings.of(context).incorrect_value;
      }
      return null;
    } catch (e) {
      return AppStrings.of(context).incorrect_value;
    }
  }
}
