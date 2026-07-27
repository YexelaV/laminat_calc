import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/router/app_router.dart';
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

  bool areAllFieldsValid(BuildContext context, CalculateState state) {
    final indentFromWallValue = indentFromWallController.text.trim();
    final rowOffsetValue = rowOffsetController.text.trim();
    final minimumLaminateLengthValue = minimumLaminateLengthController.text.trim();

    if (indentFromWallValue.isEmpty ||
        rowOffsetValue.isEmpty ||
        minimumLaminateLengthValue.isEmpty) {
      return false;
    }

    final appStrings = AppStrings.of(context);
    final indentFromWallValid = Validators.sizeValidator(
            context, indentFromWallValue, 0, MAX_INDENT_FROM_WALL, appStrings.mm) ==
        null;
    final rowOffsetValid = Validators.sizeValidator(
            context, rowOffsetValue, MIN_ROW_OFFSET, rowOffsetMax(state), appStrings.mm,
            disabled: state.laminateLength == null) ==
        null;
    final minimumLaminateLengthValid = Validators.sizeValidator(context, minimumLaminateLengthValue,
            MIN_MIN_LENGTH, minimumLaminateLengthMax(state), appStrings.mm,
            disabled: minimumLaminateLengthValidatorDisabled(state)) ==
        null;

    return indentFromWallValid && rowOffsetValid && minimumLaminateLengthValid;
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

  int rowOffsetMax(CalculateState state) {
    final laminateLength = state.laminateLength;
    if (laminateLength == null) return 0;
    final length = rowLength(state);
    if (length == null) return laminateLength ~/ 2;
    return maxRowOffset(length, laminateLength, MIN_MIN_LENGTH);
  }

  int minimumLaminateLengthMax(CalculateState state) {
    final laminateLength = state.laminateLength;
    final rowOffset = state.rowOffset;
    final length = rowLength(state);

    if (laminateLength == null || rowOffset == null || length == null) {
      return 0;
    }
    return maxMinimumLaminateLength(length, laminateLength, rowOffset);
  }

  bool minimumLaminateLengthValidatorDisabled(CalculateState state) {
    final rowOffset = state.rowOffset;
    if (state.roomLength == null ||
        state.roomWidth == null ||
        state.laminateLength == null ||
        state.indentFromWall == null ||
        rowOffset == null) {
      return true;
    }
    // While the row offset itself is out of range its dependent bounds are
    // meaningless, so skip the min/max check until the offset is fixed.
    return rowOffset < MIN_ROW_OFFSET || rowOffset > rowOffsetMax(state);
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
                        SegmentedButton<Direction>(
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextFormField(
                                controller: indentFromWallController,
                                focusNode: indentFromWallFocusNode,
                                nextFocusNode: rowOffsetFocusNode,
                                labelText: appStrings.expansion_gap_mm,
                                validator: (value) => Validators.sizeValidator(context, value ?? '',
                                    0, MAX_INDENT_FROM_WALL, AppStrings.of(context).mm),
                                callback: (value) => context
                                    .read<CalculateCubit>()
                                    .setIndentFromWall(int.parse(value)),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextFormField(
                                controller: rowOffsetController,
                                focusNode: rowOffsetFocusNode,
                                nextFocusNode: minimumLaminateLengthFocusNode,
                                labelText: appStrings.joint_offset_mm,
                                validator: (value) => Validators.sizeValidator(context, value ?? '',
                                    MIN_ROW_OFFSET, rowOffsetMax(state), AppStrings.of(context).mm,
                                    disabled: state.laminateLength == null),
                                callback: (value) =>
                                    context.read<CalculateCubit>().setRowOffset(int.parse(value)),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextFormField(
                                controller: minimumLaminateLengthController,
                                focusNode: minimumLaminateLengthFocusNode,
                                labelText: appStrings.minimal_piece_length,
                                validator: (value) => Validators.sizeValidator(
                                    context,
                                    value ?? '',
                                    MIN_MIN_LENGTH,
                                    minimumLaminateLengthMax(state),
                                    AppStrings.of(context).mm,
                                    disabled: minimumLaminateLengthValidatorDisabled(state)),
                                callback: (value) => context
                                    .read<CalculateCubit>()
                                    .setMinimumLaminateLength(int.parse(value)),
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
                                  final rowOffset = state.rowOffset;
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
