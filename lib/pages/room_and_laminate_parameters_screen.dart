import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/utils/validators.dart';
import 'package:floor_calculator/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RoomAndLaminateParametersScreen extends StatefulWidget {
  @override
  RoomAndLaminateParametersScreenState createState() => RoomAndLaminateParametersScreenState();
}

class RoomAndLaminateParametersScreenState extends State<RoomAndLaminateParametersScreen> {
  final lengthFocusNode = FocusNode();
  final widthFocusNode = FocusNode();
  final lengthFormKey = GlobalKey<FormFieldState>();
  final widthFormKey = GlobalKey<FormFieldState>();

  double? roomLength;

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

    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
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
                        labelText: appStrings.length_m,
                        validator: (value) => Validators.sizeValidator(
                            context, value ?? '', MIN_LENGTH, MAX_LENGTH, AppStrings.of(context).m),
                        callback: (value) => roomLength = double.parse(value ?? ''),
                      ),
                    ),
                    SizedBox(width: 40),
                    Expanded(
                      child: AppTextFormField(
                        formKey: widthFormKey,
                        focusNode: widthFocusNode,
                        labelText: appStrings.width_m,
                        validator: (value) => Validators.sizeValidator(
                            context, value ?? '', MIN_WIDTH, MAX_WIDTH, AppStrings.of(context).m),
                        callback: (value) => roomLength = double.parse(value ?? ''),
                      ),
                    ),
                    //  ),
                    //     Expanded(
                    //         child: textFormField(
                    //       1,
                    //       (value) => (value),
                    //       (String value) => () {},
                    //       AppStrings.of(context).width_m,
                    //     ))
                    //   ],
                    // ),
                    // SizedBox(height: 16),
                    // titleText(AppStrings.of(context).laminate, Icons.horizontal_split_sharp),
                    // Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    //   Expanded(
                    //     child: textFormField(
                    //       2,
                    //       (value) => (value),
                    //       (String value) => () {},
                    //       AppStrings.of(context).length_mm,
                    //     ),
                    //   ),
                    //   SizedBox(width: 40),
                    //   Expanded(
                    //     child: textFormField(
                    //       3,
                    //       (value) => (value),
                    //       (String value) => () {},
                    //       AppStrings.of(context).width_mm,
                    //     ),
                    //   ),
                    // ]),
                    // Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    //   Expanded(
                    //     child: textFormField(
                    //       4,
                    //       (value) => (value),
                    //       (String value) => () {},
                    //       AppStrings.of(context).pieces_per_package,
                    //     ),
                    //   ),
                  ]),
                  SizedBox(height: 20),
                  TextButton(
                      child: Container(
                          alignment: Alignment.center,
                          width: 140,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.blue,
                          ),
                          child: Text(
                            AppStrings.of(context).next,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          )),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        lengthFormKey.currentState?.validate();
                        widthFormKey.currentState?.validate();

                        /*            if (validate) {
                                 Calculation calculation = Calculation(
                                    roomLength: roomLength,
                                    roomWidth: roomWidth,
                                    plankLength: plankLength,
                                    plankWidth: plankWidth,
                                    planksInPack: planksInPack,
                                    price: price,
                                    indent: indent,
                                    minLength: minLength,
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
  }
}
