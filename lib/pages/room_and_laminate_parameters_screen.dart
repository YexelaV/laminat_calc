import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/utils/units.dart';
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
  final lengthInchFocusNode = FocusNode();
  final widthFocusNode = FocusNode();
  final widthInchFocusNode = FocusNode();
  final laminateLengthFocusNode = FocusNode();
  final laminateWidthFocusNode = FocusNode();
  final piecesPerPackageFocusNode = FocusNode();

  // In imperial mode length/width controllers hold feet and the inch
  // controllers hold the remaining inches.
  final lengthController = TextEditingController();
  final lengthInchController = TextEditingController(text: '0');
  final widthController = TextEditingController();
  final widthInchController = TextEditingController(text: '0');
  final laminateLengthController = TextEditingController();
  final laminateWidthController = TextEditingController();
  final piecesPerPackageController = TextEditingController();

  @override
  void dispose() {
    lengthController.dispose();
    lengthInchController.dispose();
    widthController.dispose();
    widthInchController.dispose();
    laminateLengthController.dispose();
    laminateWidthController.dispose();
    piecesPerPackageController.dispose();
    lengthFocusNode.dispose();
    lengthInchFocusNode.dispose();
    widthFocusNode.dispose();
    widthInchFocusNode.dispose();
    laminateLengthFocusNode.dispose();
    laminateWidthFocusNode.dispose();
    piecesPerPackageFocusNode.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  // Rewrites field texts from the canonical state (meters/mm) so already
  // entered values survive a unit switch.
  void switchSystem(BuildContext context, MeasurementSystem system, CalculateState state) {
    void setRoomField(
        double? meters, TextEditingController main, TextEditingController inchPart) {
      if (meters == null) {
        main.clear();
        inchPart.text = '0';
        return;
      }
      if (system == MeasurementSystem.metric) {
        main.text = '${(meters * 1000).round()}';
      } else {
        final totalInches = meters * 1000 / MM_PER_INCH;
        final feet = totalInches ~/ 12;
        main.text = '$feet';
        inchPart.text = (totalInches - feet * 12).toStringAsFixed(1);
      }
    }

    void setMmField(int? mm, TextEditingController controller) {
      if (mm == null) {
        controller.clear();
      } else {
        controller.text = formatSize(mm, system);
      }
    }

    setRoomField(state.roomLength, lengthController, lengthInchController);
    setRoomField(state.roomWidth, widthController, widthInchController);
    setMmField(state.laminateLength, laminateLengthController);
    setMmField(state.laminateWidth, laminateWidthController);
    context.read<CalculateCubit>().setMeasurementSystem(system);
  }

  void setRoomFromImperial(BuildContext context) {
    final lengthFeet = _parse(lengthController);
    final lengthInches = _parse(lengthInchController);
    if (lengthFeet != null && lengthInches != null) {
      context.read<CalculateCubit>().setRoomLength(feetInchesToMeters(lengthFeet, lengthInches));
    }
    final widthFeet = _parse(widthController);
    final widthInches = _parse(widthInchController);
    if (widthFeet != null && widthInches != null) {
      context.read<CalculateCubit>().setRoomWidth(feetInchesToMeters(widthFeet, widthInches));
    }
  }

  bool areAllFieldsValid(BuildContext context, MeasurementSystem system) {
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
    final bool lengthValid;
    final bool widthValid;
    final bool laminateLengthValid;
    final bool laminateWidthValid;
    if (system == MeasurementSystem.metric) {
      lengthValid = Validators.sizeValidator(
              context, lengthValue, MIN_ROOM_MM, MAX_LENGTH_MM, appStrings.mm) ==
          null;
      widthValid = Validators.sizeValidator(
              context, widthValue, MIN_ROOM_MM, MAX_WIDTH_MM, appStrings.mm) ==
          null;
      laminateLengthValid = Validators.sizeValidator(
              context, laminateLengthValue, MIN_PLANK_LENGTH, MAX_PLANK_LENGTH, appStrings.mm) ==
          null;
      laminateWidthValid = Validators.sizeValidator(
              context, laminateWidthValue, MIN_PLANK_WIDTH, MAX_PLANK_WIDTH, appStrings.mm) ==
          null;
    } else {
      final lengthInchValue = lengthInchController.text.trim();
      final widthInchValue = widthInchController.text.trim();
      if (lengthInchValue.isEmpty || widthInchValue.isEmpty) return false;
      lengthValid = Validators.sizeValidator(context, lengthValue, MIN_ROOM_FT,
                  (MAX_LENGTH / M_PER_FOOT).floor(), appStrings.ft) ==
              null &&
          Validators.sizeValidator(
                  context, lengthInchValue, 0, MAX_INCHES_IN_FOOT, appStrings.inch) ==
              null;
      widthValid = Validators.sizeValidator(context, widthValue, MIN_ROOM_FT,
                  (MAX_WIDTH / M_PER_FOOT).floor(), appStrings.ft) ==
              null &&
          Validators.sizeValidator(
                  context, widthInchValue, 0, MAX_INCHES_IN_FOOT, appStrings.inch) ==
              null;
      laminateLengthValid = Validators.sizeValidator(context, laminateLengthValue,
              ceilInch(MIN_PLANK_LENGTH), floorInch(MAX_PLANK_LENGTH), appStrings.inch) ==
          null;
      laminateWidthValid = Validators.sizeValidator(context, laminateWidthValue,
              ceilInch(MIN_PLANK_WIDTH), floorInch(MAX_PLANK_WIDTH), appStrings.inch) ==
          null;
    }
    final piecesPerPackageValid = Validators.sizeValidator(
            context, piecesPerPackageValue, MIN_ITEMS_IN_PACK, MAX_ITEMS_IN_PACK, appStrings.pcs) ==
        null;

    return lengthValid &&
        widthValid &&
        laminateLengthValid &&
        laminateWidthValid &&
        piecesPerPackageValid;
  }

  Widget imperialRoomSize(
    BuildContext context, {
    required String title,
    required TextEditingController feetController,
    required FocusNode feetFocusNode,
    required TextEditingController inchController,
    required FocusNode inchFocusNode,
    required FocusNode nextFocusNode,
    required int maxFeet,
  }) {
    final appStrings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 16),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: AppTextFormField(
              controller: feetController,
              focusNode: feetFocusNode,
              nextFocusNode: inchFocusNode,
              labelText: appStrings.ft,
              validator: (value) => Validators.sizeValidator(
                  context, value ?? '', MIN_ROOM_FT, maxFeet, appStrings.ft),
              callback: (value) => setRoomFromImperial(context),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: AppTextFormField(
              controller: inchController,
              focusNode: inchFocusNode,
              nextFocusNode: nextFocusNode,
              labelText: appStrings.inch,
              validator: (value) => Validators.sizeValidator(
                  context, value ?? '', 0, MAX_INCHES_IN_FOOT, appStrings.inch),
              callback: (value) => setRoomFromImperial(context),
            ),
          ),
        ]),
      ],
    );
  }

  Widget titleText(String title, IconData icon, {bool centered = false}) {
    return Row(
      mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
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
                        titleText(appStrings.units, Icons.straighten, centered: true),
                        SizedBox(height: 8),
                        SegmentedButton<MeasurementSystem>(
                          segments: [
                            ButtonSegment(
                              value: MeasurementSystem.metric,
                              label: Text(appStrings.metric_units),
                            ),
                            ButtonSegment(
                              value: MeasurementSystem.imperial,
                              label: Text(appStrings.imperial_units),
                            ),
                          ],
                          selected: {state.system},
                          onSelectionChanged: (selection) =>
                              switchSystem(context, selection.first, state),
                        ),
                        SizedBox(height: 16),
                        titleText(AppStrings.of(context).room, Icons.home_filled),
                        if (state.system == MeasurementSystem.metric)
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(
                              child: AppTextFormField(
                                controller: lengthController,
                                focusNode: lengthFocusNode,
                                nextFocusNode: widthFocusNode,
                                labelText: appStrings.length_mm,
                                validator: (value) => Validators.sizeValidator(context, value ?? '',
                                    MIN_ROOM_MM, MAX_LENGTH_MM, AppStrings.of(context).mm),
                                callback: (value) {
                                  context
                                      .read<CalculateCubit>()
                                      .setRoomLength(int.parse(value) / 1000);
                                },
                              ),
                            ),
                            SizedBox(width: 40),
                            Expanded(
                              child: AppTextFormField(
                                controller: widthController,
                                focusNode: widthFocusNode,
                                nextFocusNode: laminateLengthFocusNode,
                                labelText: appStrings.width_mm,
                                validator: (value) => Validators.sizeValidator(context, value ?? '',
                                    MIN_ROOM_MM, MAX_WIDTH_MM, AppStrings.of(context).mm),
                                callback: (value) {
                                  context
                                      .read<CalculateCubit>()
                                      .setRoomWidth(int.parse(value) / 1000);
                                },
                              ),
                            ),
                          ])
                        else ...[
                          imperialRoomSize(
                            context,
                            title: appStrings.length,
                            feetController: lengthController,
                            feetFocusNode: lengthFocusNode,
                            inchController: lengthInchController,
                            inchFocusNode: lengthInchFocusNode,
                            nextFocusNode: widthFocusNode,
                            maxFeet: (MAX_LENGTH / M_PER_FOOT).floor(),
                          ),
                          imperialRoomSize(
                            context,
                            title: appStrings.width,
                            feetController: widthController,
                            feetFocusNode: widthFocusNode,
                            inchController: widthInchController,
                            inchFocusNode: widthInchFocusNode,
                            nextFocusNode: laminateLengthFocusNode,
                            maxFeet: (MAX_WIDTH / M_PER_FOOT).floor(),
                          ),
                        ],
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
                                  labelText: state.system == MeasurementSystem.metric
                                      ? appStrings.length_mm
                                      : appStrings.length_in,
                                  validator: (value) => state.system == MeasurementSystem.metric
                                      ? Validators.sizeValidator(context, value ?? '',
                                          MIN_PLANK_LENGTH, MAX_PLANK_LENGTH, appStrings.mm)
                                      : Validators.sizeValidator(
                                          context,
                                          value ?? '',
                                          ceilInch(MIN_PLANK_LENGTH),
                                          floorInch(MAX_PLANK_LENGTH),
                                          appStrings.inch),
                                  callback: (value) {
                                    context.read<CalculateCubit>().setLaminateLength(
                                        state.system == MeasurementSystem.metric
                                            ? int.parse(value)
                                            : inchToMm(
                                                double.parse(value.replaceAll(',', '.'))));
                                  }),
                            ),
                            SizedBox(width: 40),
                            Expanded(
                              child: AppTextFormField(
                                controller: laminateWidthController,
                                focusNode: laminateWidthFocusNode,
                                nextFocusNode: piecesPerPackageFocusNode,
                                labelText: state.system == MeasurementSystem.metric
                                    ? appStrings.width_mm
                                    : appStrings.width_in,
                                validator: (value) => state.system == MeasurementSystem.metric
                                    ? Validators.sizeValidator(context, value ?? '',
                                        MIN_PLANK_WIDTH, MAX_PLANK_WIDTH, appStrings.mm)
                                    : Validators.sizeValidator(
                                        context,
                                        value ?? '',
                                        ceilInch(MIN_PLANK_WIDTH),
                                        floorInch(MAX_PLANK_WIDTH),
                                        appStrings.inch),
                                callback: (value) {
                                  context.read<CalculateCubit>().setLaminateWidth(
                                      state.system == MeasurementSystem.metric
                                          ? int.parse(value)
                                          : inchToMm(double.parse(value.replaceAll(',', '.'))));
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
                                color: areAllFieldsValid(context, state.system) ? Colors.blue : Colors.grey,
                              ),
                              child: Text(
                                AppStrings.of(context).next,
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              )),
                          onPressed: areAllFieldsValid(context, state.system)
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
