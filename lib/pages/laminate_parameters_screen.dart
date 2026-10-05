// What the laminate itself is: a plank's length and width, and how many go in
// a pack.
//
// Its own screen rather than the foot of the room form. The room grew a shape
// to pick and up to five measurements to type, and the two sections had nothing
// to do with one another: the room is measured once with a tape, the laminate
// is copied off the box in the shop. On one screen the pack count ended up
// below the fold and the Next button below that, which is how a tap aimed at it
// could land on nothing at all.
import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/utils/validators.dart';
import 'package:floor_calculator/widgets/app_text_form_field.dart';
import 'package:floor_calculator/widgets/inch_field.dart';
import 'package:floor_calculator/widgets/parameters_card.dart';
import 'package:floor_calculator/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// An inch box carries a fraction picker beside it, so it is wider than the
// number alone needs.
const double _NUMBER_FIELD_WIDTH = 72;
const double _INCH_FIELD_WIDTH =
    _NUMBER_FIELD_WIDTH + INCH_FRACTION_GAP + INCH_FRACTION_WIDTH;

class LaminateParametersScreen extends StatefulWidget {
  const LaminateParametersScreen({super.key});

  @override
  LaminateParametersScreenState createState() => LaminateParametersScreenState();
}

class LaminateParametersScreenState extends State<LaminateParametersScreen> {
  final lengthController = TextEditingController();
  final widthController = TextEditingController();
  final packController = TextEditingController();

  final lengthFocusNode = FocusNode();
  final widthFocusNode = FocusNode();
  final packFocusNode = FocusNode();

  List<TextEditingController> get _controllers =>
      [lengthController, widthController, packController];

  @override
  void initState() {
    super.initState();
    // The screen is reached with the state already holding whatever was typed
    // the last time through, and a user who steps back to fix the room must
    // find the laminate where they left it.
    final state = context.read<CalculateCubit>().state;
    rewriteFieldsFor(state.system, state);
    // The Next button is decided from what is in the boxes, and a value a field
    // rejects never reaches the state — so without this the button would stay
    // as it was while the box under it went red.
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
    widthController.dispose();
    packController.dispose();
    lengthFocusNode.dispose();
    widthFocusNode.dispose();
    packFocusNode.dispose();
    super.dispose();
  }

  // Rewrites the field texts from the canonical state, which is always
  // millimetres, so that values already entered survive a change of units.
  void rewriteFieldsFor(MeasurementSystem system, CalculateState state) {
    void setField(int? mm, TextEditingController controller) {
      if (mm == null) {
        controller.clear();
      } else {
        controller.text = formatSize(mm, system);
      }
    }

    setField(state.laminateLength, lengthController);
    setField(state.laminateWidth, widthController);
    final pack = state.quantityPerPack;
    if (pack != null) packController.text = '$pack';
  }

  void openSettings(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SettingsSheet(
          onSystemChanged: (system) {
            final cubit = context.read<CalculateCubit>();
            if (system == cubit.state.system) return;
            rewriteFieldsFor(system, cubit.state);
            cubit.setMeasurementSystem(system);
          },
        ),
      );

  int parseSize(MeasurementSystem system, String value) =>
      system == MeasurementSystem.metric ? int.parse(value) : inchToMm(parseInches(value)!);

  bool areAllFieldsValid(BuildContext context, CalculateState state) {
    final appStrings = AppStrings.of(context);
    final length = lengthController.text.trim();
    final width = widthController.text.trim();
    final pack = packController.text.trim();
    if (length.isEmpty || width.isEmpty || pack.isEmpty) return false;

    final bool lengthValid;
    final bool widthValid;
    if (state.system == MeasurementSystem.metric) {
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
          const SizedBox(width: kFormGap),
          Expanded(child: width),
        ]),
      ];
    }
    String? echo(int? mm) => mm == null ? null : "${formatInches(mm / MM_PER_INCH)}''";
    return [
      sizeTitle(lengthTitle, echo(state.laminateLength)),
      const SizedBox(height: kFormGap),
      Row(children: [SizedBox(width: _INCH_FIELD_WIDTH, child: length)]),
      // The same gap as anywhere else on the form: the labels ride on the top
      // border of the boxes, so the air under a title is about 8 px less than
      // the number says and the air above one is all there — which is enough
      // to tell whose title it is.
      const SizedBox(height: kFormGap),
      sizeTitle(widthTitle, echo(state.laminateWidth)),
      const SizedBox(height: kFormGap),
      Row(children: [SizedBox(width: _INCH_FIELD_WIDTH, child: width)]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings.of(context);
    return BlocBuilder<CalculateCubit, CalculateState>(
      builder: (context, state) {
        final cubit = context.read<CalculateCubit>();
        return ParametersCard(
          title: appStrings.laminate,
          icon: Icons.horizontal_split_sharp,
          canProceed: areAllFieldsValid(context, state),
          onNext: () => context.router.push(LayingParametersRoute()),
          onSettings: () => openSettings(context),
          children: [
            const SizedBox(height: kFormGap),
            ...plankRows(
              state,
              lengthTitle: appStrings.length,
              widthTitle: appStrings.width,
              length: plankSize(
                context,
                state: state,
                controller: lengthController,
                focusNode: lengthFocusNode,
                nextFocusNode: widthFocusNode,
                // In inches the box holds one number under a title of its own,
                // so it is labelled with the unit, exactly like the room boxes.
                labelText: state.system == MeasurementSystem.metric
                    ? appStrings.length_mm
                    : appStrings.inch,
                minMm: MIN_PLANK_LENGTH,
                maxMm: MAX_PLANK_LENGTH,
                apply: cubit.setLaminateLength,
              ),
              width: plankSize(
                context,
                state: state,
                controller: widthController,
                focusNode: widthFocusNode,
                nextFocusNode: packFocusNode,
                labelText: state.system == MeasurementSystem.metric
                    ? appStrings.width_mm
                    : appStrings.inch,
                minMm: MIN_PLANK_WIDTH,
                maxMm: MAX_PLANK_WIDTH,
                apply: cubit.setLaminateWidth,
              ),
            ),
            const SizedBox(height: kFormGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextFormField(
                    controller: packController,
                    focusNode: packFocusNode,
                    labelText: appStrings.pieces_per_package,
                    validator: (value) => Validators.sizeValidator(context, value ?? '',
                        MIN_ITEMS_IN_PACK, MAX_ITEMS_IN_PACK, appStrings.pcs),
                    callback: (value) => cubit.setQuantityPerPack(int.parse(value)),
                  ),
                ),
                const SizedBox(width: kFormGap),
                // Half a row, like the length field above it: a pack count is
                // two digits and a box the width of the card reads as a much
                // longer value.
                const Spacer(),
              ],
            ),
          ],
        );
      },
    );
  }
}
