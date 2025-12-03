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
            context, indentFromWallValue, 0, MAX_indentFromWall, appStrings.mm) ==
        null;
    final rowOffsetValid = Validators.sizeValidator(context, rowOffsetValue, MIN_ROW_OFFSET,
            ((state.laminateLength ?? 0) / 2).floor(), appStrings.mm,
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

  int minimumLaminateLengthMax(CalculateState state) {
    final roomLength = state.roomLength;
    final roomWidth = state.roomWidth;
    final laminateLength = state.laminateLength;
    final rowOffset = state.rowOffset;
    final indentFromWall = state.indentFromWall;

    if (roomLength == null ||
        roomWidth == null ||
        laminateLength == null ||
        rowOffset == null ||
        indentFromWall == null) {
      return 0;
    }
    final actualLength = (roomLength * 1000 - indentFromWall * 2).toInt();
    final rowLength = actualLength;
    var currentLength = 0;
    while (currentLength + laminateLength < rowLength) {
      currentLength += laminateLength;
    }
    var lastlaminateLength = rowLength - currentLength;
    var rowRemain = rowLength - currentLength + laminateLength;
    if (lastlaminateLength <= laminateLength / 2) {
      return ((rowRemain - rowOffset) / 2).truncate();
    } else {
      return lastlaminateLength - rowOffset;
    }
  }

  bool minimumLaminateLengthValidatorDisabled(CalculateState state) {
    return state.roomLength == null ||
        state.roomWidth == null ||
        state.laminateLength == null ||
        state.indentFromWall == null ||
        state.rowOffset == null;
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
                                    0, MAX_indentFromWall, AppStrings.of(context).mm),
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
                                validator: (value) => Validators.sizeValidator(
                                    context,
                                    value ?? '',
                                    MIN_ROW_OFFSET,
                                    ((state.laminateLength ?? 0) / 2).floor(),
                                    AppStrings.of(context).mm,
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
                                      direction: Direction.length,
                                    );
                                    final result = calculation.calculate();
                                    context.router.push(ResultRoute(result: result));
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
