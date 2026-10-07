import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_cubit.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/room_kind.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';
import 'package:floor_calculator/utils/validators.dart';
import 'package:floor_calculator/widgets/parameters_card.dart';
import 'package:floor_calculator/widgets/app_text_form_field.dart';
import 'package:floor_calculator/widgets/inch_field.dart';
import 'package:floor_calculator/widgets/room_sketch.dart';
import 'package:floor_calculator/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// One rhythm for the whole form. The labels ride on the field borders now, so
// every title and every row above needs clearance or the label lands on it.
const double _GAP = kFormGap;

// A room size is three controls wide, so its boxes are sized to their digits
// instead of sharing out the row: '5' in a full-width box reads as a mistake.
const double _NUMBER_FIELD_WIDTH = 72;
const double _INCH_FIELD_WIDTH = _NUMBER_FIELD_WIDTH + INCH_FRACTION_GAP + INCH_FRACTION_WIDTH;

// A shape tile is square and takes a sixth of the card, up to this. Beyond it
// the button stops reading as a button — the outline inside has long since been
// as clear as it is going to get.
const double _TILE_MAX = 60;

// Rounded enough to read as a button, square enough that the corner of the room
// drawn inside it is still the sharpest corner on the tile.
const double _TILE_RADIUS = 12;

// What sits between two tiles, across and down.
const double _TILE_GAP = 8;

// The one caption under the row of tiles. Its line height is written down
// rather than left to the font, because the line is reserved before the text is
// laid out and a reserved line that is short by a pixel clips the descenders.
const double _CAPTION_SIZE = 14;
const double _CAPTION_HEIGHT = 1.2;

class RoomParametersScreen extends StatefulWidget {
  const RoomParametersScreen({super.key});

  @override
  RoomParametersScreenState createState() => RoomParametersScreenState();
}

class RoomParametersScreenState extends State<RoomParametersScreen> {
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
  // The cut-away corner, on screen only while the room is Г-shaped. Its own
  // boxes rather than the ones above: the two shapes are alternatives, and a
  // user who tries one and goes back to the other must find their numbers
  // where they left them.
  final notchLengthFocusNode = FocusNode();
  final notchLengthInchFocusNode = FocusNode();
  final notchLength2FocusNode = FocusNode();
  final notchLength2InchFocusNode = FocusNode();
  final notchWidthFocusNode = FocusNode();
  final notchWidthInchFocusNode = FocusNode();

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
  final notchLengthController = TextEditingController();
  final notchLengthInchController = TextEditingController(text: '0');
  final notchLength2Controller = TextEditingController();
  final notchLength2InchController = TextEditingController(text: '0');
  final notchWidthController = TextEditingController();
  final notchWidthInchController = TextEditingController(text: '0');

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
        notchLengthController,
        notchLengthInchController,
        notchLength2Controller,
        notchLength2InchController,
        notchWidthController,
        notchWidthInchController,
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
    // The sketch picks out the measurement being typed, so a change of cursor
    // has to redraw as surely as a change of digit does.
    for (final node in _focusNodes) {
      node.addListener(_onFieldChanged);
    }
  }

  // Every box's own focus node and the inch box beside it, so that one list can
  // be listened to and disposed of.
  List<FocusNode> get _focusNodes => [
        lengthFocusNode,
        lengthInchFocusNode,
        widthFocusNode,
        widthInchFocusNode,
        length2FocusNode,
        length2InchFocusNode,
        width2FocusNode,
        width2InchFocusNode,
        diagonalFocusNode,
        diagonalInchFocusNode,
        notchLengthFocusNode,
        notchLengthInchFocusNode,
        notchLength2FocusNode,
        notchLength2InchFocusNode,
        notchWidthFocusNode,
        notchWidthInchFocusNode,
      ];

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_onFieldChanged);
    }
    for (final node in _focusNodes) {
      node.removeListener(_onFieldChanged);
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
    notchLengthController.dispose();
    notchLengthInchController.dispose();
    notchLength2Controller.dispose();
    notchLength2InchController.dispose();
    notchWidthController.dispose();
    notchWidthInchController.dispose();
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
    notchLengthFocusNode.dispose();
    notchLengthInchFocusNode.dispose();
    notchLength2FocusNode.dispose();
    notchLength2InchFocusNode.dispose();
    notchWidthFocusNode.dispose();
    notchWidthInchFocusNode.dispose();
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

    setRoomField(state.roomLength, lengthController, lengthInchController);
    setRoomField(state.roomWidth, widthController, widthInchController);
    setRoomField(state.roomLength2, length2Controller, length2InchController);
    setRoomField(state.roomWidth2, width2Controller, width2InchController);
    setRoomField(state.roomDiagonal, diagonalController, diagonalInchController);
    setRoomField(state.notchLength, notchLengthController, notchLengthInchController);
    setRoomField(state.notchLength2, notchLength2Controller, notchLength2InchController);
    setRoomField(state.notchWidth, notchWidthController, notchWidthInchController);
  }

  // Changing the shape never puts a number in a box the user did not type.
  //
  // It used to: a new shape arrived with whatever it added already filled in —
  // the far walls equal to the near ones, a cut a third of the room — so that
  // the form was valid the moment it changed. What that actually did was fill
  // three boxes with measurements nobody had taken and light the Next button
  // over them, and a tape measure is the whole point of the screen. A user who
  // types an overall size and says the walls differ is telling us they have
  // not measured the other two yet.
  //
  // What the user *did* type is carried from shape to shape and kept — see
  // [CalculateState.notchLength] — and clamped into the new shape's bounds,
  // which is not a guess but the arithmetic of the shape they just picked: a
  // cut that was legal as the only one on its wall may be too deep to share it.
  void setRoomKind(BuildContext context, RoomKind kind) {
    final cubit = context.read<CalculateCubit>();
    final state = cubit.state;
    final length = state.roomLength;
    final width = state.roomWidth;
    final notchLength = state.notchLength;
    final notchLength2 = state.notchLength2;
    final notchWidth = state.notchWidth;
    if (length != null && width != null && kind.isCut) {
      final alongWall = state.cutWall.runsAlongLength;
      final along = alongWall ? length : width;
      final into = kind.isPaired ? (alongWall ? width : length) : width;
      final lone = kind.hasOneLeg ? math.min(length, width) : length;
      final loneMax = kind.hasOneLeg ? CornerSize.wallOfLeg(notchMax(lone)) : notchMax(lone);
      final floor = kind.hasOneLeg ? CornerSize.wallOfLeg(MIN_NOTCH_MM) : MIN_NOTCH_MM;
      // [heldBetween] rather than clamp: a room may be small enough that no cut
      // fits in it at all, and then the ceiling lands under the floor. What is
      // carried over is the smallest cut there is, and the sketch says it does
      // not fit.
      if (kind.isPaired) {
        final share =
            heldBetween(along ~/ 4, floor, shoulderMax(along, MIN_NOTCH_MM));
        if (notchLength != null) {
          cubit.setNotchLength(heldBetween(notchLength, floor, share));
        }
        if (notchLength2 != null) {
          cubit.setNotchLength2(heldBetween(notchLength2, floor, share));
        }
      } else if (notchLength != null) {
        cubit.setNotchLength(heldBetween(notchLength, floor, loneMax));
      }
      if (!kind.hasOneLeg && notchWidth != null) {
        cubit.setNotchWidth(heldBetween(notchWidth, MIN_NOTCH_MM, notchMax(into)));
      }
    }
    cubit.setRoomKind(kind);
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
            final cubit = context.read<CalculateCubit>();
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
    apply(notchLengthController, notchLengthInchController, cubit.setNotchLength);
    apply(notchLength2Controller, notchLength2InchController, cubit.setNotchLength2);
    apply(notchWidthController, notchWidthInchController, cubit.setNotchWidth);
  }

  /// One room measurement the shape asks for, and everything the form needs to
  /// put a box on screen for it.
  ///
  /// The shapes went from three to six, and with them the nested ternaries that
  /// used to pick each label and each next-focus target — four of them a side,
  /// metric and imperial. Six shapes do not fit that way round, so the question
  /// is turned over: the shape names its boxes once, in order, and the form
  /// walks the list.
  /// Which wall of the sketch each measurement is written beside.
  ///
  /// The sketch writes `wallLengths()[i]` next to wall `i`, so a box that wants
  /// to say "that number is mine" — to be highlighted when the cursor is in it,
  /// or to be a question mark until it is filled — has to name indices.
  ///
  /// Worked out from the outline rather than listed per shape. A wall square to
  /// the x axis carries a length, one square to the y axis carries a width, and
  /// a wall that a cut put there carries that cut's own leg: one rule for every
  /// shape that is built out of a rectangle. A room measured wall by wall is
  /// square to nothing, so it keeps the one listing there is.
  _WallMap _wallsOf(CalculateState state) {
    final shape = state.shape;
    if (shape == null) return const _WallMap();
    if (shape is RoomShape) {
      // [RoomShape.wallLengths] is near, right, far, left, in that order.
      return const _WallMap(alongLength: [0], acrossWidth: [3], farLength: [2], farWidth: [1]);
    }
    if (shape is! CutCornersRoomShape) return const _WallMap();

    final corners = shape.corners();
    final byCorner = shape.cutWalls();
    final cut = {for (final walls in byCorner.values) ...walls};
    final alongLength = <int>[];
    final acrossWidth = <int>[];
    for (var i = 0; i < corners.length; i++) {
      if (cut.contains(i)) continue;
      final from = corners[i];
      final to = corners[(i + 1) % corners.length];
      final flat = from.y == to.y;
      // The overall size owns the wall that *is* that size, not every wall
      // pointing the same way. A cut shortens the wall opposite the one it
      // leaves whole, and that shortened wall is a number the room worked out
      // rather than one anybody typed — lighting it up along with its full
      // neighbour said the box owned two walls, one of which it does not.
      //
      // Orientation as well as length, because a square room's walls all
      // measure the same and the length would otherwise claim the width's.
      final span = flat ? (to.x - from.x).abs() : (to.y - from.y).abs();
      final overall = (flat ? shape.length : shape.width).toDouble();
      if (span != overall) continue;
      (flat ? alongLength : acrossWidth).add(i);
    }
    // A notch leaves its corner two walls, one square to each axis, and they
    // are its two legs. A chamfer leaves one, slanted, and it is the only wall
    // the single leg can be written on.
    //
    // The two bounding walls the cut shortened are noted as well. They carry no
    // measurement of their own — the room worked them out — so they are nobody's
    // to light up, but they are everybody's to mark unknown: until the cut is
    // typed, what is left of the walls beside it is as much a guess as the cut.
    final cutAlong = <RoomCorner, List<int>>{};
    final cutAcross = <RoomCorner, List<int>>{};
    final shortened = <RoomCorner, List<int>>{};
    byCorner.forEach((corner, walls) {
      final n = corners.length;
      for (final neighbour in [walls.first - 1, walls.last + 1]) {
        final at = (neighbour + n) % n;
        if (!cut.contains(at)) shortened.putIfAbsent(corner, () => []).add(at);
      }
      for (final i in walls) {
        final from = corners[i];
        final to = corners[(i + 1) % corners.length];
        if (from.y == to.y) {
          cutAlong.putIfAbsent(corner, () => []).add(i);
        } else if (from.x == to.x) {
          cutAcross.putIfAbsent(corner, () => []).add(i);
        } else {
          cutAlong.putIfAbsent(corner, () => []).add(i);
        }
      }
    });
    return _WallMap(
      alongLength: alongLength,
      acrossWidth: acrossWidth,
      cutAlong: cutAlong,
      cutAcross: cutAcross,
      shortened: shortened,
    );
  }

  List<_RoomBox> _roomBoxes(BuildContext context, CalculateState state) {
    final appStrings = AppStrings.of(context);
    final cubit = context.read<CalculateCubit>();
    final kind = state.roomKind;
    final walls = _wallsOf(state);

    // What the first two boxes are called. They are the whole room for a
    // rectangle, the first two walls of a quadrilateral, and the bounding size
    // a cut is taken out of.
    final overall = kind.isCut;
    final boxes = <_RoomBox>[
      _RoomBox(
        controller: lengthController,
        inchController: lengthInchController,
        focusNode: lengthFocusNode,
        inchFocusNode: lengthInchFocusNode,
        label: state.unevenWalls
            ? appStrings.wall_length_mm(1)
            : overall
                ? appStrings.overall_length_mm
                : appStrings.length_mm,
        title: state.unevenWalls
            ? appStrings.wall_length(1)
            : overall
                ? appStrings.overall_length
                : appStrings.length,
        minMm: MIN_ROOM_MM,
        maxMm: MAX_LENGTH_MM,
        valueMm: state.roomLength,
        walls: walls.alongLength,
        apply: cubit.setRoomLength,
      ),
      _RoomBox(
        controller: widthController,
        inchController: widthInchController,
        focusNode: widthFocusNode,
        inchFocusNode: widthInchFocusNode,
        label: state.unevenWalls
            ? appStrings.wall_width_mm(1)
            : overall
                ? appStrings.overall_width_mm
                : appStrings.width_mm,
        title: state.unevenWalls
            ? appStrings.wall_width(1)
            : overall
                ? appStrings.overall_width
                : appStrings.width,
        minMm: MIN_ROOM_MM,
        maxMm: MAX_WIDTH_MM,
        valueMm: state.roomWidth,
        walls: walls.acrossWidth,
        apply: cubit.setRoomWidth,
      ),
    ];

    if (state.unevenWalls) {
      boxes.addAll([
        _RoomBox(
          controller: length2Controller,
          inchController: length2InchController,
          focusNode: length2FocusNode,
          inchFocusNode: length2InchFocusNode,
          label: appStrings.wall_length_mm(2),
          title: appStrings.wall_length(2),
          minMm: MIN_ROOM_MM,
          maxMm: MAX_LENGTH_MM,
          valueMm: state.roomLength2,
          walls: walls.farLength,
          apply: cubit.setRoomLength2,
        ),
        _RoomBox(
          controller: width2Controller,
          inchController: width2InchController,
          focusNode: width2FocusNode,
          inchFocusNode: width2InchFocusNode,
          label: appStrings.wall_width_mm(2),
          title: appStrings.wall_width(2),
          minMm: MIN_ROOM_MM,
          maxMm: MAX_WIDTH_MM,
          valueMm: state.roomWidth2,
          walls: walls.farWidth,
          apply: cubit.setRoomWidth2,
        ),
        _RoomBox(
          controller: diagonalController,
          inchController: diagonalInchController,
          focusNode: diagonalFocusNode,
          inchFocusNode: diagonalInchFocusNode,
          label: appStrings.wall_diagonal_mm,
          title: appStrings.wall_diagonal,
          minMm: diagonalMin(state),
          maxMm: diagonalMax(state),
          valueMm: state.roomDiagonal,
          isDiagonal: true,
          apply: cubit.setRoomDiagonal,
        ),
      ]);
      return boxes;
    }

    if (!kind.isCut) return boxes;

    // A cut may be a hand's width, so its boxes have no floor of a whole foot
    // the way a wall does.
    final alongSide = state.cutWall.runsAlongLength ? state.roomLength : state.roomWidth;
    final pair = state.cutWall.corners;
    if (kind.isPaired) {
      // Two shoulders, each measured along the wall the pair stands on, and
      // each bounded by what the other one leaves.
      //
      // Named for what they take out of the room, which is not the same thing
      // in the two shapes that have a pair of them: a chamfer is run across the
      // corner and is a cut, a T's corners are taken out square and are
      // notches. The screen said "cut" for both and then asked for the depth of
      // the *notches* underneath, and the caption below the drawing calls them
      // notches too.
      final shoulder = kind.hasOneLeg ? appStrings.shoulder : appStrings.notch;
      final shoulderMm = kind.hasOneLeg ? appStrings.shoulder_mm : appStrings.notch_mm;
      boxes.add(_RoomBox(
        controller: notchLengthController,
        inchController: notchLengthInchController,
        focusNode: notchLengthFocusNode,
        inchFocusNode: notchLengthInchFocusNode,
        label: shoulderMm(1),
        title: shoulder(1),
        minMm: kind.hasOneLeg ? CornerSize.wallOfLeg(MIN_NOTCH_MM) : MIN_NOTCH_MM,
        maxMm: shoulderMax(alongSide, state.notchLength2),
        valueMm: state.notchLength,
        walls: walls.cutLegOf(pair[0], along: state.cutWall.runsAlongLength),
        derived: walls.shortenedBy(pair[0]),
        minFeet: 0,
        apply: cubit.setNotchLength,
      ));
      boxes.add(_RoomBox(
        controller: notchLength2Controller,
        inchController: notchLength2InchController,
        focusNode: notchLength2FocusNode,
        inchFocusNode: notchLength2InchFocusNode,
        label: shoulderMm(2),
        title: shoulder(2),
        minMm: kind.hasOneLeg ? CornerSize.wallOfLeg(MIN_NOTCH_MM) : MIN_NOTCH_MM,
        maxMm: shoulderMax(alongSide, state.notchLength),
        valueMm: state.notchLength2,
        walls: walls.cutLegOf(pair[1], along: state.cutWall.runsAlongLength),
        derived: walls.shortenedBy(pair[1]),
        minFeet: 0,
        apply: cubit.setNotchLength2,
      ));
    } else {
      // A chamfer is given by the wall it leaves and reaches the same way
      // along both sides, so what bounds it is the shorter of the two — and
      // the bound is stated in the wall's own length, which is what the box
      // asks for.
      final lone = kind.hasOneLeg
          ? math.min(state.roomLength ?? MIN_ROOM_MM, state.roomWidth ?? MIN_ROOM_MM)
          : state.roomLength;
      boxes.add(_RoomBox(
        controller: notchLengthController,
        inchController: notchLengthInchController,
        focusNode: notchLengthFocusNode,
        inchFocusNode: notchLengthInchFocusNode,
        label: kind.hasOneLeg ? appStrings.chamfer_leg_mm : appStrings.notch_length_mm,
        title: kind.hasOneLeg ? appStrings.chamfer_leg : appStrings.notch_length,
        minMm: kind.hasOneLeg ? CornerSize.wallOfLeg(MIN_NOTCH_MM) : MIN_NOTCH_MM,
        maxMm: kind.hasOneLeg
            ? CornerSize.wallOfLeg(notchMax(lone))
            : notchMax(lone),
        valueMm: state.notchLength,
        walls: walls.cutLegOf(state.notchCorner, along: true),
        derived: walls.shortenedBy(state.notchCorner),
        minFeet: 0,
        apply: cubit.setNotchLength,
      ));
    }
    if (!kind.hasOneLeg) {
      // How deep the square cut goes: across the wall for a pair, and down the
      // width for a lone one.
      final into = kind.isPaired
          ? (state.cutWall.runsAlongLength ? state.roomWidth : state.roomLength)
          : state.roomWidth;
      boxes.add(_RoomBox(
        controller: notchWidthController,
        inchController: notchWidthInchController,
        focusNode: notchWidthFocusNode,
        inchFocusNode: notchWidthInchFocusNode,
        label: kind.isPaired ? appStrings.cut_depth_mm : appStrings.notch_width_mm,
        title: kind.isPaired ? appStrings.cut_depth : appStrings.notch_width,
        minMm: MIN_NOTCH_MM,
        maxMm: notchMax(into),
        valueMm: state.notchWidth,
        walls: kind.isPaired
            ? [
                for (final corner in state.cutWall.corners)
                  ...walls.cutLegOf(corner, along: !state.cutWall.runsAlongLength)
              ]
            : walls.cutLegOf(state.notchCorner, along: false),
        derived: kind.isPaired
            ? [for (final corner in state.cutWall.corners) ...walls.shortenedBy(corner)]
            : walls.shortenedBy(state.notchCorner),
        minFeet: 0,
        apply: cubit.setNotchWidth,
      ));
    }
    return boxes;
  }

  // What a cut-away corner is allowed to be, given the overall size typed so
  // far: big enough to be a cut, and small enough to leave a room beside it.
  // Asking the shape itself, as the diagonal's bounds do, means the number the
  // user is shown is the one that actually makes an L.
  int notchMax(int? overall) => LRoomShape.maxNotchLength(overall ?? MIN_ROOM_MM);

  // What one shoulder of a pair may be, given the wall it stands on and what
  // the shoulder at the other end of that wall already takes. The same
  // arithmetic [CutCornersRoomShape.problem] does, so the bound on screen is
  // the one that actually leaves a room between the two cuts.
  int shoulderMax(int? side, int? other) =>
      (side ?? MIN_ROOM_MM) - (other ?? MIN_NOTCH_MM) - CutCornersRoomShape.minArmMm;

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
    // Every room measurement is at least a foot, so the feet box may insist on
    // one. A cut-away corner may be a hand's width, and then it may not.
    int minFeet = MIN_ROOM_FT,
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
                context, value, minFeet, maxWholeFeet(maxMm), appStrings.ft) ==
            null &&
        Validators.sizeValidator(context, inchValue, 0, MAX_INCHES_IN_FOOT, appStrings.inch) ==
            null;
  }

  bool areAllFieldsValid(BuildContext context, CalculateState state) {
    // The same list the boxes are drawn from, so a shape cannot put a box on
    // screen that nothing checks, or check one it never shows.
    for (final box in _roomBoxes(context, state)) {
      if (!roomSizeValid(context, state.system,
          controller: box.controller,
          inchController: box.inchController,
          minMm: box.minMm,
          maxMm: box.maxMm,
          minFeet: box.minFeet)) {
        return false;
      }
    }
    // The last word is the outline's, not the fields': every measurement can
    // be in range and still describe no room. In feet and inches it is the
    // only word, because a box of whole feet cannot carry the bound.
    return state.shape?.problem == null;
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
    required FocusNode? nextFocusNode,
    required int maxFeet,
    required int? valueMm,
    int minFeet = MIN_ROOM_FT,
  }) {
    final appStrings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The title and its boxes are one measurement, so they sit close; what
        // separates one measurement from the next is put between them by
        // [roomFields], which is the only place that knows which is first.
        sizeTitle(title, valueMm == null ? null : formatFeetInches(valueMm)),
        SizedBox(height: kFormGap),
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
              validator: (value) =>
                  Validators.sizeValidator(context, value ?? '', minFeet, maxFeet, appStrings.ft),
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

  /// The room boxes the shape asks for, laid out for the unit system in use:
  /// two to a row in millimetres, one stack of title-and-two-boxes each in feet
  /// and inches. The order is [_roomBoxes]' order, and so is the keyboard's walk
  /// from one to the next.
  List<Widget> roomFields(BuildContext context, CalculateState state) {
    final boxes = _roomBoxes(context, state);
    // The last box has nowhere to send the keyboard on: the laminate is on a
    // screen of its own now, and the Next button is the way to it.
    FocusNode? after(int i) => i + 1 < boxes.length ? boxes[i + 1].focusNode : null;

    if (state.system != MeasurementSystem.metric) {
      return [
        for (var i = 0; i < boxes.length; i++) ...[
          // The same gap as anywhere else on the form, which reads as more than
          // it is: the labels ride on the top border of the boxes, so the air
          // under a title is about 8 px less than the number says, and the air
          // above one is all there. A title is plainly nearer its own boxes
          // than the ones above it without being given a bigger gap to do it.
          if (i > 0) SizedBox(height: kFormGap),
          imperialRoomSize(
            context,
            title: boxes[i].title,
            feetController: boxes[i].controller,
            feetFocusNode: boxes[i].focusNode,
            inchController: boxes[i].inchController,
            inchFocusNode: boxes[i].inchFocusNode,
            nextFocusNode: after(i),
            maxFeet: maxWholeFeet(boxes[i].maxMm),
            valueMm: boxes[i].valueMm,
            minFeet: boxes[i].minFeet,
          ),
        ],
      ];
    }

    Widget metric(int i) => metricRoomSize(
          context,
          controller: boxes[i].controller,
          focusNode: boxes[i].focusNode,
          nextFocusNode: after(i),
          labelText: boxes[i].label,
          minMm: boxes[i].minMm,
          maxMm: boxes[i].maxMm,
          apply: boxes[i].apply,
        );

    final rows = <Widget>[];
    for (var i = 0; i < boxes.length; i += 2) {
      // Between the rows and not above the first: what separates the boxes from
      // the tiles above them is the card's business, and adding to it here
      // would make the two gaps one sum nobody can read off either place.
      if (rows.isNotEmpty) rows.add(const SizedBox(height: kFormGap));
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: metric(i)),
        SizedBox(width: _GAP),
        // An odd box keeps its half of the row rather than stretching across
        // it: a lone number in a full-width box reads as a mistake.
        if (i + 1 < boxes.length) Expanded(child: metric(i + 1)) else Spacer(),
      ]));
    }
    return rows;
  }

  /// What the chosen shape is called, in the user's own language.
  ///
  /// A chain rather than a switch. The shapes are classes now and nothing a
  /// 2.18 switch does with those is worth having: without a `default` the
  /// method would not compile, and with one a shape nobody wrote a branch for
  /// would quietly borrow another's name. A chain ends the same way, so the
  /// guarantee is bought back in the test that walks [RoomKind.values] and
  /// insists every shape has a name of its own.
  String roomKindName(BuildContext context, RoomKind kind) {
    final appStrings = AppStrings.of(context);
    if (kind == RoomKind.rectangle) return appStrings.shape_rectangle;
    if (kind == RoomKind.uneven) return appStrings.uneven_walls;
    if (kind == RoomKind.chamfer) return appStrings.shape_chamfer;
    if (kind == RoomKind.chamferPair) return appStrings.shape_chamfer_pair;
    if (kind == RoomKind.lShaped) return appStrings.shape_l;
    return appStrings.shape_t;
  }

  /// What the room is, as a row of shapes rather than a line of words.
  ///
  /// This was a dropdown while there were three shapes, chosen because three
  /// segmented buttons on a 360 dp phone leave about a word each and "Wände
  /// unterschiedlicher Länge" is not a word. Six shapes would be six lines of
  /// prose in a menu nobody opens, and the shapes are the one thing here that
  /// needs no translating: a user looking for the room they are standing in
  /// recognises it faster than they read it. A row of outlines has no three-item
  /// ceiling, and it shows the trapezium and the parallelogram that the engine
  /// has always been able to lay and the word "uneven walls" never admitted to.
  ///
  /// All six on one line, with the name of the chosen one under the row. Two
  /// rows of three were what six captions cost; one caption buys the line back
  /// and leaves every shape in sight at once.
  Widget roomKindField(BuildContext context, CalculateState state) {
    // The caption is one line and the row below it must not move as the name
    // changes, so the line is reserved at the height one line of it takes —
    // which is the font size the user asked for, not the one written here.
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(_CAPTION_SIZE) * _CAPTION_HEIGHT;
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = RoomKind.values.length;
        final width = constraints.maxWidth;
        final cell = (width - _TILE_GAP * (perRow - 1)) / perRow;
        // The square is the cell, up to a ceiling: on a tablet a sixth of the
        // card is still a thumb wide, and a button much bigger than that reads
        // as a picture of something rather than as something to press.
        final side = math.min(cell, _TILE_MAX);
        // Spread rather than packed, so the first tile is flush with the left
        // edge of the boxes below and the last with their right. Only visible
        // once the squares stop filling their cells — on a phone they fill them
        // exactly. The tiles then stand one [step] apart, which is what the
        // caption below needs to find the one it names.
        final step = (width - side) / (perRow - 1);
        final chosen = RoomKind.values.indexOf(state.roomKind);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No heading over the tiles. Six little rooms under the word "Room"
            // are a row of rooms to choose from however they are captioned, and
            // the caption only pushed the first box of the form further down the
            // screen. Laid out rather than scrolled. A row that has to be
            // scrolled hides whatever is off the end of it — which is how a user
            // with a T-shaped room would never learn the calculator takes one.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final kind in RoomKind.values)
                  shapeTile(context, kind, kind == state.roomKind, side),
              ],
            ),
            SizedBox(height: 6),
            // One caption for the row, under the tile it names. Six names under
            // six tiles is what forced the shapes into two rows: a sixth of a
            // 360 dp card is about four characters, and "Wände unterschiedlicher
            // Länge" is not four characters in any language we ship. Named one
            // at a time the caption has the whole card to itself, so it is read
            // rather than guessed at — and the five shapes nobody picked say
            // what they are by their outline, which is what they were drawn for.
            SizedBox(
              height: lineHeight,
              child: CustomSingleChildLayout(
                delegate: _CaptionUnder(chosen * step + side / 2),
                child: Text(
                  roomKindName(context, state.roomKind),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _CAPTION_SIZE,
                    height: _CAPTION_HEIGHT,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// One shape to choose: its outline, boxed, and blue when it is the shape the
  /// room is. What it is called is written once under the row — see
  /// [roomKindField].
  ///
  /// The box is square. A tile as wide as its share of the card and only as tall
  /// as an outline needs came out a letterbox, and a letterbox is the one shape
  /// a room cannot be — it read as a wide room rather than as a button. Square
  /// says nothing about the room and leaves the outline inside it room to be
  /// the thing that does.
  Widget shapeTile(BuildContext context, RoomKind kind, bool chosen, double side) {
    return GestureDetector(
      // The shape itself is the key. Each is a const instance and there is one
      // of each, so it identifies its tile as well as a name would and cannot
      // drift from the shape it stands for the way a hand-written string can.
      key: ValueKey(kind),
      behavior: HitTestBehavior.opaque,
      onTap: () => setRoomKind(context, kind),
      child: Semantics(
        button: true,
        selected: chosen,
        label: roomKindName(context, kind),
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_TILE_RADIUS),
            border: Border.all(
              color: chosen ? Colors.blue : Colors.black.withValues(alpha: 0.2),
              width: chosen ? 2 : 1,
            ),
            color: chosen ? Colors.blue.withValues(alpha: 0.06) : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(side * 0.16),
            child: CustomPaint(
              painter: RoomKindIcon(
                corners: kindIconCorners(kind),
                colour: chosen ? Colors.blue : Colors.black54,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }

  /// The outline each tile draws, in a unit square with y running down.
  ///
  /// Drawn from a fixed little shape rather than from the user's own room: the
  /// tile has to be recognisable before any measurement is typed, and a room
  /// 6 m by 1.2 m would make every tile a line.
  ///
  /// A table on the screen rather than a getter on [RoomKind]: these are the
  /// picker's drawings, not the room's — the T here is the letter, and no
  /// measurement would ever produce it. Kept as one list so that all six can be
  /// read against each other, which is how they were drawn.
  ///
  /// Not the third of a side a real cut defaults to: a third of a 40 dp square
  /// is barely a nick, and the tile's one job is to be recognised across the
  /// row.
  static const double _ICON_CUT = 0.34;
  static const Map<RoomKind, List<Offset>> _ICON_CORNERS = {
    RoomKind.rectangle: [Offset(0, 0), Offset(1, 0), Offset(1, 1), Offset(0, 1)],
    RoomKind.uneven: [Offset(0, 0.1), Offset(1, 0), Offset(0.92, 1), Offset(0.06, 0.88)],
    RoomKind.chamfer: [
      Offset(0, 0), Offset(1, 0), Offset(1, 1 - _ICON_CUT), Offset(1 - _ICON_CUT, 1), Offset(0, 1)
    ],
    RoomKind.chamferPair: [
      Offset(_ICON_CUT, 0), Offset(1 - _ICON_CUT, 0), Offset(1, _ICON_CUT), Offset(1, 1), Offset(0, 1), Offset(0, _ICON_CUT)
    ],
    RoomKind.lShaped: [
      Offset(0, 0), Offset(1, 0), Offset(1, 1 - _ICON_CUT), Offset(1 - _ICON_CUT, 1 - _ICON_CUT),
      Offset(1 - _ICON_CUT, 1), Offset(0, 1)
    ],
    RoomKind.tShaped: [
      Offset(_ICON_CUT, 0), Offset(1 - _ICON_CUT, 0), Offset(1 - _ICON_CUT, _ICON_CUT), Offset(1, _ICON_CUT),
      Offset(1, 1), Offset(0, 1), Offset(0, _ICON_CUT), Offset(_ICON_CUT, _ICON_CUT)
    ],
  };

  // Read with a `!`: a shape added to [RoomKind.values] and forgotten here
  // fails the first widget test that builds the row, rather than quietly
  // drawing somebody else's room.
  List<Offset> kindIconCorners(RoomKind kind) => _ICON_CORNERS[kind]!;

  // The sketch that says which wall is which and which corner is cut, and the
  // one thing the fields cannot say on their own: that the measurements
  // describe no room at all.
  Widget roomSketch(BuildContext context, CalculateState state) {
    final appStrings = AppStrings.of(context);
    final shape = state.shape;
    if (state.roomKind == RoomKind.rectangle || shape == null) {
      return const SizedBox.shrink();
    }
    final problem = shape.problem;
    // Which numbers on the drawing are guesses, and which one is being typed.
    // Both come off the same list the boxes are built from, so a box and the
    // number beside its wall cannot disagree about which is which.
    final boxes = _roomBoxes(context, state);
    final unknownWalls = <int>{};
    final litWalls = <int>{};
    var unknownDiagonal = false;
    var litDiagonal = false;
    for (final box in boxes) {
      // Empty rather than unparsed: a half-typed number is still the user
      // telling us something, and blanking it out mid-keystroke would make the
      // drawing flicker between a number and a question mark.
      if (box.valueMm == null) {
        unknownWalls.addAll(box.walls);
        // And what the room worked out from it: a wall shortened by a cut
        // nobody has typed is as much of a guess as the cut.
        unknownWalls.addAll(box.derived);
        unknownDiagonal |= box.isDiagonal;
      }
      if (box.focusNode.hasFocus || box.inchFocusNode.hasFocus) {
        litWalls.addAll(box.walls);
        litDiagonal |= box.isDiagonal;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The drawing is not another row of the form, so it keeps a section's
        // worth of air above it.
        SizedBox(height: kFormSectionGap),
        RoomSketch(
          shape: shape,
          system: state.system,
          cutCorner:
              state.cutCorners && !state.roomKind.isPaired ? state.notchCorner : null,
          cutWall: state.cutCorners && state.roomKind.isPaired ? state.cutWall : null,
          onCorner: state.cutCorners && !state.roomKind.isPaired
              ? (corner) => context.read<CalculateCubit>().setNotchCorner(corner)
              : null,
          onWall: state.cutCorners && state.roomKind.isPaired
              ? (wall) => context.read<CalculateCubit>().setCutWall(wall)
              : null,
          unknownWalls: unknownWalls,
          unknownDiagonal: unknownDiagonal,
          litWalls: litWalls,
          litDiagonal: litDiagonal,
        ),
        if (state.cutCorners && problem == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state.roomKind.isPaired
                  ? appStrings.tap_wall_to_cut
                  : appStrings.tap_corner_to_cut,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 13),
            ),
          ),
        if (problem != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state.cutCorners ? appStrings.notch_does_not_fit : appStrings.walls_do_not_close,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings.of(context);

    return BlocBuilder<CalculateCubit, CalculateState>(
      builder: (context, state) {
        return ParametersCard(
          title: appStrings.room,
          icon: Icons.home_filled,
          canProceed: areAllFieldsValid(context, state),
          onNext: () => context.router.push(LaminateParametersRoute()),
          onSettings: () => openSettings(context),
          children: [
            // Above the sizes, because it decides what they are called: a
            // length, a first wall, or an overall length a cut is taken out of.
            SizedBox(height: _GAP),
            roomKindField(context, state),
            // A section's worth of air under the tiles, not a row's. What is
            // above the line is a choice already made and what is below it is
            // the typing still to do; the shape names and the field labels are
            // both small grey text, and without the gap the two blocks read as
            // one list.
            SizedBox(height: kFormSectionGap),
            ...roomFields(context, state),
            roomSketch(context, state),
          ],
        );
      },
    );
  }
}

/// One room measurement the shape asks for: the boxes it is typed into on
/// either side of the unit system, what it is called in each, what it is
/// allowed to be, and where the number goes when it changes.
///
/// The form used to pick all of this with a nested ternary per shape, repeated
/// at eight sites. Three shapes fitted that way; six do not, and a seventh
/// would have to be written into every one of the eight again. So a shape now
/// says what its boxes are once, in [RoomParametersScreenState
/// ._roomBoxes], and the rest of the form reads the list.
class _RoomBox {
  final TextEditingController controller;
  final TextEditingController inchController;
  final FocusNode focusNode;
  final FocusNode inchFocusNode;

  /// Two names, not one with a unit stuck on: in millimetres the unit rides in
  /// the field's own label, and in feet and inches a title sits above a pair of
  /// boxes that are labelled ft and in. Every other label in this form is
  /// translated as both, and these are no different.
  final String label;
  final String title;

  final int minMm;
  final int maxMm;
  final int? valueMm;

  /// Which walls of the sketch carry this measurement. Empty for a box that
  /// nothing on the drawing is labelled with.
  final List<int> walls;

  /// Walls whose number is worked out from this one. Not lit when the cursor is
  /// here — they are not this measurement — but as much a guess as it is while
  /// the box is empty.
  final List<int> derived;

  /// Whether this is the diagonal, which is drawn as a dashed line across the
  /// room rather than as a wall and so is pointed at separately.
  final bool isDiagonal;

  /// Every wall of a room is at least a foot, so its feet box may insist on
  /// one. A cut may be a hand's width, and then it may not.
  final int minFeet;

  final void Function(int) apply;

  const _RoomBox({
    required this.controller,
    required this.inchController,
    required this.focusNode,
    required this.inchFocusNode,
    required this.label,
    required this.title,
    required this.minMm,
    required this.maxMm,
    required this.valueMm,
    required this.apply,
    this.walls = const [],
    this.derived = const [],
    this.isDiagonal = false,
    this.minFeet = MIN_ROOM_FT,
  });
}

/// Puts the caption under the tile it names: centred on [centre], and shifted
/// back inside the card when the name is wider than the room left beside it.
///
/// A delegate rather than an [Align], because where the line goes depends on how
/// wide the text came out — "Т-образное" centred under the last tile would hang
/// off the right edge of the card, and the first tile's centre is 20 dp from the
/// left, which is less than half of any name we have. Nothing else in the frame
/// knows the text's width, and this is the one place that is told it.
class _CaptionUnder extends SingleChildLayoutDelegate {
  final double centre;

  const _CaptionUnder(this.centre);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
        (centre - childSize.width / 2).clamp(0.0, math.max(0.0, size.width - childSize.width)),
        0,
      );

  @override
  bool shouldRelayout(_CaptionUnder old) => old.centre != centre;
}

/// One shape tile: an outline given in a unit square, drawn to fill whatever
/// box it is put in and hatched the way a plan is.
///
/// Its own painter rather than [RoomSketch], which draws a room to scale with
/// every wall measured. A tile has no measurements and no scale — it is a
/// pictogram, and 48 dp of pictogram has room for an outline and nothing else.
class RoomKindIcon extends CustomPainter {
  final List<Offset> corners;
  final Color colour;

  const RoomKindIcon({required this.corners, required this.colour});

  /// How much wider than tall the outline is drawn. The tile is square and the
  /// outline must not be, or a rectangular room comes out a square one and the
  /// first tile stops saying what it is for. Rooms are wider than they are deep
  /// more often than not, and four to three is the shallowest that reads as
  /// deliberate.
  static const double aspect = 4 / 3;

  @override
  void paint(Canvas canvas, Size size) {
    // The widest box of that shape that fits, centred in what there is.
    final width = math.min(size.width, size.height * aspect);
    final height = width / aspect;
    final origin = Offset((size.width - width) / 2, (size.height - height) / 2);

    final path = Path();
    Offset at(Offset p) => origin + Offset(p.dx * width, p.dy * height);
    path.moveTo(at(corners.first).dx, at(corners.first).dy);
    for (final corner in corners.skip(1)) {
      path.lineTo(at(corner).dx, at(corner).dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = colour.withValues(alpha: 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = colour,
    );
  }

  @override
  bool shouldRepaint(RoomKindIcon old) =>
      old.colour != colour || old.corners != corners;
}

/// Which walls of the sketch each kind of measurement is written beside.
///
/// Indices into [RoomOutline.wallLengths], which is also the order the sketch
/// labels them in. Built once per rebuild by
/// [RoomParametersScreenState._wallsOf] and handed to the boxes, so that the
/// mapping from a box to the number beside a wall is written down in one place
/// instead of being guessed at wherever it is wanted.
class _WallMap {
  /// Walls of the bounding rectangle that run along the room's length, and the
  /// ones that run across it. More than one of each where a cut has broken a
  /// wall into two pieces.
  final List<int> alongLength;
  final List<int> acrossWidth;

  /// The far wall and the far side of a room measured wall by wall, which has
  /// four walls all of its own and no bounding rectangle to speak of.
  final List<int> farLength;
  final List<int> farWidth;

  /// Per cut corner, the leg measured along the room's length and the one
  /// measured across it. A chamfer has one wall for its one leg and it is
  /// filed under [cutAlong].
  final Map<RoomCorner, List<int>> cutAlong;
  final Map<RoomCorner, List<int>> cutAcross;

  /// Per cut corner, the two bounding walls that cut has shortened. Theirs are
  /// the numbers the room worked out, so no box is written on them — but a box
  /// left empty leaves them guesses too.
  final Map<RoomCorner, List<int>> shortened;

  const _WallMap({
    this.alongLength = const [],
    this.acrossWidth = const [],
    this.farLength = const [],
    this.farWidth = const [],
    this.cutAlong = const {},
    this.cutAcross = const {},
    this.shortened = const {},
  });

  /// The wall a cut's leg is written on, whichever way round the cut is.
  List<int> cutLegOf(RoomCorner corner, {required bool along}) =>
      (along ? cutAlong : cutAcross)[corner] ?? const [];

  /// What that cut also makes a guess of while it is not typed.
  List<int> shortenedBy(RoomCorner corner) => shortened[corner] ?? const [];
}
