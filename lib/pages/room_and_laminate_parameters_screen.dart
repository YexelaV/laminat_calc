import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/utils/validators.dart';
import 'package:floor_calculator/widgets/app_background.dart';
import 'package:floor_calculator/widgets/app_text_form_field.dart';
import 'package:floor_calculator/widgets/inch_field.dart';
import 'package:floor_calculator/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// One rhythm for the whole form. The labels ride on the field borders now, so
// every title and every row above needs clearance or the label lands on it.
const double _GAP = 12;
const double _SECTION_GAP = 20;

// A room size is three controls wide, so its boxes are sized to their digits
// instead of sharing out the row: '5' in a full-width box reads as a mistake.
const double _NUMBER_FIELD_WIDTH = 72;
const double _INCH_FIELD_WIDTH = _NUMBER_FIELD_WIDTH + INCH_FRACTION_GAP + INCH_FRACTION_WIDTH;

class RoomAndLaminateParametersScreen extends StatefulWidget {
  const RoomAndLaminateParametersScreen({super.key});

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

  // Rewrites the field texts from the canonical state, which is always
  // millimetres, so that values already entered survive a change of units.
  void rewriteFieldsFor(MeasurementSystem system, CalculateState state) {
    void setRoomField(int? mm, TextEditingController main, TextEditingController inchPart) {
      if (mm == null) {
        main.clear();
        inchPart.text = '0';
        return;
      }
      if (system == MeasurementSystem.metric) {
        main.text = '$mm';
      } else {
        main.text = '${wholeFeet(mm)}';
        inchPart.text = formatInches(remainingInches(mm));
      }
    }

    void setPlankField(int? mm, TextEditingController controller) {
      if (mm == null) {
        controller.clear();
      } else {
        controller.text = formatSize(mm, system);
      }
    }

    setRoomField(state.roomLength, lengthController, lengthInchController);
    setRoomField(state.roomWidth, widthController, widthInchController);
    setPlankField(state.laminateLength, laminateLengthController);
    setPlankField(state.laminateWidth, laminateWidthController);
  }

  void openSettings(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SettingsSheet(
          onSystemChanged: (system) {
            final cubit = getIt.get<CalculateCubit>();
            if (system == cubit.state.system) return;
            rewriteFieldsFor(system, cubit.state);
            cubit.setMeasurementSystem(system);
          },
        ),
      );

  double? _parse(TextEditingController controller) => parseInches(controller.text);

  int parseSize(MeasurementSystem system, String value) =>
      system == MeasurementSystem.metric ? int.parse(value) : inchToMm(parseInches(value)!);

  void setRoomFromImperial(BuildContext context) {
    final lengthFeet = _parse(lengthController);
    final lengthInches = _parse(lengthInchController);
    if (lengthFeet != null && lengthInches != null) {
      context.read<CalculateCubit>().setRoomLength(feetInchesToMm(lengthFeet, lengthInches));
    }
    final widthFeet = _parse(widthController);
    final widthInches = _parse(widthInchController);
    if (widthFeet != null && widthInches != null) {
      context.read<CalculateCubit>().setRoomWidth(feetInchesToMm(widthFeet, widthInches));
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
      widthValid =
          Validators.sizeValidator(context, widthValue, MIN_ROOM_MM, MAX_WIDTH_MM, appStrings.mm) ==
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
      lengthValid = Validators.sizeValidator(
                  context, lengthValue, MIN_ROOM_FT, maxWholeFeet(MAX_LENGTH_MM), appStrings.ft) ==
              null &&
          Validators.sizeValidator(
                  context, lengthInchValue, 0, MAX_INCHES_IN_FOOT, appStrings.inch) ==
              null;
      widthValid = Validators.sizeValidator(
                  context, widthValue, MIN_ROOM_FT, maxWholeFeet(MAX_WIDTH_MM), appStrings.ft) ==
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

  // A size typed into several controls needs a name of its own and an echo of
  // what the controls add up to; the boxes below it are then free to be
  // labelled with bare units.
  Widget sizeTitle(String title, String? value) => Row(
        children: [
          Text(title, style: TextStyle(color: Colors.black.withValues(alpha: 0.8), fontSize: 16)),
          // The echo shares the title's line because the form has no room to
          // spare on a short screen.
          if (value != null) ...[
            SizedBox(width: 8),
            Text(
              '= $value',
              style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 14),
            ),
          ],
        ],
      );

  // Millimetres are two boxes side by side. In inches each box carries a
  // fraction picker, so the pair does not fit one row and the sizes are laid
  // out like the room ones instead: a title, an echo and one box to a row.
  List<Widget> plankRows(
    CalculateState state, {
    required Widget length,
    required Widget width,
    required String lengthTitle,
    required String widthTitle,
  }) {
    if (state.system == MeasurementSystem.metric) {
      return [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: length),
          SizedBox(width: _GAP),
          Expanded(child: width),
        ]),
      ];
    }
    String? echo(int? mm) => mm == null ? null : "${formatInches(mm / MM_PER_INCH)}''";
    return [
      sizeTitle(lengthTitle, echo(state.laminateLength)),
      SizedBox(height: _GAP),
      Row(children: [SizedBox(width: _INCH_FIELD_WIDTH, child: length)]),
      SizedBox(height: _GAP),
      sizeTitle(widthTitle, echo(state.laminateWidth)),
      SizedBox(height: _GAP),
      Row(children: [SizedBox(width: _INCH_FIELD_WIDTH, child: width)]),
    ];
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
    required int? valueMm,
  }) {
    final appStrings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _GAP),
        sizeTitle(title, valueMm == null ? null : formatFeetInches(valueMm)),
        SizedBox(height: _GAP),
        // Two or three digits go into each box, so the boxes are sized for
        // that and the row ends where they end.
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: _NUMBER_FIELD_WIDTH,
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
          SizedBox(width: _GAP),
          SizedBox(
            width: _INCH_FIELD_WIDTH,
            child: InchField(
              controller: inchController,
              focusNode: inchFocusNode,
              nextFocusNode: nextFocusNode,
              labelText: appStrings.inch,
              validator: (value) =>
                  Validators.sizeValidator(context, value, 0, MAX_INCHES_IN_FOOT, appStrings.inch),
              callback: (value) => setRoomFromImperial(context),
            ),
          ),
        ]),
      ],
    );
  }

  // The same plank dimension in either system: millimetres are typed whole,
  // inches come with a fraction picker.
  Widget plankSize(
    BuildContext context, {
    required CalculateState state,
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required String labelText,
    required int minMm,
    required int maxMm,
    required void Function(int) apply,
  }) {
    final appStrings = AppStrings.of(context);
    if (state.system == MeasurementSystem.metric) {
      return AppTextFormField(
        controller: controller,
        focusNode: focusNode,
        nextFocusNode: nextFocusNode,
        labelText: labelText,
        validator: (value) =>
            Validators.sizeValidator(context, value ?? '', minMm, maxMm, appStrings.mm),
        callback: (value) => apply(parseSize(state.system, value)),
      );
    }
    return InchField(
      controller: controller,
      focusNode: focusNode,
      nextFocusNode: nextFocusNode,
      labelText: labelText,
      validator: (value) => Validators.sizeValidator(
          context, value, ceilInch(minMm), floorInch(maxMm), appStrings.inch),
      callback: (value) => apply(parseSize(state.system, value)),
    );
  }

  Widget titleText(String title, IconData icon, {Widget? trailing}) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 20).copyWith(color: Colors.blue)),
        SizedBox(width: 8),
        Icon(
          icon,
          size: 20,
          color: Colors.blue,
        ),
        if (trailing != null) ...[Spacer(), trailing],
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
          return AppBackground(
              child: Scaffold(
            backgroundColor: Colors.transparent,
            // Centred while the card fits, scrollable when it does not: the
            // imperial form is two rows taller than the metric one and the
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
                          titleText(
                            AppStrings.of(context).room,
                            Icons.home_filled,
                            // The language and the unit system are answered once
                            // on the way in; this is the only way back to them.
                            trailing: IconButton(
                              icon: Icon(Icons.settings, color: Colors.black54),
                              onPressed: () => openSettings(context),
                              // A default IconButton is 48 high and would make
                              // the title row taller than the section below it.
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints.tightFor(width: 36, height: 36),
                            ),
                          ),
                          if (state.system == MeasurementSystem.metric) ...[
                            SizedBox(height: _GAP),
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(
                                child: AppTextFormField(
                                  controller: lengthController,
                                  focusNode: lengthFocusNode,
                                  nextFocusNode: widthFocusNode,
                                  labelText: appStrings.length_mm,
                                  validator: (value) => Validators.sizeValidator(
                                      context,
                                      value ?? '',
                                      MIN_ROOM_MM,
                                      MAX_LENGTH_MM,
                                      AppStrings.of(context).mm),
                                  callback: (value) {
                                    context.read<CalculateCubit>().setRoomLength(int.parse(value));
                                  },
                                ),
                              ),
                              SizedBox(width: _GAP),
                              Expanded(
                                child: AppTextFormField(
                                  controller: widthController,
                                  focusNode: widthFocusNode,
                                  nextFocusNode: laminateLengthFocusNode,
                                  labelText: appStrings.width_mm,
                                  validator: (value) => Validators.sizeValidator(
                                      context,
                                      value ?? '',
                                      MIN_ROOM_MM,
                                      MAX_WIDTH_MM,
                                      AppStrings.of(context).mm),
                                  callback: (value) {
                                    context.read<CalculateCubit>().setRoomWidth(int.parse(value));
                                  },
                                ),
                              ),
                            ]),
                          ] else ...[
                            imperialRoomSize(
                              context,
                              title: appStrings.length,
                              feetController: lengthController,
                              feetFocusNode: lengthFocusNode,
                              inchController: lengthInchController,
                              inchFocusNode: lengthInchFocusNode,
                              nextFocusNode: widthFocusNode,
                              maxFeet: maxWholeFeet(MAX_LENGTH_MM),
                              valueMm: state.roomLength,
                            ),
                            imperialRoomSize(
                              context,
                              title: appStrings.width,
                              feetController: widthController,
                              feetFocusNode: widthFocusNode,
                              inchController: widthInchController,
                              inchFocusNode: widthInchFocusNode,
                              nextFocusNode: laminateLengthFocusNode,
                              maxFeet: maxWholeFeet(MAX_WIDTH_MM),
                              valueMm: state.roomWidth,
                            ),
                          ],
                          SizedBox(height: _SECTION_GAP),
                          titleText(appStrings.laminate, Icons.horizontal_split_sharp),
                          SizedBox(height: _GAP),
                          ...plankRows(
                            state,
                            lengthTitle: appStrings.length,
                            widthTitle: appStrings.width,
                            length: plankSize(
                              context,
                              state: state,
                              controller: laminateLengthController,
                              focusNode: laminateLengthFocusNode,
                              nextFocusNode: laminateWidthFocusNode,
                              // In inches the box holds one number under a
                              // title of its own, so it is labelled with the
                              // unit, exactly like the room boxes.
                              labelText: state.system == MeasurementSystem.metric
                                  ? appStrings.length_mm
                                  : appStrings.inch,
                              minMm: MIN_PLANK_LENGTH,
                              maxMm: MAX_PLANK_LENGTH,
                              apply: (mm) => context.read<CalculateCubit>().setLaminateLength(mm),
                            ),
                            width: plankSize(
                              context,
                              state: state,
                              controller: laminateWidthController,
                              focusNode: laminateWidthFocusNode,
                              nextFocusNode: piecesPerPackageFocusNode,
                              labelText: state.system == MeasurementSystem.metric
                                  ? appStrings.width_mm
                                  : appStrings.inch,
                              minMm: MIN_PLANK_WIDTH,
                              maxMm: MAX_PLANK_WIDTH,
                              apply: (mm) => context.read<CalculateCubit>().setLaminateWidth(mm),
                            ),
                          ),
                          SizedBox(height: _GAP),
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
                              SizedBox(width: _GAP),
                              // Half a row, like the length field above it: a
                              // pack count is two digits and a box the width of
                              // the card reads as a much longer value.
                              Spacer(),
                            ],
                          ),
                          SizedBox(height: 30),
                          TextButton(
                            onPressed: areAllFieldsValid(context, state.system)
                                ? () {
                                    FocusScope.of(context).unfocus();
                                    context.router.push(LayingParametersRoute());
                                  }
                                : null,
                            child: Container(
                                alignment: Alignment.center,
                                width: 140,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: areAllFieldsValid(context, state.system)
                                      ? Colors.blue
                                      : Colors.grey,
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
