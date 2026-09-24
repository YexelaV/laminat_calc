import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/di/get_it.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/utils/validators.dart';
import 'package:floor_calculator/widgets/app_background.dart';
import 'package:floor_calculator/widgets/app_text_form_field.dart';
import 'package:floor_calculator/widgets/inch_field.dart';
import 'package:floor_calculator/widgets/room_sketch.dart';
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
  // The opposite walls and the diagonal, on screen only while the room is
  // being measured wall by wall.
  final length2FocusNode = FocusNode();
  final length2InchFocusNode = FocusNode();
  final width2FocusNode = FocusNode();
  final width2InchFocusNode = FocusNode();
  final diagonalFocusNode = FocusNode();
  final diagonalInchFocusNode = FocusNode();
  final laminateLengthFocusNode = FocusNode();
  final laminateWidthFocusNode = FocusNode();
  final piecesPerPackageFocusNode = FocusNode();

  // In imperial mode length/width controllers hold feet and the inch
  // controllers hold the remaining inches.
  final lengthController = TextEditingController();
  final lengthInchController = TextEditingController(text: '0');
  final widthController = TextEditingController();
  final widthInchController = TextEditingController(text: '0');
  final length2Controller = TextEditingController();
  final length2InchController = TextEditingController(text: '0');
  final width2Controller = TextEditingController();
  final width2InchController = TextEditingController(text: '0');
  final diagonalController = TextEditingController();
  final diagonalInchController = TextEditingController(text: '0');
  final laminateLengthController = TextEditingController();
  final laminateWidthController = TextEditingController();
  final piecesPerPackageController = TextEditingController();

  // Every box on the form, so that one list can be listened to and disposed of.
  List<TextEditingController> get _controllers => [
        lengthController,
        lengthInchController,
        widthController,
        widthInchController,
        length2Controller,
        length2InchController,
        width2Controller,
        width2InchController,
        diagonalController,
        diagonalInchController,
        laminateLengthController,
        laminateWidthController,
        piecesPerPackageController,
      ];

  @override
  void initState() {
    super.initState();
    // The Next button is decided from what is in the boxes, and a value a field
    // rejects never reaches the state — so without this the button would stay
    // as it was while the box under it went red. It matters most for the
    // diagonal, whose own bounds move as the walls are typed.
    for (final controller in _controllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_onFieldChanged);
    }
    lengthController.dispose();
    lengthInchController.dispose();
    widthController.dispose();
    widthInchController.dispose();
    length2Controller.dispose();
    length2InchController.dispose();
    width2Controller.dispose();
    width2InchController.dispose();
    diagonalController.dispose();
    diagonalInchController.dispose();
    laminateLengthController.dispose();
    laminateWidthController.dispose();
    piecesPerPackageController.dispose();
    lengthFocusNode.dispose();
    lengthInchFocusNode.dispose();
    widthFocusNode.dispose();
    widthInchFocusNode.dispose();
    length2FocusNode.dispose();
    length2InchFocusNode.dispose();
    width2FocusNode.dispose();
    width2InchFocusNode.dispose();
    diagonalFocusNode.dispose();
    diagonalInchFocusNode.dispose();
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
    setRoomField(state.roomLength2, length2Controller, length2InchController);
    setRoomField(state.roomWidth2, width2Controller, width2InchController);
    setRoomField(state.roomDiagonal, diagonalController, diagonalInchController);
    setPlankField(state.laminateLength, laminateLengthController);
    setPlankField(state.laminateWidth, laminateWidthController);
  }

  // Turning the walls on fills the second pair and the diagonal with the room
  // already typed, so the form is valid the moment it opens and the user only
  // changes what they actually measured. Someone who never measured across gets
  // exactly the rectangle they had before.
  void toggleUnevenWalls(BuildContext context, bool on) {
    final cubit = context.read<CalculateCubit>();
    final state = cubit.state;
    final length = state.roomLength;
    final width = state.roomWidth;
    if (on && length != null && width != null) {
      cubit.setRoomLength2(state.roomLength2 ?? length);
      cubit.setRoomWidth2(state.roomWidth2 ?? width);
      cubit.setRoomDiagonal(state.roomDiagonal ?? RoomShape.rectangleDiagonal(length, width));
    }
    cubit.setUnevenWalls(on);
    rewriteFieldsFor(cubit.state.system, cubit.state);
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
    void apply(TextEditingController feet, TextEditingController inches, void Function(int) set) {
      final wholeFeet = _parse(feet);
      final restInches = _parse(inches);
      if (wholeFeet != null && restInches != null) set(feetInchesToMm(wholeFeet, restInches));
    }

    final cubit = context.read<CalculateCubit>();
    apply(lengthController, lengthInchController, cubit.setRoomLength);
    apply(widthController, widthInchController, cubit.setRoomWidth);
    apply(length2Controller, length2InchController, cubit.setRoomLength2);
    apply(width2Controller, width2InchController, cubit.setRoomWidth2);
    apply(diagonalController, diagonalInchController, cubit.setRoomDiagonal);
  }

  // What the diagonal field is allowed to be, given the four walls typed so
  // far: the triangle inequality on each half of the room. Asking the shape
  // itself means the number the user is shown is the one that actually closes.
  int diagonalMin(CalculateState state) => RoomShape.minDiagonal(
        lengthNear: state.roomLength ?? MIN_ROOM_MM,
        lengthFar: state.roomLength2 ?? state.roomLength ?? MIN_ROOM_MM,
        widthLeft: state.roomWidth ?? MIN_ROOM_MM,
        widthRight: state.roomWidth2 ?? state.roomWidth ?? MIN_ROOM_MM,
      );

  int diagonalMax(CalculateState state) => RoomShape.maxDiagonal(
        lengthNear: state.roomLength ?? MIN_ROOM_MM,
        lengthFar: state.roomLength2 ?? state.roomLength ?? MIN_ROOM_MM,
        widthLeft: state.roomWidth ?? MIN_ROOM_MM,
        widthRight: state.roomWidth2 ?? state.roomWidth ?? MIN_ROOM_MM,
      );

  // One room measurement, in whichever system: millimetres in one box, or feet
  // and inches in two.
  bool roomSizeValid(
    BuildContext context,
    MeasurementSystem system, {
    required TextEditingController controller,
    required TextEditingController inchController,
    required int minMm,
    required int maxMm,
  }) {
    final appStrings = AppStrings.of(context);
    final value = controller.text.trim();
    if (value.isEmpty) return false;
    if (system == MeasurementSystem.metric) {
      return Validators.sizeValidator(context, value, minMm, maxMm, appStrings.mm) == null;
    }
    final inchValue = inchController.text.trim();
    if (inchValue.isEmpty) return false;
    return Validators.sizeValidator(
                context, value, MIN_ROOM_FT, maxWholeFeet(maxMm), appStrings.ft) ==
            null &&
        Validators.sizeValidator(context, inchValue, 0, MAX_INCHES_IN_FOOT, appStrings.inch) ==
            null;
  }

  bool areAllFieldsValid(BuildContext context, CalculateState state) {
    final system = state.system;
    final laminateLengthValue = laminateLengthController.text.trim();
    final laminateWidthValue = laminateWidthController.text.trim();
    final piecesPerPackageValue = piecesPerPackageController.text.trim();

    if (laminateLengthValue.isEmpty ||
        laminateWidthValue.isEmpty ||
        piecesPerPackageValue.isEmpty) {
      return false;
    }

    final appStrings = AppStrings.of(context);
    if (!roomSizeValid(context, system,
        controller: lengthController,
        inchController: lengthInchController,
        minMm: MIN_ROOM_MM,
        maxMm: MAX_LENGTH_MM)) {
      return false;
    }
    if (!roomSizeValid(context, system,
        controller: widthController,
        inchController: widthInchController,
        minMm: MIN_ROOM_MM,
        maxMm: MAX_WIDTH_MM)) {
      return false;
    }
    if (state.unevenWalls) {
      if (!roomSizeValid(context, system,
          controller: length2Controller,
          inchController: length2InchController,
          minMm: MIN_ROOM_MM,
          maxMm: MAX_LENGTH_MM)) {
        return false;
      }
      if (!roomSizeValid(context, system,
          controller: width2Controller,
          inchController: width2InchController,
          minMm: MIN_ROOM_MM,
          maxMm: MAX_WIDTH_MM)) {
        return false;
      }
      if (!roomSizeValid(context, system,
          controller: diagonalController,
          inchController: diagonalInchController,
          minMm: diagonalMin(state),
          maxMm: diagonalMax(state))) {
        return false;
      }
      // The last word is the outline's, not the fields': every measurement can
      // be in range and still describe no room. In feet and inches it is the
      // only word, because a box of whole feet cannot carry the bound.
      if (state.shape?.problem != null) return false;
    }

    final bool laminateLengthValid;
    final bool laminateWidthValid;
    if (system == MeasurementSystem.metric) {
      laminateLengthValid = Validators.sizeValidator(
              context, laminateLengthValue, MIN_PLANK_LENGTH, MAX_PLANK_LENGTH, appStrings.mm) ==
          null;
      laminateWidthValid = Validators.sizeValidator(
              context, laminateWidthValue, MIN_PLANK_WIDTH, MAX_PLANK_WIDTH, appStrings.mm) ==
          null;
    } else {
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

    return laminateLengthValid && laminateWidthValid && piecesPerPackageValid;
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

  // One room measurement in millimetres. The bounds come in as arguments
  // because the diagonal's are worked out from the walls rather than fixed.
  Widget metricRoomSize(
    BuildContext context, {
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? nextFocusNode,
    required String labelText,
    required int minMm,
    required int maxMm,
    required void Function(int) apply,
  }) =>
      AppTextFormField(
        controller: controller,
        focusNode: focusNode,
        nextFocusNode: nextFocusNode,
        labelText: labelText,
        validator: (value) => Validators.sizeValidator(
            context, value ?? '', minMm, maxMm, AppStrings.of(context).mm),
        callback: (value) => apply(int.parse(value)),
      );

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

  // The switch that turns two numbers into five, the sketch that says which
  // wall is which, and the one thing the fields cannot say on their own: that
  // the measurements close into no room at all.
  Widget unevenWalls(BuildContext context, CalculateState state) {
    final appStrings = AppStrings.of(context);
    final shape = state.shape;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4),
        InkWell(
          onTap: () => toggleUnevenWalls(context, !state.unevenWalls),
          child: Row(children: [
            SizedBox(
              width: 40,
              height: 32,
              child: Checkbox(
                value: state.unevenWalls,
                onChanged: (on) => toggleUnevenWalls(context, on ?? false),
              ),
            ),
            Flexible(
              child: Text(
                appStrings.uneven_walls,
                style: TextStyle(color: Colors.black.withValues(alpha: 0.8), fontSize: 15),
              ),
            ),
          ]),
        ),
        if (state.unevenWalls && shape != null) ...[
          RoomSketch(shape: shape, system: state.system),
          if (shape.problem != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                appStrings.walls_do_not_close,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
        ],
      ],
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
                                child: metricRoomSize(
                                  context,
                                  controller: lengthController,
                                  focusNode: lengthFocusNode,
                                  nextFocusNode: widthFocusNode,
                                  labelText: state.unevenWalls
                                      ? appStrings.wall_length_mm(1)
                                      : appStrings.length_mm,
                                  minMm: MIN_ROOM_MM,
                                  maxMm: MAX_LENGTH_MM,
                                  apply: context.read<CalculateCubit>().setRoomLength,
                                ),
                              ),
                              SizedBox(width: _GAP),
                              Expanded(
                                child: metricRoomSize(
                                  context,
                                  controller: widthController,
                                  focusNode: widthFocusNode,
                                  nextFocusNode: state.unevenWalls
                                      ? length2FocusNode
                                      : laminateLengthFocusNode,
                                  labelText: state.unevenWalls
                                      ? appStrings.wall_width_mm(1)
                                      : appStrings.width_mm,
                                  minMm: MIN_ROOM_MM,
                                  maxMm: MAX_WIDTH_MM,
                                  apply: context.read<CalculateCubit>().setRoomWidth,
                                ),
                              ),
                            ]),
                            if (state.unevenWalls) ...[
                              SizedBox(height: _GAP),
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(
                                  child: metricRoomSize(
                                    context,
                                    controller: length2Controller,
                                    focusNode: length2FocusNode,
                                    nextFocusNode: width2FocusNode,
                                    labelText: appStrings.wall_length_mm(2),
                                    minMm: MIN_ROOM_MM,
                                    maxMm: MAX_LENGTH_MM,
                                    apply: context.read<CalculateCubit>().setRoomLength2,
                                  ),
                                ),
                                SizedBox(width: _GAP),
                                Expanded(
                                  child: metricRoomSize(
                                    context,
                                    controller: width2Controller,
                                    focusNode: width2FocusNode,
                                    nextFocusNode: diagonalFocusNode,
                                    labelText: appStrings.wall_width_mm(2),
                                    minMm: MIN_ROOM_MM,
                                    maxMm: MAX_WIDTH_MM,
                                    apply: context.read<CalculateCubit>().setRoomWidth2,
                                  ),
                                ),
                              ]),
                              SizedBox(height: _GAP),
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(
                                  child: metricRoomSize(
                                    context,
                                    controller: diagonalController,
                                    focusNode: diagonalFocusNode,
                                    nextFocusNode: laminateLengthFocusNode,
                                    labelText: appStrings.wall_diagonal_mm,
                                    minMm: diagonalMin(state),
                                    maxMm: diagonalMax(state),
                                    apply: context.read<CalculateCubit>().setRoomDiagonal,
                                  ),
                                ),
                                SizedBox(width: _GAP),
                                Spacer(),
                              ]),
                            ],
                          ] else ...[
                            imperialRoomSize(
                              context,
                              title: state.unevenWalls
                                  ? appStrings.wall_length(1)
                                  : appStrings.length,
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
                              title:
                                  state.unevenWalls ? appStrings.wall_width(1) : appStrings.width,
                              feetController: widthController,
                              feetFocusNode: widthFocusNode,
                              inchController: widthInchController,
                              inchFocusNode: widthInchFocusNode,
                              nextFocusNode:
                                  state.unevenWalls ? length2FocusNode : laminateLengthFocusNode,
                              maxFeet: maxWholeFeet(MAX_WIDTH_MM),
                              valueMm: state.roomWidth,
                            ),
                            if (state.unevenWalls) ...[
                              imperialRoomSize(
                                context,
                                title: appStrings.wall_length(2),
                                feetController: length2Controller,
                                feetFocusNode: length2FocusNode,
                                inchController: length2InchController,
                                inchFocusNode: length2InchFocusNode,
                                nextFocusNode: width2FocusNode,
                                maxFeet: maxWholeFeet(MAX_LENGTH_MM),
                                valueMm: state.roomLength2,
                              ),
                              imperialRoomSize(
                                context,
                                title: appStrings.wall_width(2),
                                feetController: width2Controller,
                                feetFocusNode: width2FocusNode,
                                inchController: width2InchController,
                                inchFocusNode: width2InchFocusNode,
                                nextFocusNode: diagonalFocusNode,
                                maxFeet: maxWholeFeet(MAX_WIDTH_MM),
                                valueMm: state.roomWidth2,
                              ),
                              imperialRoomSize(
                                context,
                                title: appStrings.wall_diagonal,
                                feetController: diagonalController,
                                feetFocusNode: diagonalFocusNode,
                                inchController: diagonalInchController,
                                inchFocusNode: diagonalInchFocusNode,
                                nextFocusNode: laminateLengthFocusNode,
                                maxFeet: maxWholeFeet(diagonalMax(state)),
                                valueMm: state.roomDiagonal,
                              ),
                            ],
                          ],
                          unevenWalls(context, state),
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
                            onPressed: areAllFieldsValid(context, state)
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
                                  color: areAllFieldsValid(context, state)
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
