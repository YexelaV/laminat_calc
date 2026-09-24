import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/row_plan.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/utils/validators.dart';
import 'package:floor_calculator/widgets/app_background.dart';
import 'package:floor_calculator/widgets/app_text_form_field.dart';
import 'package:floor_calculator/widgets/inch_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// The same rhythm as the room form: the labels ride on the field borders, so
// nothing may sit directly above a field.
const double _GAP = 12;
const double _SECTION_GAP = 20;

class LayingParametersScreen extends StatefulWidget {
  const LayingParametersScreen({super.key});

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
        ? Validators.sizeValidator(
            context, value, MIN_ROW_OFFSET, rowOffsetMax(state), appStrings.mm, disabled: disabled)
        : Validators.sizeValidator(context, value, ceilInch(MIN_ROW_OFFSET),
            floorInch(rowOffsetMax(state)), appStrings.inch,
            disabled: disabled);
    if (rangeError != null || disabled) return rangeError;
    // Whether an offset can be laid at all depends on the minimum length, and
    // where the rows are not all one length that pairing has no closed form.
    // The minimum length field asks the engine about the pair, so this one only
    // checks the range.
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

  String? minimumLaminateLengthValidator(BuildContext context, CalculateState state, String value) {
    final appStrings = AppStrings.of(context);
    final disabled = minimumLaminateLengthValidatorDisabled(state);
    final rangeError = state.system == MeasurementSystem.metric
        ? Validators.sizeValidator(
            context, value, MIN_MIN_LENGTH, minimumLaminateLengthMax(state), appStrings.mm,
            disabled: disabled)
        : Validators.sizeValidator(context, value, ceilInch(MIN_MIN_LENGTH),
            floorInch(minimumLaminateLengthMax(state)), appStrings.inch,
            disabled: disabled);
    if (rangeError != null || disabled) return rangeError;
    final plan = planOf(state);
    final shape = state.shape;
    final laminateLength = state.laminateLength;
    final laminateWidth = state.laminateWidth;
    final indentFromWall = state.indentFromWall;
    final offset = effectiveRowOffset(state);
    if (plan == null ||
        shape == null ||
        laminateLength == null ||
        laminateWidth == null ||
        indentFromWall == null ||
        offset == null) {
      return null;
    }
    // Feasibility is not monotone in the minimum length, so a value inside
    // the min/max range can still be impossible to lay.
    //
    // Rows all of one length carry one grid of joints and the answer is a
    // formula. Rows that do not — a 45° layout, or a room whose opposite walls
    // differ — have to be searched for, and the search is the engine's: a
    // second implementation of it would drift from the first.
    if (!plan.isUniform) {
      if (!planFeasible(
        shape: shape,
        indentFromWall: indentFromWall,
        laminateLength: laminateLength,
        laminateWidth: laminateWidth,
        minimumLaminateLength: parseSize(state, value),
        rowOffset: offset,
        direction: state.direction,
      )) {
        return appStrings.incorrect_value;
      }
      return null;
    }
    if (!exactOffsetFeasible(plan.lengths.first, laminateLength, offset, parseSize(state, value),
        plan.numberOfRows)) {
      return appStrings.incorrect_value;
    }
    return null;
  }

  int parseSize(CalculateState state, String value) =>
      state.system == MeasurementSystem.metric ? int.parse(value) : inchToMm(parseInches(value)!);

  // Millimetres are typed whole; inches carry a fraction picker beside the
  // field, and the two halves reach the validator as one string.
  Widget sizeField({
    required CalculateState state,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String labelText,
    required String? Function(String) validator,
    required void Function(int) apply,
  }) {
    if (state.system == MeasurementSystem.metric) {
      return AppTextFormField(
        controller: controller,
        focusNode: focusNode,
        nextFocusNode: nextFocusNode,
        labelText: labelText,
        validator: (value) => validator(value ?? ''),
        callback: (value) => apply(parseSize(state, value)),
      );
    }
    return InchField(
      controller: controller,
      focusNode: focusNode,
      nextFocusNode: nextFocusNode,
      labelText: labelText,
      validator: validator,
      callback: (value) => apply(parseSize(state, value)),
    );
  }

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
        : '= ${formatInches(offset / MM_PER_INCH)} ${appStrings.inch}';
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

  // The rows the room will actually be laid in, asked of the same function the
  // engine asks. Null while a field the geometry needs is still empty.
  //
  // The form used to derive the geometry alongside the engine, in scalars of
  // its own. It cannot any more — a room whose walls differ has no single row
  // length to derive — and it is better off for it: feasibility is not monotone
  // in the minimum plank length, so a millimetre of disagreement between the
  // two used to turn into a green form that then reported no laying variants.
  RowPlan? planOf(CalculateState state) {
    final shape = state.shape;
    final laminateLength = state.laminateLength;
    final laminateWidth = state.laminateWidth;
    final indentFromWall = state.indentFromWall;
    if (shape == null ||
        laminateLength == null ||
        laminateWidth == null ||
        indentFromWall == null) {
      return null;
    }
    if (shape.problem != null) return null;
    return planFor(
      shape: shape,
      indentFromWall: indentFromWall,
      laminateLength: laminateLength,
      laminateWidth: laminateWidth,
      direction: state.direction,
    );
  }

  // Null when there is nothing to give: a field still empty, or rows that are
  // not all of one length — a 45° layout, or a room whose opposite walls differ.
  int? rowLength(CalculateState state) {
    final plan = planOf(state);
    if (plan == null || !plan.isUniform) return null;
    return plan.lengths.first;
  }

  int? numberOfRowsFor(CalculateState state) => planOf(state)?.numberOfRows;

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
    final plan = planOf(state);
    final laminateLength = state.laminateLength;
    final rowOffset = effectiveRowOffset(state);
    if (plan == null || laminateLength == null) return 0;
    // Rows all of one length have a closed form for this; the rest are read off
    // the plan they will actually be laid in.
    if (!plan.isUniform) {
      return maxMinimumLaminateLengthFor(plan: plan, laminateLength: laminateLength);
    }
    if (rowOffset == null) return 0;
    return maxMinimumLaminateLengthExact(
        plan.lengths.first, laminateLength, rowOffset, plan.numberOfRows);
  }

  bool minimumLaminateLengthValidatorDisabled(CalculateState state) {
    final rowOffset = effectiveRowOffset(state);
    if (planOf(state) == null || rowOffset == null) {
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
          return AppBackground(
              child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            // Centred while the card fits, scrollable when it does not: the
            // keyboard takes half the screen away while a field is focused.
            body: Center(
              child: SingleChildScrollView(
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
                                style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.8), fontSize: 16),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SegmentedButton<Direction>(
                              // The tick costs the selected segment about a
                              // character of width, which on a 360 dp phone is
                              // enough to break a word in half. The fill already
                              // says which one is chosen.
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(
                                  value: Direction.length,
                                  label: Text(appStrings.along_length),
                                ),
                                ButtonSegment(
                                  value: Direction.width,
                                  label: Text(appStrings.along_width),
                                ),
                                ButtonSegment(
                                  value: Direction.diagonal,
                                  label: Text(appStrings.diagonally),
                                ),
                              ],
                              selected: {state.direction},
                              onSelectionChanged: (selection) =>
                                  context.read<CalculateCubit>().setDirection(selection.first),
                            ),
                          ),
                          SizedBox(height: _GAP),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: sizeField(
                                  state: state,
                                  controller: indentFromWallController,
                                  focusNode: indentFromWallFocusNode,
                                  nextFocusNode: state.offsetMode == OffsetMode.exact
                                      ? rowOffsetFocusNode
                                      : minimumLaminateLengthFocusNode,
                                  labelText: state.system == MeasurementSystem.metric
                                      ? appStrings.expansion_gap_mm
                                      : appStrings.expansion_gap_in,
                                  validator: (value) =>
                                      indentFromWallValidator(context, state, value),
                                  apply: (mm) =>
                                      context.read<CalculateCubit>().setIndentFromWall(mm),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: _SECTION_GAP),
                          Row(
                            children: [
                              Text(
                                appStrings.joint_offset,
                                style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.8), fontSize: 16),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SegmentedButton<OffsetMode>(
                              showSelectedIcon: false,
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
                          SizedBox(height: _GAP),
                          if (state.offsetMode == OffsetMode.exact)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: sizeField(
                                    state: state,
                                    controller: rowOffsetController,
                                    focusNode: rowOffsetFocusNode,
                                    nextFocusNode: minimumLaminateLengthFocusNode,
                                    labelText: state.system == MeasurementSystem.metric
                                        ? appStrings.joint_offset_mm
                                        : appStrings.joint_offset_in,
                                    validator: (value) => rowOffsetValidator(context, state, value),
                                    apply: (mm) => context.read<CalculateCubit>().setRowOffset(mm),
                                  ),
                                ),
                              ],
                            )
                          else
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                offsetValueText(context, state),
                                style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.6), fontSize: 14),
                              ),
                            ),
                          SizedBox(height: _GAP),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: sizeField(
                                  state: state,
                                  controller: minimumLaminateLengthController,
                                  focusNode: minimumLaminateLengthFocusNode,
                                  labelText: state.system == MeasurementSystem.metric
                                      ? appStrings.minimal_piece_length
                                      : appStrings.minimal_piece_length_in,
                                  validator: (value) =>
                                      minimumLaminateLengthValidator(context, state, value),
                                  apply: (mm) =>
                                      context.read<CalculateCubit>().setMinimumLaminateLength(mm),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30),
                          TextButton(
                            onPressed: areAllFieldsValid(context, state)
                                ? () {
                                    FocusScope.of(context).unfocus();
                                    final shape = state.shape;
                                    final laminateLength = state.laminateLength;
                                    final laminateWidth = state.laminateWidth;
                                    final quantityPerPack = state.quantityPerPack;
                                    final indentFromWall = state.indentFromWall;
                                    final rowOffset = effectiveRowOffset(state);
                                    final minimumLaminateLength = state.minimumLaminateLength;

                                    if (shape != null &&
                                        laminateLength != null &&
                                        laminateWidth != null &&
                                        quantityPerPack != null &&
                                        indentFromWall != null &&
                                        rowOffset != null &&
                                        minimumLaminateLength != null) {
                                      final calculation = Calculation(
                                        shape: shape,
                                        laminateLength: laminateLength,
                                        laminateWidth: laminateWidth,
                                        planksInPack: quantityPerPack,
                                        indentFromWall: indentFromWall,
                                        minimumLaminateLength: minimumLaminateLength,
                                        rowOffset: rowOffset,
                                        direction: state.direction,
                                      );
                                      final result = calculation.calculate();
                                      if (result.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content:
                                                Text(AppStrings.of(context).no_laying_variants),
                                          ),
                                        );
                                      } else {
                                        context.router.push(ResultRoute(result: result));
                                      }
                                    }
                                  }
                                : null,
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
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ));
        },
      ),
    );
  }
}
