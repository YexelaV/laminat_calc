import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
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
  final lengthFormKey = GlobalKey<FormFieldState>();
  final widthFormKey = GlobalKey<FormFieldState>();
  final laminateLengthFormKey = GlobalKey<FormFieldState>();
  final laminateWidthFormKey = GlobalKey<FormFieldState>();
  final piecesPerPackageFormKey = GlobalKey<FormFieldState>();

  final calculateCubit = getIt.get<CalculateCubit>();

  double roomLength = 0;
  double roomWidth = 0;
  int laminateLength = 0;
  int laminateWidth = 0;
  int quantityPerPack = 0;

  bool parametersEntered = false;

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
      create: (context) => calculateCubit,
      child: BlocConsumer<CalculateCubit, CalculateState>(
        listener: (context, state) {
          if (parametersEntered != state.roomAndLaminateParametersEntered()) {
            parametersEntered = state.roomAndLaminateParametersEntered();
            setState(() {});
          }
        },
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
                              formKey: lengthFormKey,
                              focusNode: lengthFocusNode,
                              nextFocusNode: widthFocusNode,
                              labelText: appStrings.length_m,
                              validator: (value) => Validators.sizeValidator(context, value ?? '',
                                  MIN_LENGTH, MAX_LENGTH, AppStrings.of(context).m),
                              callback: (value) =>
                                  calculateCubit.setRoomLength(double.parse(value)),
                            ),
                          ),
                          SizedBox(width: 40),
                          Expanded(
                            child: AppTextFormField(
                              formKey: widthFormKey,
                              focusNode: widthFocusNode,
                              nextFocusNode: laminateLengthFocusNode,
                              labelText: appStrings.width_m,
                              validator: (value) => Validators.sizeValidator(context, value ?? '',
                                  MIN_WIDTH, MAX_WIDTH, AppStrings.of(context).m),
                              callback: (value) => calculateCubit.setRoomWidth(double.parse(value)),
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
                                  formKey: laminateLengthFormKey,
                                  focusNode: laminateLengthFocusNode,
                                  nextFocusNode: laminateWidthFocusNode,
                                  labelText: appStrings.length_mm,
                                  validator: (value) => Validators.sizeValidator(
                                      context,
                                      value ?? '',
                                      MIN_PLANK_LENGTH,
                                      MAX_PLANK_LENGTH,
                                      AppStrings.of(context).mm),
                                  callback: (value) =>
                                      calculateCubit.setLaminateLength(int.parse(value))),
                            ),
                            SizedBox(width: 40),
                            Expanded(
                              child: AppTextFormField(
                                formKey: laminateWidthFormKey,
                                focusNode: laminateWidthFocusNode,
                                nextFocusNode: piecesPerPackageFocusNode,
                                labelText: appStrings.width_mm,
                                validator: (value) => Validators.sizeValidator(context, value ?? '',
                                    MIN_PLANK_WIDTH, MAX_PLANK_WIDTH, AppStrings.of(context).mm),
                                callback: (value) =>
                                    calculateCubit.setLaminateWidth(int.parse(value)),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextFormField(
                                formKey: piecesPerPackageFormKey,
                                focusNode: piecesPerPackageFocusNode,
                                labelText: appStrings.pieces_per_package,
                                validator: (value) => Validators.sizeValidator(
                                    context,
                                    value ?? '',
                                    MIN_ITEMS_IN_PACK,
                                    MAX_ITEMS_IN_PACK,
                                    AppStrings.of(context).pcs),
                                callback: (value) =>
                                    calculateCubit.setQuantityPerPack(int.parse(value)),
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
                                  color: parametersEntered ? Colors.blue : Colors.grey,
                                ),
                                child: Text(
                                  AppStrings.of(context).next,
                                  style: TextStyle(color: Colors.white, fontSize: 18),
                                )),
                            onPressed: () {
                              if (parametersEntered) {
                                FocusScope.of(context).unfocus();
                              }
                              // FocusScope.of(context).unfocus();
                              // lengthFormKey.currentState?.validate();
                              // widthFormKey.currentState?.validate();

                              /*            if (validate) {
                                           Calculation calculation = Calculation(
                                              roomLength: roomLength,
                                              roomWidth: roomWidth,
                                              laminateLength: laminateLength,
                                              laminateWidth: laminateWidth,
                                              planksInPack: planksInPack,
                                              price: price,
                                              indentFromWall: indentFromWall,
                                              minimumLaminateLength: minimumLaminateLength,
                                              rowOffset: rowOffset,
                                              direction: Direction.length,
                                            );
                                            final result = calculation.calculate();
          
                                            Navigator.of(context).push(
                                                CupertinoPageRoute(builder: (context) => ResultPage(result)));
                                          }*/
                            })
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
