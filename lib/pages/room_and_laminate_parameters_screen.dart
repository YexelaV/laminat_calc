import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/utils/validators.dart';
import 'package:floor_calculator/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoomAndLaminateParametersScreen extends StatefulWidget {
  @override
  RoomAndLaminateParametersScreenState createState() => RoomAndLaminateParametersScreenState();
}

class RoomAndLaminateParametersScreenState extends State<RoomAndLaminateParametersScreen> {
  final lengthFocusNode = FocusNode();
  final widthFocusNode = FocusNode();
  final laminateLengthFocusNode = FocusNode();
  final laminateWidthFocusNode = FocusNode();
  final piecesPerPackageFocusNode = FocusNode();

  final lengthController = TextEditingController();
  final widthController = TextEditingController();
  final laminateLengthController = TextEditingController();
  final laminateWidthController = TextEditingController();
  final piecesPerPackageController = TextEditingController();

  @override
  void dispose() {
    lengthController.dispose();
    widthController.dispose();
    laminateLengthController.dispose();
    laminateWidthController.dispose();
    piecesPerPackageController.dispose();
    lengthFocusNode.dispose();
    widthFocusNode.dispose();
    laminateLengthFocusNode.dispose();
    laminateWidthFocusNode.dispose();
    piecesPerPackageFocusNode.dispose();
    super.dispose();
  }

  bool areAllFieldsValid(BuildContext context) {
    final lengthValue = lengthController.text.trim();
    final widthValue = widthController.text.trim();
    final laminateLengthValue = laminateLengthController.text.trim();
    final laminateWidthValue = laminateWidthController.text.trim();
    final piecesPerPackageValue = piecesPerPackageController.text.trim();

    if (lengthValue.isEmpty ||
        widthValue.isEmpty ||
        laminateLengthValue.isEmpty ||
        laminateWidthValue.isEmpty ||
        piecesPerPackageValue.isEmpty) {
      return false;
    }

    final appStrings = AppStrings.of(context);
    final lengthValid =
        Validators.sizeValidator(context, lengthValue, MIN_LENGTH, MAX_LENGTH, appStrings.m) ==
            null;
    final widthValid =
        Validators.sizeValidator(context, widthValue, MIN_WIDTH, MAX_WIDTH, appStrings.m) == null;
    final laminateLengthValid = Validators.sizeValidator(
            context, laminateLengthValue, MIN_PLANK_LENGTH, MAX_PLANK_LENGTH, appStrings.mm) ==
        null;
    final laminateWidthValid = Validators.sizeValidator(
            context, laminateWidthValue, MIN_PLANK_WIDTH, MAX_PLANK_WIDTH, appStrings.mm) ==
        null;
    final piecesPerPackageValid = Validators.sizeValidator(
            context, piecesPerPackageValue, MIN_ITEMS_IN_PACK, MAX_ITEMS_IN_PACK, appStrings.pcs) ==
        null;

    return lengthValid &&
        widthValid &&
        laminateLengthValid &&
        laminateWidthValid &&
        piecesPerPackageValid;
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

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings.of(context);

    return BlocProvider<CalculateCubit>(
      create: (context) => getIt.get<CalculateCubit>(),
      child: BlocBuilder<CalculateCubit, CalculateState>(
        builder: (context, state) {
          return Scaffold(
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
                        titleText(AppStrings.of(context).room, Icons.home_filled),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: AppTextFormField(
                              controller: lengthController,
                              focusNode: lengthFocusNode,
                              nextFocusNode: widthFocusNode,
                              labelText: appStrings.length_m,
                              validator: (value) => Validators.sizeValidator(context, value ?? '',
                                  MIN_LENGTH, MAX_LENGTH, AppStrings.of(context).m),
                              callback: (value) {
                                context.read<CalculateCubit>().setRoomLength(double.parse(value));
                              },
                            ),
                          ),
                          SizedBox(width: 40),
                          Expanded(
                            child: AppTextFormField(
                              controller: widthController,
                              focusNode: widthFocusNode,
                              nextFocusNode: laminateLengthFocusNode,
                              labelText: appStrings.width_m,
                              validator: (value) => Validators.sizeValidator(context, value ?? '',
                                  MIN_WIDTH, MAX_WIDTH, AppStrings.of(context).m),
                              callback: (value) {
                                context.read<CalculateCubit>().setRoomWidth(double.parse(value));
                              },
                            ),
                          ),
                        ]),
                        SizedBox(height: 16),
                        titleText(AppStrings.of(context).laminate, Icons.horizontal_split_sharp),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextFormField(
                                  controller: laminateLengthController,
                                  focusNode: laminateLengthFocusNode,
                                  nextFocusNode: laminateWidthFocusNode,
                                  labelText: appStrings.length_mm,
                                  validator: (value) => Validators.sizeValidator(
                                      context,
                                      value ?? '',
                                      MIN_PLANK_LENGTH,
                                      MAX_PLANK_LENGTH,
                                      AppStrings.of(context).mm),
                                  callback: (value) {
                                    context
                                        .read<CalculateCubit>()
                                        .setLaminateLength(int.parse(value));
                                  }),
                            ),
                            SizedBox(width: 40),
                            Expanded(
                              child: AppTextFormField(
                                controller: laminateWidthController,
                                focusNode: laminateWidthFocusNode,
                                nextFocusNode: piecesPerPackageFocusNode,
                                labelText: appStrings.width_mm,
                                validator: (value) => Validators.sizeValidator(context, value ?? '',
                                    MIN_PLANK_WIDTH, MAX_PLANK_WIDTH, AppStrings.of(context).mm),
                                callback: (value) {
                                  context.read<CalculateCubit>().setLaminateWidth(int.parse(value));
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextFormField(
                                controller: piecesPerPackageController,
                                focusNode: piecesPerPackageFocusNode,
                                labelText: appStrings.pieces_per_package,
                                validator: (value) => Validators.sizeValidator(
                                    context,
                                    value ?? '',
                                    MIN_ITEMS_IN_PACK,
                                    MAX_ITEMS_IN_PACK,
                                    AppStrings.of(context).pcs),
                                callback: (value) {
                                  context
                                      .read<CalculateCubit>()
                                      .setQuantityPerPack(int.parse(value));
                                },
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
                                color: areAllFieldsValid(context) ? Colors.blue : Colors.grey,
                              ),
                              child: Text(
                                AppStrings.of(context).next,
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              )),
                          onPressed: areAllFieldsValid(context)
                              ? () {
                                  FocusScope.of(context).unfocus();
                                  context.router.push(LayingParametersRoute());
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
