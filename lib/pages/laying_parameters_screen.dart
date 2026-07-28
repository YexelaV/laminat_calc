import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/utils/validators.dart';
import 'package:floor_calculator/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LayingParametersScreen extends StatefulWidget {
  @override
  LayingParametersScreenState createState() => LayingParametersScreenState();
}

class LayingParametersScreenState extends State<LayingParametersScreen> {
  final indentFromWallFocusNode = FocusNode();
  final rowOffsetFocusNode = FocusNode();
  final minimumLaminateLengthFocusNode = FocusNode();

  final indentFromWallController = TextEditingController();
  final rowOffsetController = TextEditingController();
  final minimumLaminateLengthController = TextEditingController();

  @override
  void dispose() {
    indentFromWallController.dispose();
    rowOffsetController.dispose();
    minimumLaminateLengthController.dispose();
    indentFromWallFocusNode.dispose();
    rowOffsetFocusNode.dispose();
    minimumLaminateLengthFocusNode.dispose();
    super.dispose();
  }

  String? indentFromWallValidator(BuildContext context, CalculateState state, String value) {
    final appStrings = AppStrings.of(context);
    return state.system == MeasurementSystem.metric
        ? Validators.sizeValidator(context, value, 0, MAX_INDENT_FROM_WALL, appStrings.mm)
        : Validators.sizeValidator(
            context, value, 0, floorInch(MAX_INDENT_FROM_WALL), appStrings.inch);
  }

  String? rowOffsetValidator(BuildContext context, CalculateState state, String value) {
    final appStrings = AppStrings.of(context);
    final disabled = state.laminateLength == null;
    final rangeError = state.system == MeasurementSystem.metric
        ? Validators.sizeValidator(context, value, MIN_ROW_OFFSET, rowOffsetMax(state),
            appStrings.mm,
            disabled: disabled)
        : Validators.sizeValidator(context, value, ceilInch(MIN_ROW_OFFSET),
            floorInch(rowOffsetMax(state)), appStrings.inch,
            disabled: disabled);
    if (rangeError != null || disabled) return rangeError;
    final length = rowLength(state);
    final rows = numberOfRowsFor(state);
    final laminateLength = state.laminateLength;
    if (length == null || rows == null || laminateLength == null) return null;
    final offset = parseSize(state, value);
    if (maxMinimumLaminateLengthExact(length, laminateLength, offset, rows) < MIN_MIN_LENGTH) {
      return appStrings.incorrect_value;
    }
    return null;
  }

  String? minimumLaminateLengthValidator(
      BuildContext context, CalculateState state, String value) {
    final appStrings = AppStrings.of(context);
    final disabled = minimumLaminateLengthValidatorDisabled(state);
    final rangeError = state.system == MeasurementSystem.metric
        ? Validators.sizeValidator(context, value, MIN_MIN_LENGTH, minimumLaminateLengthMax(state),
            appStrings.mm,
            disabled: disabled)
        : Validators.sizeValidator(context, value, ceilInch(MIN_MIN_LENGTH),
            floorInch(minimumLaminateLengthMax(state)), appStrings.inch,
            disabled: disabled);
    if (rangeError != null || disabled) return rangeError;
    final length = rowLength(state);
    final rows = numberOfRowsFor(state);
    final laminateLength = state.laminateLength;
    final offset = effectiveRowOffset(state);
    if (length == null || rows == null || laminateLength == null || offset == null) return null;
    // Feasibility is not monotone in the minimum length, so a value inside
    // the min/max range can still be impossible to lay.
    if (!exactOffsetFeasible(length, laminateLength, offset, parseSize(state, value), rows)) {
      return appStrings.incorrect_value;
    }
    return null;
  }

  int parseSize(CalculateState state, String value) => state.system == MeasurementSystem.metric
      ? int.parse(value)
      : inchToMm(double.parse(value.replaceAll(',', '.')));

  bool areAllFieldsValid(BuildContext context, CalculateState state) {
    final indentFromWallValue = indentFromWallController.text.trim();
    final rowOffsetValue = rowOffsetController.text.trim();
    final minimumLaminateLengthValue = minimumLaminateLengthController.text.trim();

    if (indentFromWallValue.isEmpty || minimumLaminateLengthValue.isEmpty) {
      return false;
    }
    if (state.offsetMode == OffsetMode.exact &&
        (rowOffsetValue.isEmpty || rowOffsetValidator(context, state, rowOffsetValue) != null)) {
      return false;
    }

    return indentFromWallValidator(context, state, indentFromWallValue) == null &&
        minimumLaminateLengthValidator(context, state, minimumLaminateLengthValue) == null;
  }

  String offsetValueText(BuildContext context, CalculateState state) {
    final appStrings = AppStrings.of(context);
    final offset = effectiveRowOffset(state);
    if (offset == null) return '';
    return state.system == MeasurementSystem.metric
        ? '= $offset ${appStrings.mm}'
        : '= ${(offset / MM_PER_INCH).toStringAsFixed(1)} ${appStrings.inch}';
  }

  Widget titleText(String title, IconData icon) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 20).copyWith(color: Colors.blue)),
        SizedBox(width: 8),
        Icon(
          icon,
          size: 20,
          color: Colors.blue,
        ),
      ],
    );
  }

  int? rowLength(CalculateState state) {
    final along = state.direction == Direction.length ? state.roomLength : state.roomWidth;
    final indentFromWall = state.indentFromWall;
    if (along == null || indentFromWall == null) return null;
    return (along * 1000 - indentFromWall * 2).toInt();
  }

  int? numberOfRowsFor(CalculateState state) {
    final across = state.direction == Direction.length ? state.roomWidth : state.roomLength;
    final laminateWidth = state.laminateWidth;
    final indentFromWall = state.indentFromWall;
    if (across == null || laminateWidth == null || indentFromWall == null) return null;
    return ((across * 1000 - indentFromWall * 2) / laminateWidth).ceil();
  }

  // The exact offset in mm: derived from the plank length for the fraction
  // modes, entered by the user in the exact mode.
  int? effectiveRowOffset(CalculateState state) {
    final divisor = state.offsetMode.divisor;
    if (divisor == null) return state.rowOffset;
    final laminateLength = state.laminateLength;
    if (laminateLength == null) return null;
    return (laminateLength / divisor).round();
  }

  int rowOffsetMax(CalculateState state) {
    final laminateLength = state.laminateLength;
    if (laminateLength == null) return 0;
    return laminateLength ~/ 2;
  }

  int minimumLaminateLengthMax(CalculateState state) {
    final laminateLength = state.laminateLength;
    final rowOffset = effectiveRowOffset(state);
    final length = rowLength(state);
    final rows = numberOfRowsFor(state);

    if (laminateLength == null || rowOffset == null || length == null || rows == null) {
      return 0;
    }
    return maxMinimumLaminateLengthExact(length, laminateLength, rowOffset, rows);
  }

  bool minimumLaminateLengthValidatorDisabled(CalculateState state) {
    final rowOffset = effectiveRowOffset(state);
    if (state.roomLength == null ||
        state.roomWidth == null ||
        state.laminateLength == null ||
        state.laminateWidth == null ||
        state.indentFromWall == null ||
        rowOffset == null) {
      return true;
    }
    // While the offset itself is out of range, or no minimum length works at
    // all for this offset, the min/max bounds are meaningless, so skip the
    // check (the final calculation reports infeasible configurations).
    return rowOffset < MIN_ROW_OFFSET ||
        rowOffset > rowOffsetMax(state) ||
        minimumLaminateLengthMax(state) < MIN_MIN_LENGTH;
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings.of(context);

    return BlocProvider<CalculateCubit>.value(
      value: getIt.get<CalculateCubit>(),
      child: BlocBuilder<CalculateCubit, CalculateState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Container(
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        titleText(AppStrings.of(context).laying, Icons.branding_watermark),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              appStrings.laying_direction,
                              style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SegmentedButton<Direction>(
                            segments: [
                              ButtonSegment(
                                value: Direction.length,
                                label: Text(appStrings.along_length),
                              ),
                              ButtonSegment(
                                value: Direction.width,
                                label: Text(appStrings.along_width),
                              ),
                            ],
                            selected: {state.direction},
                            onSelectionChanged: (selection) =>
                                context.read<CalculateCubit>().setDirection(selection.first),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextFormField(
                                controller: indentFromWallController,
                                focusNode: indentFromWallFocusNode,
                                nextFocusNode: state.offsetMode == OffsetMode.exact
                                    ? rowOffsetFocusNode
                                    : minimumLaminateLengthFocusNode,
                                labelText: state.system == MeasurementSystem.metric
                                    ? appStrings.expansion_gap_mm
                                    : appStrings.expansion_gap_in,
                                validator: (value) =>
                                    indentFromWallValidator(context, state, value ?? ''),
                                callback: (value) => context
                                    .read<CalculateCubit>()
                                    .setIndentFromWall(parseSize(state, value)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              appStrings.joint_offset,
                              style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SegmentedButton<OffsetMode>(
                            segments: [
                              ButtonSegment(value: OffsetMode.half, label: Text('1/2')),
                              ButtonSegment(value: OffsetMode.third, label: Text('1/3')),
                              ButtonSegment(value: OffsetMode.quarter, label: Text('1/4')),
                              ButtonSegment(
                                value: OffsetMode.exact,
                                label: Text(appStrings.exact_offset),
                              ),
                            ],
                            selected: {state.offsetMode},
                            onSelectionChanged: (selection) =>
                                context.read<CalculateCubit>().setOffsetMode(selection.first),
                          ),
                        ),
                        if (state.offsetMode == OffsetMode.exact)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AppTextFormField(
                                  controller: rowOffsetController,
                                  focusNode: rowOffsetFocusNode,
                                  nextFocusNode: minimumLaminateLengthFocusNode,
                                  labelText: state.system == MeasurementSystem.metric
                                      ? appStrings.joint_offset_mm
                                      : appStrings.joint_offset_in,
                                  validator: (value) =>
                                      rowOffsetValidator(context, state, value ?? ''),
                                  callback: (value) => context
                                      .read<CalculateCubit>()
                                      .setRowOffset(parseSize(state, value)),
                                ),
                              ),
                            ],
                          )
                        else
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                offsetValueText(context, state),
                                style:
                                    TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14),
                              ),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextFormField(
                                controller: minimumLaminateLengthController,
                                focusNode: minimumLaminateLengthFocusNode,
                                labelText: state.system == MeasurementSystem.metric
                                    ? appStrings.minimal_piece_length
                                    : appStrings.minimal_piece_length_in,
                                validator: (value) =>
                                    minimumLaminateLengthValidator(context, state, value ?? ''),
                                callback: (value) => context
                                    .read<CalculateCubit>()
                                    .setMinimumLaminateLength(parseSize(state, value)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        TextButton(
                          child: Container(
                              alignment: Alignment.center,
                              width: 140,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color:
                                    areAllFieldsValid(context, state) ? Colors.blue : Colors.grey,
                              ),
                              child: Text(
                                AppStrings.of(context).next,
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              )),
                          onPressed: areAllFieldsValid(context, state)
                              ? () {
                                  FocusScope.of(context).unfocus();
                                  final roomLength = state.roomLength;
                                  final roomWidth = state.roomWidth;
                                  final laminateLength = state.laminateLength;
                                  final laminateWidth = state.laminateWidth;
                                  final quantityPerPack = state.quantityPerPack;
                                  final indentFromWall = state.indentFromWall;
                                  final rowOffset = effectiveRowOffset(state);
                                  final minimumLaminateLength = state.minimumLaminateLength;

                                  if (roomLength != null &&
                                      roomWidth != null &&
                                      laminateLength != null &&
                                      laminateWidth != null &&
                                      quantityPerPack != null &&
                                      indentFromWall != null &&
                                      rowOffset != null &&
                                      minimumLaminateLength != null) {
                                    final calculation = Calculation(
                                      roomLength: roomLength,
                                      roomWidth: roomWidth,
                                      laminateLength: laminateLength,
                                      laminateWidth: laminateWidth,
                                      planksInPack: quantityPerPack,
                                      price: 0,
                                      indentFromWall: indentFromWall,
                                      minimumLaminateLength: minimumLaminateLength,
                                      rowOffset: rowOffset,
                                      direction: state.direction,
                                    );
                                    final result = calculation.calculate();
                                    if (result.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(AppStrings.of(context).no_laying_variants),
                                        ),
                                      );
                                    } else {
                                      context.router.push(ResultRoute(result: result));
                                    }
                                  }
                                }
                              : null,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
