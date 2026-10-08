// Everything typed, on one page, before anything is worked out from it.
//
// The form is three sections over two screens, and the last of them used to
// push straight to a list of variants. A user who had mistyped a plank length
// found out from the answer — a floor that wanted forty packs — and had to walk
// back through both screens to see which number was wrong.
//
// Nothing is editable here. The way to change a number is the arrow back to the
// screen that asked for it, which is where its bounds and its error message
// live; a second place to type the same value is a second place for the two to
// disagree.
import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/cubit/laminate_cubit.dart';
import 'package:floor_calculator/cubit/laying_cubit.dart';
import 'package:floor_calculator/cubit/room_cubit.dart';
import 'package:floor_calculator/cubit/settings_cubit.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/pages/room_parameters_screen.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/widgets/parameters_card.dart';
import 'package:floor_calculator/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One line of the review: what it is called on the left, what it says on the
/// right.
///
/// The value is set against the right edge and the name against the left, so
/// that the numbers make a column. A review is read down that column — the eye
/// is hunting for a wrong number, not for a name it typed itself five seconds
/// ago.
class ReviewLine extends StatelessWidget {
  final String title;
  final String value;

  const ReviewLine(this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 15, color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
            const SizedBox(width: 12),
            Text(value, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          ],
        ),
      );
}

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  /// A measurement with its unit on it. The form puts the unit in each box's
  /// label and has one unit a box; a column of values has to carry its own.
  ///
  /// Feet and inches carry theirs already — `12'-4 1/2''` says what it is — so
  /// only millimetres need the word.
  static String withUnit(AppLocalizations appStrings, int? mm, MeasurementSystem system) {
    if (mm == null) return '—';
    return system == MeasurementSystem.metric
        ? '$mm ${appStrings.mm}'
        : sizeLabel(mm, system);
  }

  /// The offset in millimetres, whichever way it was chosen: typed outright, or
  /// a fraction of the plank worked out from it.
  static int? _offsetMm(LaminateState laminate, LayingState laying) {
    final divisor = laying.offsetMode.divisor;
    if (divisor == null) return laying.rowOffset;
    final plank = laminate.laminateLength;
    return plank == null ? null : (plank / divisor).round();
  }

  /// Which way the rows will actually run.
  ///
  /// Not always what is stored: a room with a notch or a cut can refuse the
  /// direction the user chose in a rectangle, and the laying screen reads it
  /// through the room rather than rewriting it — see `LayingInputs.direction`.
  /// A review that says "diagonal" over a floor laid along the room would be
  /// worse than no review at all, so it reads it the same way.
  static Direction effectiveDirection(RoomState room, LayingState laying) {
    final shape = room.shape;
    final chosen = laying.direction;
    if (shape == null) return chosen;
    if (chosen == Direction.diagonal) {
      if (shape.takesDiagonal) return chosen;
      return shape.takesAlongLength ? Direction.length : Direction.width;
    }
    if (chosen == Direction.length) {
      return shape.takesAlongLength ? chosen : Direction.width;
    }
    return shape.takesAcrossWidth ? chosen : Direction.length;
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings.of(context);
    final system = context.watch<SettingsCubit>().state.system;
    final room = context.watch<RoomCubit>().state;
    final laminate = context.watch<LaminateCubit>().state;
    final laying = context.watch<LayingCubit>().state;
    final direction = effectiveDirection(room, laying);
    final divisor = laying.offsetMode.divisor;

    String size(int? mm) => withUnit(appStrings, mm, system);

    return ParametersCard(
      title: appStrings.room,
      icon: CustomPaint(
        painter: RoomKindIcon(
          corners: roomKindIconCorners(room.roomKind),
          colour: Colors.blue,
        ),
      ),
      // Every value here came through a field that would not let it past
      // unless it was one the engine takes, so there is nothing left to refuse.
      canProceed: true,
      nextLabel: appStrings.calculate,
      onNext: () => calculate(context, room, laminate, laying, direction),
      // The gear works here as it does on the forms, and costs nothing: there
      // are no boxes holding text in the old unit, so switching the system only
      // rewrites the column on the right.
      onSettings: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SettingsSheet(
          onSystemChanged: (picked) => context.read<SettingsCubit>().setSystem(picked),
        ),
      ),
      children: [
        const SizedBox(height: kFormGap),
        ReviewLine(appStrings.room_shape, roomKindNameOf(appStrings, room.roomKind)),
        for (final measurement in roomMeasurements(appStrings, room))
          ReviewLine(measurement.title, size(measurement.valueMm)),
        const SizedBox(height: kFormSectionGap),
        sectionTitle(
          appStrings.laminate,
          const Icon(Icons.horizontal_split_sharp, size: kTitleIcon, color: Colors.blue),
        ),
        const SizedBox(height: kFormGap),
        ReviewLine(appStrings.length, size(laminate.laminateLength)),
        ReviewLine(appStrings.width, size(laminate.laminateWidth)),
        ReviewLine(
          appStrings.pieces_per_package,
          laminate.quantityPerPack == null
              ? '—'
              : '${laminate.quantityPerPack} ${appStrings.pcs}',
        ),
        const SizedBox(height: kFormSectionGap),
        sectionTitle(
          appStrings.laying,
          const Icon(Icons.branding_watermark, size: kTitleIcon, color: Colors.blue),
        ),
        const SizedBox(height: kFormGap),
        ReviewLine(
          appStrings.laying_direction,
          direction == Direction.length
              ? appStrings.along_length
              : direction == Direction.width
                  ? appStrings.along_width
                  : appStrings.diagonally,
        ),
        ReviewLine(appStrings.expansion_gap, size(laying.indentFromWall)),
        // The fraction and the millimetres it came to, because the user chose
        // the first and the floor is laid to the second.
        ReviewLine(
          appStrings.joint_offset,
          divisor == null
              ? size(_offsetMm(laminate, laying))
              : '1/$divisor · ${size(_offsetMm(laminate, laying))}',
        ),
        ReviewLine(appStrings.min_piece_length, size(laying.minimumLaminateLength)),
      ],
    );
  }

  /// Lays the floor and goes to the variants, or says there are none.
  ///
  /// The same arithmetic the laying screen used to do at its own Next button,
  /// moved here with the button. Every number has been checked by the field it
  /// was typed into; the nulls below are what the type system knows and the
  /// form does not say back to it.
  void calculate(
    BuildContext context,
    RoomState room,
    LaminateState laminate,
    LayingState laying,
    Direction direction,
  ) {
    final shape = room.shape;
    final laminateLength = laminate.laminateLength;
    final laminateWidth = laminate.laminateWidth;
    final planksInPack = laminate.quantityPerPack;
    final indentFromWall = laying.indentFromWall;
    final rowOffset = _offsetMm(laminate, laying);
    final minimumLaminateLength = laying.minimumLaminateLength;
    if (shape == null ||
        laminateLength == null ||
        laminateWidth == null ||
        planksInPack == null ||
        indentFromWall == null ||
        rowOffset == null ||
        minimumLaminateLength == null) {
      return;
    }
    final result = Calculation(
      shape: shape,
      laminateLength: laminateLength,
      laminateWidth: laminateWidth,
      planksInPack: planksInPack,
      indentFromWall: indentFromWall,
      minimumLaminateLength: minimumLaminateLength,
      rowOffset: rowOffset,
      direction: direction,
    ).calculate();
    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).no_laying_variants)),
      );
      return;
    }
    context.router.push(ResultRoute(result: result));
  }
}
