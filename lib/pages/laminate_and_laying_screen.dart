import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/laminate_cubit.dart';
import 'package:floor_calculator/cubit/laying_cubit.dart';
import 'package:floor_calculator/cubit/room_cubit.dart';
import 'package:floor_calculator/cubit/settings_cubit.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/row_plan.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/utils/validators.dart';
import 'package:floor_calculator/widgets/app_text_form_field.dart';
import 'package:floor_calculator/widgets/inch_field.dart';
import 'package:floor_calculator/widgets/parameters_card.dart';
import 'package:floor_calculator/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// The same rhythm as the room form: the labels ride on the field borders, so
// nothing may sit directly above a field.
//
// Tighter than the room's own, and on purpose. This screen carries both halves
// of what is typed after the room — eight controls where the room has four —
// and the air between them is what decides whether the Next button is on the
// page or under the fold. A label riding a border needs a few pixels over it,
// not a dozen.
const double _GAP = 8;
const double _SECTION_GAP = 14;

/// Between a heading and the control it names. Half the gap between controls,
/// because a heading belongs to what is under it and reads as a stray line when
/// it floats equidistant between the two.
const double _LABEL_GAP = 4;

// An inch box carries a fraction picker beside it, so it is wider than the
// number alone needs.
const double _NUMBER_FIELD_WIDTH = 72;
const double _INCH_FIELD_WIDTH =
    _NUMBER_FIELD_WIDTH + INCH_FRACTION_GAP + INCH_FRACTION_WIDTH;

/// What is being laid and how it goes down: the plank off the carton, then the
/// gap, the joint offset, the shortest offcut and the direction.
///
/// One screen for the two. They were two while the room form still carried the
/// laminate at its foot — splitting the plank off was what got the pack count
/// back above the fold — and once the room had a screen to itself the plank had
/// three boxes on a page of its own. Three boxes do not need a page, and a user
/// typing a floor in reads them off one carton and goes straight on to the gap
/// round the walls; the Next button between them was a step that asked nothing.
///
/// Together they are also honest about what depends on what: every bound on
/// this screen's lower half is worked out from the plank in its upper half, and
/// a plank length changed here moves the offset's ceiling and the shortest
/// offcut's as the digits land.
class LaminateAndLayingScreen extends StatefulWidget {
  const LaminateAndLayingScreen({super.key});

  @override
  LaminateAndLayingScreenState createState() => LaminateAndLayingScreenState();
}

class LaminateAndLayingScreenState extends State<LaminateAndLayingScreen> {
  final lengthFocusNode = FocusNode();
  final widthFocusNode = FocusNode();
  final packFocusNode = FocusNode();
  final indentFromWallFocusNode = FocusNode();
  final rowOffsetFocusNode = FocusNode();
  final minimumLaminateLengthFocusNode = FocusNode();

  final lengthController = TextEditingController();
  final widthController = TextEditingController();
  final packController = TextEditingController();
  final indentFromWallController = TextEditingController();
  final rowOffsetController = TextEditingController();
  final minimumLaminateLengthController = TextEditingController();

  /// Every box on the screen, so that one list can be listened to and disposed
  /// of. The Next button is decided from what is in them, and a value a field
  /// rejects never reaches the state — so without the listener the button would
  /// stay as it was while the box under it went red.
  List<TextEditingController> get _controllers => [
        lengthController,
        widthController,
        packController,
        indentFromWallController,
        rowOffsetController,
        minimumLaminateLengthController,
      ];

  @override
  void initState() {
    super.initState();
    // The screen is reached with the cubits already holding whatever was typed
    // the last time through, and a user who steps back to fix the room must
    // find both halves of this one where they left them. Without it the boxes
    // come back empty, the Next button comes back grey, and six numbers that
    // were never in question have to be typed again.
    rewriteFieldsFor(context.read<SettingsCubit>().state.system);
    for (final controller in _controllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  // Rewrites the field texts from the canonical state, which is always
  // millimetres, so that values already entered survive a change of units.
  void rewriteFieldsFor(MeasurementSystem system) {
    final laminate = context.read<LaminateCubit>().state;
    final laying = context.read<LayingCubit>().state;
    void setField(int? mm, TextEditingController controller) {
      if (mm == null) {
        controller.clear();
      } else {
        controller.text = formatSize(mm, system);
      }
    }

    setField(laminate.laminateLength, lengthController);
    setField(laminate.laminateWidth, widthController);
    final pack = laminate.quantityPerPack;
    if (pack != null) packController.text = '$pack';
    setField(laying.indentFromWall, indentFromWallController);
    setField(laying.rowOffset, rowOffsetController);
    setField(laying.minimumLaminateLength, minimumLaminateLengthController);
  }

  void openSettings(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SettingsSheet(
          onSystemChanged: (system) {
            final settings = context.read<SettingsCubit>();
            if (system == settings.state.system) return;
            // The boxes hold text in the old unit and the cubits hold
            // millimetres, so the text is rewritten before the setting moves.
            rewriteFieldsFor(system);
            settings.setSystem(system);
          },
        ),
      );

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_onFieldChanged);
      controller.dispose();
    }
    lengthFocusNode.dispose();
    widthFocusNode.dispose();
    packFocusNode.dispose();
    indentFromWallFocusNode.dispose();
    rowOffsetFocusNode.dispose();
    minimumLaminateLengthFocusNode.dispose();
    super.dispose();
  }

  String? indentFromWallValidator(BuildContext context, LayingInputs inputs, String value) {
    final appStrings = AppStrings.of(context);
    return inputs.system == MeasurementSystem.metric
        ? Validators.sizeValidator(context, value, 0, MAX_INDENT_FROM_WALL, appStrings.mm)
        : Validators.sizeValidator(
            context, value, 0, floorInch(MAX_INDENT_FROM_WALL), appStrings.inch);
  }

  String? rowOffsetValidator(BuildContext context, LayingInputs inputs, String value) {
    final appStrings = AppStrings.of(context);
    final disabled = inputs.laminateLength == null;
    final rangeError = inputs.system == MeasurementSystem.metric
        ? Validators.sizeValidator(
            context, value, MIN_ROW_OFFSET, rowOffsetMax(inputs), appStrings.mm,
            disabled: disabled)
        : Validators.sizeValidator(context, value, ceilInch(MIN_ROW_OFFSET),
            floorInch(rowOffsetMax(inputs)), appStrings.inch,
            disabled: disabled);
    if (rangeError != null || disabled) return rangeError;
    // Whether an offset can be laid at all depends on the minimum length, and
    // where the rows are not all one length that pairing has no closed form.
    // The minimum length field asks the engine about the pair, so this one only
    // checks the range.
    final length = rowLength(inputs);
    final rows = numberOfRowsFor(inputs);
    final laminateLength = inputs.laminateLength;
    if (length == null || rows == null || laminateLength == null) return null;
    final offset = parseSize(inputs, value);
    if (maxMinimumLaminateLengthExact(length, laminateLength, offset, rows) <
        MIN_MIN_LENGTH) {
      return appStrings.incorrect_value;
    }
    return null;
  }

  String? minimumLaminateLengthValidator(
      BuildContext context, LayingInputs inputs, String value) {
    final appStrings = AppStrings.of(context);
    final disabled = minimumLaminateLengthValidatorDisabled(inputs);
    final rangeError = inputs.system == MeasurementSystem.metric
        ? Validators.sizeValidator(
            context, value, MIN_MIN_LENGTH, minimumLaminateLengthMax(inputs), appStrings.mm,
            disabled: disabled)
        : Validators.sizeValidator(context, value, ceilInch(MIN_MIN_LENGTH),
            floorInch(minimumLaminateLengthMax(inputs)), appStrings.inch,
            disabled: disabled);
    if (rangeError != null || disabled) return rangeError;
    final plan = planOf(inputs);
    final shape = inputs.shape;
    final laminateLength = inputs.laminateLength;
    final laminateWidth = inputs.laminateWidth;
    final indentFromWall = inputs.indentFromWall;
    final offset = effectiveRowOffset(inputs);
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
        minimumLaminateLength: parseSize(inputs, value),
        rowOffset: offset,
        direction: inputs.direction,
      )) {
        return appStrings.incorrect_value;
      }
      return null;
    }
    if (!exactOffsetFeasible(plan.lengths.first, laminateLength, offset,
        parseSize(inputs, value), plan.numberOfRows)) {
      return appStrings.incorrect_value;
    }
    return null;
  }

  int parseSize(LayingInputs inputs, String value) =>
      inputs.system == MeasurementSystem.metric
          ? int.parse(value)
          : inchToMm(parseInches(value)!);

  // Millimetres are typed whole; inches carry a fraction picker beside the
  // field, and the two halves reach the validator as one string.
  Widget sizeField({
    required LayingInputs inputs,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String labelText,
    required String? Function(String) validator,
    required void Function(int) apply,
  }) {
    if (inputs.system == MeasurementSystem.metric) {
      return AppTextFormField(
        controller: controller,
        focusNode: focusNode,
        nextFocusNode: nextFocusNode,
        labelText: labelText,
        validator: (value) => validator(value ?? ''),
        callback: (value) => apply(parseSize(inputs, value)),
      );
    }
    return InchField(
      controller: controller,
      focusNode: focusNode,
      nextFocusNode: nextFocusNode,
      labelText: labelText,
      validator: validator,
      callback: (value) => apply(parseSize(inputs, value)),
    );
  }

  /// Whether the plank is a plank. Its own check rather than a line in
  /// [areAllFieldsValid], because the three boxes above the fold are answered
  /// off a carton and the five below them are answered about the floor, and a
  /// user who has not got to the second half yet should still see the first
  /// half go green.
  bool isLaminateValid(BuildContext context, MeasurementSystem system) {
    final appStrings = AppStrings.of(context);
    final length = lengthController.text.trim();
    final width = widthController.text.trim();
    final pack = packController.text.trim();
    if (length.isEmpty || width.isEmpty || pack.isEmpty) return false;

    final bool lengthValid;
    final bool widthValid;
    if (system == MeasurementSystem.metric) {
      lengthValid = Validators.sizeValidator(
              context, length, MIN_PLANK_LENGTH, MAX_PLANK_LENGTH, appStrings.mm) ==
          null;
      widthValid = Validators.sizeValidator(
              context, width, MIN_PLANK_WIDTH, MAX_PLANK_WIDTH, appStrings.mm) ==
          null;
    } else {
      lengthValid = Validators.sizeValidator(context, length, ceilInch(MIN_PLANK_LENGTH),
              floorInch(MAX_PLANK_LENGTH), appStrings.inch) ==
          null;
      widthValid = Validators.sizeValidator(context, width, ceilInch(MIN_PLANK_WIDTH),
              floorInch(MAX_PLANK_WIDTH), appStrings.inch) ==
          null;
    }
    final packValid = Validators.sizeValidator(
            context, pack, MIN_ITEMS_IN_PACK, MAX_ITEMS_IN_PACK, appStrings.pcs) ==
        null;
    return lengthValid && widthValid && packValid;
  }

  // The same plank dimension in either system: millimetres are typed whole,
  // inches come with a fraction picker.
  Widget plankSize(
    BuildContext context, {
    required MeasurementSystem system,
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required String labelText,
    required int minMm,
    required int maxMm,
    required void Function(int) apply,
  }) {
    final appStrings = AppStrings.of(context);
    if (system == MeasurementSystem.metric) {
      return AppTextFormField(
        controller: controller,
        focusNode: focusNode,
        nextFocusNode: nextFocusNode,
        labelText: labelText,
        validator: (value) =>
            Validators.sizeValidator(context, value ?? '', minMm, maxMm, appStrings.mm),
        callback: (value) => apply(parseSizeIn(system, value)),
      );
    }
    return InchField(
      controller: controller,
      focusNode: focusNode,
      nextFocusNode: nextFocusNode,
      labelText: labelText,
      validator: (value) => Validators.sizeValidator(
          context, value, ceilInch(minMm), floorInch(maxMm), appStrings.inch),
      callback: (value) => apply(parseSizeIn(system, value)),
    );
  }

  // Millimetres are two boxes side by side. In inches each box carries a
  // fraction picker, so the pair does not fit one row and the sizes are laid
  // out like the room ones instead: a title, an echo and one box to a row.
  List<Widget> plankRows(
    LaminateState laminate,
    MeasurementSystem system, {
    required Widget length,
    required Widget width,
    required String lengthTitle,
    required String widthTitle,
  }) {
    if (system == MeasurementSystem.metric) {
      return [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: length),
          const SizedBox(width: kFormGap),
          Expanded(child: width),
        ]),
      ];
    }
    String? echo(int? mm) => mm == null ? null : "${formatInches(mm / MM_PER_INCH)}''";
    return [
      sizeTitle(lengthTitle, echo(laminate.laminateLength)),
      const SizedBox(height: _GAP),
      Row(children: [SizedBox(width: _INCH_FIELD_WIDTH, child: length)]),
      // The same gap as anywhere else on the form: the labels ride on the top
      // border of the boxes, so the air under a title is about 8 px less than
      // the number says and the air above one is all there — which is enough
      // to tell whose title it is.
      const SizedBox(height: _GAP),
      sizeTitle(widthTitle, echo(laminate.laminateWidth)),
      const SizedBox(height: _GAP),
      Row(children: [SizedBox(width: _INCH_FIELD_WIDTH, child: width)]),
    ];
  }

  int parseSizeIn(MeasurementSystem system, String value) =>
      system == MeasurementSystem.metric ? int.parse(value) : inchToMm(parseInches(value)!);

  bool areAllFieldsValid(BuildContext context, LayingInputs inputs) {
    final indentFromWallValue = indentFromWallController.text.trim();
    final rowOffsetValue = rowOffsetController.text.trim();
    final minimumLaminateLengthValue = minimumLaminateLengthController.text.trim();

    if (indentFromWallValue.isEmpty || minimumLaminateLengthValue.isEmpty) {
      return false;
    }
    if (inputs.offsetMode == OffsetMode.exact &&
        (rowOffsetValue.isEmpty ||
            rowOffsetValidator(context, inputs, rowOffsetValue) != null)) {
      return false;
    }

    return indentFromWallValidator(context, inputs, indentFromWallValue) == null &&
        minimumLaminateLengthValidator(context, inputs, minimumLaminateLengthValue) == null;
  }

  String offsetValueText(BuildContext context, LayingInputs inputs) {
    final appStrings = AppStrings.of(context);
    final offset = effectiveRowOffset(inputs);
    if (offset == null) return '';
    return inputs.system == MeasurementSystem.metric
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
  RowPlan? planOf(LayingInputs inputs) {
    final shape = inputs.shape;
    final laminateLength = inputs.laminateLength;
    final laminateWidth = inputs.laminateWidth;
    final indentFromWall = inputs.indentFromWall;
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
      direction: inputs.direction,
    );
  }

  // Null when there is nothing to give: a field still empty, or rows that are
  // not all of one length — a 45° layout, or a room whose opposite walls differ.
  int? rowLength(LayingInputs inputs) {
    final plan = planOf(inputs);
    if (plan == null || !plan.isUniform) return null;
    return plan.lengths.first;
  }

  int? numberOfRowsFor(LayingInputs inputs) => planOf(inputs)?.numberOfRows;

  // The exact offset in mm: derived from the plank length for the fraction
  // modes, entered by the user in the exact mode.
  int? effectiveRowOffset(LayingInputs inputs) {
    final divisor = inputs.offsetMode.divisor;
    if (divisor == null) return inputs.rowOffset;
    final laminateLength = inputs.laminateLength;
    if (laminateLength == null) return null;
    return (laminateLength / divisor).round();
  }

  int rowOffsetMax(LayingInputs inputs) {
    final laminateLength = inputs.laminateLength;
    if (laminateLength == null) return 0;
    return laminateLength ~/ 2;
  }

  int minimumLaminateLengthMax(LayingInputs inputs) {
    final plan = planOf(inputs);
    final laminateLength = inputs.laminateLength;
    final rowOffset = effectiveRowOffset(inputs);
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

  bool minimumLaminateLengthValidatorDisabled(LayingInputs inputs) {
    final rowOffset = effectiveRowOffset(inputs);
    if (planOf(inputs) == null || rowOffset == null) {
      return true;
    }
    // While the offset itself is out of range, or no minimum length works at
    // all for this offset, the min/max bounds are meaningless, so skip the
    // check (the final calculation reports infeasible configurations).
    return rowOffset < MIN_ROW_OFFSET ||
        rowOffset > rowOffsetMax(inputs) ||
        minimumLaminateLengthMax(inputs) < MIN_MIN_LENGTH;
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings.of(context);

    // The room is read, not watched: its screen is under this one and out of
    // reach while this one is up, and a step back takes this screen away
    // altogether, so it comes forward again and reads it again. The plank is
    // watched, because it is typed here — every bound in the lower half is
    // worked out from it, and they have to move as the digits land.
    final room = context.read<RoomCubit>().state;

    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (was, now) => was.system != now.system,
      builder: (context, settings) => BlocBuilder<LaminateCubit, LaminateState>(
        builder: (context, laminate) => BlocBuilder<LayingCubit, LayingState>(
          builder: (context, laying) {
            final system = settings.system;
            final inputs = LayingInputs(system, room, laminate, laying);
            final cubit = context.read<LaminateCubit>();
            return ParametersCard(
              title: appStrings.laminate,
              icon: const Icon(Icons.horizontal_split_sharp,
                  size: kTitleIcon, color: Colors.blue),
              canProceed:
                  isLaminateValid(context, system) && areAllFieldsValid(context, inputs),
              onNext: () => context.router.push(const ReviewRoute()),
              onSettings: () => openSettings(context),
              children: [
                const SizedBox(height: _GAP),
                ...plankRows(
                  laminate,
                  system,
                  lengthTitle: appStrings.length,
                  widthTitle: appStrings.width,
                  length: plankSize(
                    context,
                    system: system,
                    controller: lengthController,
                    focusNode: lengthFocusNode,
                    nextFocusNode: widthFocusNode,
                    // In inches the box holds one number under a title of its
                    // own, so it is labelled with the unit, exactly like the
                    // room boxes.
                    labelText: system == MeasurementSystem.metric
                        ? appStrings.length_mm
                        : appStrings.inch,
                    minMm: MIN_PLANK_LENGTH,
                    maxMm: MAX_PLANK_LENGTH,
                    apply: cubit.setLaminateLength,
                  ),
                  width: plankSize(
                    context,
                    system: system,
                    controller: widthController,
                    focusNode: widthFocusNode,
                    nextFocusNode: packFocusNode,
                    labelText: system == MeasurementSystem.metric
                        ? appStrings.width_mm
                        : appStrings.inch,
                    minMm: MIN_PLANK_WIDTH,
                    maxMm: MAX_PLANK_WIDTH,
                    apply: cubit.setLaminateWidth,
                  ),
                ),
                const SizedBox(height: _GAP),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextFormField(
                        controller: packController,
                        focusNode: packFocusNode,
                        nextFocusNode: indentFromWallFocusNode,
                        labelText: appStrings.pieces_per_package,
                        validator: (value) => Validators.sizeValidator(context, value ?? '',
                            MIN_ITEMS_IN_PACK, MAX_ITEMS_IN_PACK, appStrings.pcs),
                        callback: (value) => cubit.setQuantityPerPack(int.parse(value)),
                      ),
                    ),
                    const SizedBox(width: kFormGap),
                    // Half a row, like the length field above it: a pack count
                    // is two digits and a box the width of the card reads as a
                    // much longer value.
                    const Spacer(),
                  ],
                ),
                // A section's worth of air and a heading of its own. Above the
                // line is what was bought; below it is what is done with it.
                const SizedBox(height: _SECTION_GAP),
                sectionTitle(
                  appStrings.laying,
                  const Icon(Icons.branding_watermark, size: kTitleIcon, color: Colors.blue),
                ),
                const SizedBox(height: _GAP),
                // No heading over these three. "Along the length", "Along the
                // width" and "Diagonal" say between them what a line reading
                // "Laying direction" would say above them, and the line only
                // pushed the rest of the form further down the screen. The
                // offset below keeps its heading, because "1/2 1/3 1/4 exact"
                // does not say what it is a half of.
                //
                // A notch in the middle of a wall parts every row that runs
                // along that wall into two, and a row in two is a thing the
                // engine cannot lay. Across it they stay whole, so one of the
                // first two is out of reach in such a room — which one depends on
                // which wall the notch is in, so it is asked of the room.
                //
                // A 45° strip crosses a cut-away corner twice, for the same kind
                // of reason, which is why the third can be out of reach too.
                // Asked of the room and not of the tile the user pressed: this
                // read "is the room specifically an L" while the L was the only
                // shape with a square cut, and went on reading it after the T and
                // the Z arrived.
                radioRows<Direction>(
                  // One to a line. These labels are sentences in half the
                  // languages shipped — "Lungo la lunghezza", "Genişlik
                  // boyunca", "Wzdłuż szerokości" — and a cell shrinks its
                  // label to fit rather than wrapping it, so every choice that
                  // shares a line costs type size. Three across was squinting
                  // and two was still small. Down a column every one of them is
                  // set at full size in every language, which is what a
                  // direction nobody should misread is worth three lines of
                  // card for.
                  rows: const [
                    [Direction.length],
                    [Direction.width],
                    [Direction.diagonal],
                  ],
                  selected: inputs.direction,
                  label: (direction) => direction == Direction.length
                      ? appStrings.along_length
                      : direction == Direction.width
                          ? appStrings.along_width
                          : appStrings.diagonally,
                  enabled: (direction) => direction == Direction.length
                      ? inputs.takesAlongLength
                      : direction == Direction.width
                          ? inputs.takesAcrossWidth
                          : inputs.takesDiagonal,
                  onChanged: (direction) =>
                      context.read<LayingCubit>().setDirection(direction),
                ),
                // Said on screen rather than in a tooltip: a tooltip
                // on a phone needs a long press, and nobody long
                // presses a button that is greyed out.
                //
                // One line, never two. A room that takes only one of
                // the straight directions does not take 45° either,
                // and saying so underneath is a second sentence that
                // adds nothing: "only across that wall" has already
                // ruled the diagonal out along with everything else.
                if (!inputs.takesAlongLength || !inputs.takesAcrossWidth)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        appStrings.direction_across_notch_only,
                        style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ),
                  )
                else if (!inputs.takesDiagonal)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        appStrings.diagonal_not_for_notch,
                        style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ),
                  ),
                SizedBox(height: _GAP),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: sizeField(
                        inputs: inputs,
                        controller: indentFromWallController,
                        focusNode: indentFromWallFocusNode,
                        nextFocusNode: inputs.offsetMode == OffsetMode.exact
                            ? rowOffsetFocusNode
                            : minimumLaminateLengthFocusNode,
                        labelText: inputs.system == MeasurementSystem.metric
                            ? appStrings.expansion_gap_mm
                            : appStrings.expansion_gap_in,
                        validator: (value) => indentFromWallValidator(context, inputs, value),
                        apply: (mm) => context.read<LayingCubit>().setIndentFromWall(mm),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _SECTION_GAP),
                Row(
                  children: [
                    Text(
                      appStrings.joint_offset,
                      style:
                          TextStyle(color: Colors.black.withValues(alpha: 0.8), fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: _LABEL_GAP),
                radioRows<OffsetMode>(
                  // Four fractions and a word, all short: one row holds them at
                  // full size in every language.
                  rows: const [OffsetMode.values],
                  selected: inputs.offsetMode,
                  label: (mode) => mode == OffsetMode.half
                      ? '1/2'
                      : mode == OffsetMode.third
                          ? '1/3'
                          : mode == OffsetMode.quarter
                              ? '1/4'
                              : appStrings.exact_offset,
                  enabled: (mode) => true,
                  onChanged: (mode) => context.read<LayingCubit>().setOffsetMode(mode),
                ),
                // A fraction of the plank is worked out rather than typed, so
                // what stands in for the box is the number it came to. Nothing
                // stands in for it until there is one: the plank is typed on
                // this very screen, and before it is, an empty line and the air
                // round it left a hole under the fractions that looked like a
                // control that had failed to draw.
                if (inputs.offsetMode == OffsetMode.exact) ...[
                  SizedBox(height: _GAP),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: sizeField(
                          inputs: inputs,
                          controller: rowOffsetController,
                          focusNode: rowOffsetFocusNode,
                          nextFocusNode: minimumLaminateLengthFocusNode,
                          labelText: inputs.system == MeasurementSystem.metric
                              ? appStrings.joint_offset_mm
                              : appStrings.joint_offset_in,
                          validator: (value) => rowOffsetValidator(context, inputs, value),
                          apply: (mm) => context.read<LayingCubit>().setRowOffset(mm),
                        ),
                      ),
                    ],
                  ),
                ] else if (offsetValueText(context, inputs).isNotEmpty) ...[
                  // Closer to the fractions than to the box below, because it
                  // is a note on what was just chosen and not a control of its
                  // own.
                  SizedBox(height: _LABEL_GAP),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      offsetValueText(context, inputs),
                      style:
                          TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 14),
                    ),
                  ),
                ],
                SizedBox(height: _GAP),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: sizeField(
                        inputs: inputs,
                        controller: minimumLaminateLengthController,
                        focusNode: minimumLaminateLengthFocusNode,
                        labelText: inputs.system == MeasurementSystem.metric
                            ? appStrings.minimal_piece_length
                            : appStrings.minimal_piece_length_in,
                        validator: (value) =>
                            minimumLaminateLengthValidator(context, inputs, value),
                        apply: (mm) =>
                            context.read<LayingCubit>().setMinimumLaminateLength(mm),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Radio buttons laid out in the rows they are given, one choice per cell and
  /// no cell ever wrapping.
  ///
  /// [SegmentedButton] was here and broke its own labels in half: a segment is
  /// given its share of the card and the words inside it wrap, so "По ширине"
  /// came out over two lines and the three segments were three different
  /// heights. A radio keeps its label on one line by construction.
  ///
  /// How many rows is the caller's business, because it is a question about the
  /// words and not about the control. The labels are nowhere near the same
  /// length — "Längs" against "Lungo la lunghezza" — and a cell shrinks its
  /// label to fit rather than wrapping it, so three long ones across one row
  /// come out too small to read comfortably. Four short ones do not. The one
  /// thing the caller may not do is leave a row that does not fit: there is no
  /// wrapping here, only type that gets smaller.
  ///
  /// Each cell takes a share of its row in proportion to what its label has to
  /// say, plus a fixed four characters' worth for the circle beside it. Without
  /// that constant the circle comes out of a short label's share and nothing
  /// else's, and the shortest of three ends up set noticeably smaller than its
  /// neighbours.
  Widget radioRows<T>({
    required List<List<T>> rows,
    required T selected,
    required String Function(T) label,
    required bool Function(T) enabled,
    required ValueChanged<T> onChanged,
  }) =>
      RadioGroup<T>(
        groupValue: selected,
        onChanged: (picked) {
          if (picked != null) onChanged(picked);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in rows)
              Row(
                children: [
                  for (final value in row)
                    Expanded(
                      flex: label(value).length + 4,
                      child: InkWell(
                        // The label is part of the control, as it is in every radio
                        // list: a word is a far bigger target than the circle beside
                        // it, and on a phone that is the difference.
                        onTap: enabled(value) ? () => onChanged(value) : null,
                        child: Row(
                          children: [
                            Radio<T>(
                              value: value,
                              enabled: enabled(value),
                              // A radio ships with a 48 dp tap target of its own,
                              // which between four of them is most of the card. The
                              // row round it carries the target instead.
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  label(value),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: enabled(value)
                                        ? Colors.black.withValues(alpha: 0.8)
                                        : Colors.black.withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      );

}

/// Everything the laying half of the screen reasons over, gathered once per
/// build.
///
/// Not a state and not stored: it lives for one frame and is thrown away. Its
/// job is to be the written-down list of what this screen reads from the rest
/// of the form — a room's outline and the three numbers off the carton typed
/// just above — so that the dozen validators and bounds above can go on being
/// written against one object without that object being everybody's answers at
/// once.
class LayingInputs {
  final MeasurementSystem system;
  final RoomState _room;
  final LaminateState _laminate;
  final LayingState _laying;

  const LayingInputs(this.system, this._room, this._laminate, this._laying);

  RoomOutline? get shape => _room.shape;

  int? get laminateLength => _laminate.laminateLength;
  int? get laminateWidth => _laminate.laminateWidth;
  int? get quantityPerPack => _laminate.quantityPerPack;

  int? get indentFromWall => _laying.indentFromWall;
  int? get rowOffset => _laying.rowOffset;
  int? get minimumLaminateLength => _laying.minimumLaminateLength;
  OffsetMode get offsetMode => _laying.offsetMode;

  /// Whether this room can be laid at 45° at all.
  ///
  /// A 45° strip crosses an outline that turns back on itself twice, so a row
  /// there would be two rows and nothing downstream has a way to say so. Asked
  /// of the room rather than of the shape the user picked off the tiles: three
  /// of the seven shapes have a corner taken out square and none of the three
  /// takes a diagonal, which the screen got wrong for two of them while it was
  /// asking whether the room was specifically an L.
  bool get takesDiagonal => shape?.takesDiagonal ?? true;

  /// Whether the rows may run along the room and whether they may run across
  /// it. One of them is false in exactly one room — the one with a notch in the
  /// middle of a wall — and true everywhere else.
  bool get takesAlongLength => shape?.takesAlongLength ?? true;

  bool get takesAcrossWidth => shape?.takesAcrossWidth ?? true;

  /// Which way the rows will actually run.
  ///
  /// Not always the direction the user picked: they may have chosen 45° in a
  /// rectangle and then stepped back and notched the room. Rather than reaching
  /// into this screen's answers from the room screen to correct one, the answer
  /// is read through the room — so an impossible pair is never acted on, and
  /// un-notching the room gives the user back the direction they chose.
  Direction get direction {
    final chosen = _laying.direction;
    if (chosen == Direction.diagonal) {
      return takesDiagonal ? chosen : _straight;
    }
    if (chosen == Direction.length) return takesAlongLength ? chosen : Direction.width;
    return takesAcrossWidth ? chosen : Direction.length;
  }

  /// The straight direction to fall back on when the one the user chose cannot
  /// be laid. Along the room wherever that works, which is every room but one.
  Direction get _straight => takesAlongLength ? Direction.length : Direction.width;
}
