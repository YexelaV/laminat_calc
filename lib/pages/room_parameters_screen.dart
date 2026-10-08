import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/room_cubit.dart';
import 'package:floor_calculator/cubit/settings_cubit.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/l10n/gen/app_localizations.dart';
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

// A shape tile is square and takes its share of the card, up to this. Beyond it
// the button stops reading as a button — the outline inside has long since been
// as clear as it is going to get.
const double _TILE_MAX = 60;

// How many shapes go on a line before the next one starts.
//
// The width of the card divided by this is what a tile gets, and four is as far
// as that can be pushed: inside the card there are 280 dp on a 360 dp phone, so
// four tiles are 64 dp and seven on one line would be 33 — under the smallest
// thing a thumb is asked to hit. The row was one line while there were six
// shapes and it was 40 dp a tile, which was already the floor rather than the
// plan.
const int _TILES_PER_ROW = 4;

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

/// One measurement the room form asked for: what it is called, and what was
/// typed into it.
class RoomMeasurement {
  final String title;
  final int? valueMm;

  const RoomMeasurement(this.title, this.valueMm);
}

/// Every measurement the room form asks for, in the order it asks them, for
/// whatever shape the room is.
///
/// The same list the boxes are built from, said twice: once here as names and
/// values, and once in [RoomParametersScreenState._roomBoxes] as boxes with
/// controllers and bounds. They are kept apart because the review screen wants
/// no controllers and the form wants nothing else, and kept honest by
/// test/review_screen_test.dart, which walks every shape and insists the two
/// lists are the same length with the same names. A shape measured on one
/// screen and missed on the other fails there rather than on a user's phone.
List<RoomMeasurement> roomMeasurements(
    AppLocalizations appStrings, RoomState state) {
  final kind = state.roomKind;
  final overall = kind.isCut;
  final out = <RoomMeasurement>[
    RoomMeasurement(
      state.unevenWalls
          ? appStrings.wall_length_near
          : overall
              ? appStrings.overall_length
              : appStrings.length,
      state.roomLength,
    ),
    RoomMeasurement(
      state.unevenWalls
          ? appStrings.wall_width_left
          : overall
              ? appStrings.overall_width
              : appStrings.width,
      state.roomWidth,
    ),
  ];

  if (state.unevenWalls) {
    out.add(RoomMeasurement(appStrings.wall_length_far, state.roomLength2));
    out.add(RoomMeasurement(appStrings.wall_width_right, state.roomWidth2));
    out.add(RoomMeasurement(appStrings.wall_diagonal, state.roomDiagonal));
    return out;
  }
  if (!kind.isCut) return out;

  // A room measured by the piece in the middle of its cut wall is two numbers
  // rather than three or four, and they are the ones the form asked for — see
  // the boxes, where the reasons are.
  final across = kind.isPaired && !state.cutWall.runsAlongLength;
  final reach = [state.notchLength, state.notchLength2];
  if (kind.isWallNotch) {
    if (kind.symmetricStem(state)) {
      out.add(RoomMeasurement(
          across ? appStrings.notch_width : appStrings.notch_length, state.midSpan));
      out.add(RoomMeasurement(
          across ? appStrings.notch_length : appStrings.notch_width, state.notchWidth));
      return out;
    }
    final leg = across ? appStrings.stub_width_n : appStrings.stub_length_n;
    out.add(RoomMeasurement(leg(1), state.notchLength));
    out.add(RoomMeasurement(leg(2), state.notchLength2));
    out.add(RoomMeasurement(
        across ? appStrings.stub_length : appStrings.stub_width, state.notchWidth));
    return out;
  }

  // The names the form asks for them under — see the boxes, where the reasons
  // are: a chamfer's pair is named by side rather than by number, and a notch's
  // two sizes are named for the room's axes, which swap over when the pair is
  // moved onto a side wall.
  final acrossWall = across;
  if (kind.symmetricStem(state)) {
    out.add(RoomMeasurement(
        acrossWall ? appStrings.stub_width : appStrings.stub_length, state.midSpan));
    out.add(RoomMeasurement(
        acrossWall ? appStrings.stub_length : appStrings.stub_width, state.notchWidth));
    return out;
  }
  if (kind.isPaired) {
    final legs = state.cutWall.runsAlongLength
        ? [appStrings.chamfer_leg_left, appStrings.chamfer_leg_right]
        : [appStrings.chamfer_leg_near, appStrings.chamfer_leg_far];
    final shoulder = acrossWall ? appStrings.notch_width_n : appStrings.notch_length_n;
    for (var i = 0; i < 2; i++) {
      out.add(RoomMeasurement(kind.hasOneLeg ? legs[i] : shoulder(i + 1), reach[i]));
    }
  } else if (kind.cutCount > 1) {
    for (var i = 0; i < 2; i++) {
      out.add(RoomMeasurement(appStrings.notch_length_n(i + 1), reach[i]));
    }
  } else {
    out.add(RoomMeasurement(
      kind.hasOneLeg ? appStrings.chamfer_leg : appStrings.notch_length,
      state.notchLength,
    ));
  }

  if (!kind.hasOneLeg) {
    final depth = [state.notchWidth, state.notchWidth2];
    for (var i = 0; i < kind.cutCount; i++) {
      out.add(RoomMeasurement(
        kind.cutCount == 1
            ? appStrings.notch_width
            : acrossWall
                ? appStrings.notch_length_n(i + 1)
                : appStrings.notch_width_n(i + 1),
        depth[i],
      ));
    }
  }
  return out;
}

/// What a shape is called, in the user's own language.
///
/// A free function because two screens name these: the form, under the tile
/// that is lit, and the review, beside the room it is about.
String roomKindNameOf(AppLocalizations appStrings, RoomKind kind) {
    if (kind == RoomKind.rectangle) return appStrings.shape_rectangle;
    if (kind == RoomKind.uneven) return appStrings.uneven_walls;
    if (kind == RoomKind.chamfer) return appStrings.shape_chamfer;
    if (kind == RoomKind.chamferPair) return appStrings.shape_chamfer_pair;
    if (kind == RoomKind.lShaped) return appStrings.shape_l;
    if (kind == RoomKind.tShaped) return appStrings.shape_t;
    if (kind == RoomKind.zShaped) return appStrings.shape_z;
    return appStrings.shape_u;
}

/// The outline a shape is drawn as, for anything that wants to draw one.
List<Offset> roomKindIconCorners(RoomKind kind) =>
    RoomParametersScreenState._ICON_CORNERS[kind]!;

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
  final notchWidth2FocusNode = FocusNode();
  final notchWidth2InchFocusNode = FocusNode();
  final midSpanFocusNode = FocusNode();
  final midSpanInchFocusNode = FocusNode();

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
  final notchWidth2Controller = TextEditingController();
  final notchWidth2InchController = TextEditingController(text: '0');
  final midSpanController = TextEditingController();
  final midSpanInchController = TextEditingController(text: '0');

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
        notchWidth2Controller,
        notchWidth2InchController,
        midSpanController,
        midSpanInchController,
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
        notchWidth2FocusNode,
        notchWidth2InchFocusNode,
        midSpanFocusNode,
        midSpanInchFocusNode,
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
    notchWidth2Controller.dispose();
    notchWidth2InchController.dispose();
    midSpanController.dispose();
    midSpanInchController.dispose();
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
    notchWidth2FocusNode.dispose();
    notchWidth2InchFocusNode.dispose();
    midSpanFocusNode.dispose();
    midSpanInchFocusNode.dispose();
    super.dispose();
  }

  // Rewrites the field texts from the canonical state, which is always
  // millimetres, so that values already entered survive a change of units.
  void rewriteFieldsFor(MeasurementSystem system, RoomState state) {
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
    setRoomField(state.notchWidth2, notchWidth2Controller, notchWidth2InchController);
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
  // [RoomState.notchLength] — and clamped into the new shape's bounds,
  // which is not a guess but the arithmetic of the shape they just picked: a
  // cut that was legal as the only one on its wall may be too deep to share it.
  void setRoomKind(BuildContext context, RoomKind kind) {
    final cubit = context.read<RoomCubit>();
    final state = cubit.state;
    final length = state.roomLength;
    final width = state.roomWidth;
    if (length != null && width != null && kind.isCut) {
      final alongWall = state.cutWall.runsAlongLength;
      final along = alongWall ? length : width;
      final into = kind.isPaired ? (alongWall ? width : length) : width;
      final lone = kind.hasOneLeg ? math.min(length, width) : length;
      final floor = kind.hasOneLeg ? CornerSize.wallOfLeg(MIN_NOTCH_MM) : MIN_NOTCH_MM;
      // How far a cut may reach in the shape being moved to. A pair standing on
      // one wall divides it, so each gets a share; a lone cut and a pair across
      // the room are each held off the far side of the room on their own,
      // because nothing holds two opposite cuts apart until they actually meet
      // — and the sketch says so when they do.
      final reach = kind.isPaired
          ? heldBetween(along ~/ 4, floor, shoulderMax(along, MIN_NOTCH_MM))
          : kind.hasOneLeg
              ? CornerSize.wallOfLeg(notchMax(lone))
              : notchMax(lone);
      // [heldBetween] rather than clamp: a room may be small enough that no cut
      // fits in it at all, and then the ceiling lands under the floor. What is
      // carried over is the smallest cut there is, and the sketch says it does
      // not fit.
      void carry(int? typed, void Function(int) set, int least, int most) {
        if (typed != null) set(heldBetween(typed, least, most));
      }

      // A notch in a wall measures the floor it leaves rather than the cut it
      // takes, so the same three numbers mean something else and are held
      // against something else — what is left for the notch between the two
      // ends, and what is left under it.
      if (kind.isWallNotch) {
        final across = alongWall ? width : length;
        carry(state.notchLength, cubit.setNotchLength, MIN_NOTCH_MM,
            WallNotchRoomShape.maxOffset(along, MIN_NOTCH_MM));
        carry(state.notchLength2, cubit.setNotchLength2, MIN_NOTCH_MM,
            WallNotchRoomShape.maxOffset(along, MIN_NOTCH_MM));
        carry(state.notchWidth, cubit.setNotchWidth, MIN_NOTCH_MM,
            WallNotchRoomShape.maxDepth(across));
        cubit.setRoomKind(kind);
        rewriteFieldsFor(context.read<SettingsCubit>().state.system, cubit.state);
        return;
      }

      carry(state.notchLength, cubit.setNotchLength, floor, reach);
      if (kind.cutCount > 1) {
        carry(state.notchLength2, cubit.setNotchLength2, floor, reach);
      }
      if (!kind.hasOneLeg) {
        carry(state.notchWidth, cubit.setNotchWidth, MIN_NOTCH_MM, notchMax(into));
        if (kind.cutCount > 1) {
          carry(state.notchWidth2, cubit.setNotchWidth2, MIN_NOTCH_MM, notchMax(into));
        }
      }
    }
    cubit.setRoomKind(kind);
    rewriteFieldsFor(context.read<SettingsCubit>().state.system, cubit.state);
  }

  void openSettings(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SettingsSheet(
          onSystemChanged: (system) {
            final settings = context.read<SettingsCubit>();
            if (system == settings.state.system) return;
            // The boxes hold text in the old unit and the cubit holds
            // millimetres, so the text is rewritten before the setting moves —
            // otherwise the rebuild lands on a form reading feet as metres.
            rewriteFieldsFor(system, context.read<RoomCubit>().state);
            settings.setSystem(system);
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

    final cubit = context.read<RoomCubit>();
    apply(lengthController, lengthInchController, cubit.setRoomLength);
    apply(widthController, widthInchController, cubit.setRoomWidth);
    apply(length2Controller, length2InchController, cubit.setRoomLength2);
    apply(width2Controller, width2InchController, cubit.setRoomWidth2);
    apply(diagonalController, diagonalInchController, cubit.setRoomDiagonal);
    apply(notchLengthController, notchLengthInchController, cubit.setNotchLength);
    apply(notchLength2Controller, notchLength2InchController, cubit.setNotchLength2);
    apply(notchWidthController, notchWidthInchController, cubit.setNotchWidth);
    apply(notchWidth2Controller, notchWidth2InchController, cubit.setNotchWidth2);
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
  _WallMap _wallsOf(RoomState state) {
    final shape = state.shape;
    if (shape == null) return const _WallMap();
    if (shape is RoomShape) {
      // [RoomShape.wallLengths] is near, right, far, left, in that order.
      return const _WallMap(alongLength: [0], acrossWidth: [3], farLength: [2], farWidth: [1]);
    }
    if (shape is WallNotchRoomShape) return _notchWalls(shape);
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

  /// The same, for the room whose missing piece is in a wall rather than a
  /// corner.
  ///
  /// Its own walk because nothing here is keyed to a corner: a notch belongs to
  /// a wall, and what the form asks about it are the two pieces of that wall it
  /// leaves. The ring [WallNotchRoomShape] builds puts the notch's four points
  /// straight after the corner its wall starts at, so where they are is known
  /// rather than searched for.
  _WallMap _notchWalls(WallNotchRoomShape shape) {
    final corners = shape.corners();
    final n = corners.length;
    // One point per corner before the notch's wall, so the notch's own first
    // point lands one past the wall's index.
    final start = shape.wall.index + 1;
    final notch = [for (var i = 0; i < 5; i++) (start - 1 + i) % n];

    // The near and right walls are walked from the corner the first offset is
    // measured at; the far and left ones are walked backwards, so the piece the
    // walk meets first is the one the *second* offset measures.
    final forwards = shape.wall == RoomWall.near || shape.wall == RoomWall.right;
    final ends = forwards ? [notch[0], notch[4]] : [notch[4], notch[0]];

    final taken = notch.toSet();
    final alongLength = <int>[];
    final acrossWidth = <int>[];
    for (var i = 0; i < n; i++) {
      if (taken.contains(i)) continue;
      final from = corners[i];
      final to = corners[(i + 1) % n];
      final flat = from.y == to.y;
      // The overall size owns the wall that *is* that size. The wall the notch
      // is cut into is in two pieces and neither of them is, which is exactly
      // right: those two are the user's own numbers and have boxes of their own.
      final span = flat ? (to.x - from.x).abs() : (to.y - from.y).abs();
      if (span != (flat ? shape.length : shape.width).toDouble()) continue;
      (flat ? alongLength : acrossWidth).add(i);
    }

    return _WallMap(
      alongLength: alongLength,
      acrossWidth: acrossWidth,
      notchEnds: ends,
      notchLegs: [notch[1], notch[3]],
      notchSpan: [notch[2]],
    );
  }

  List<_RoomBox> _roomBoxes(BuildContext context, RoomState state) {
    final appStrings = AppStrings.of(context);
    final cubit = context.read<RoomCubit>();
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
            ? appStrings.wall_length_near_mm
            : overall
                ? appStrings.overall_length_mm
                : appStrings.length_mm,
        title: state.unevenWalls
            ? appStrings.wall_length_near
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
            ? appStrings.wall_width_left_mm
            : overall
                ? appStrings.overall_width_mm
                : appStrings.width_mm,
        title: state.unevenWalls
            ? appStrings.wall_width_left
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
          label: appStrings.wall_length_far_mm,
          title: appStrings.wall_length_far,
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
          label: appStrings.wall_width_right_mm,
          title: appStrings.wall_width_right,
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

    // A notch in the middle of a wall asks for the same three numbers a pair of
    // cuts on one wall does and means the opposite by them: not what is taken
    // off each end, but what is left there. So it is measured and bounded on
    // its own terms rather than borrowed from the branch below, and the one
    // thing it shares is the boxes those numbers are typed into.
    if (kind.isWallNotch) {
      final along = state.cutWall.runsAlongLength ? state.roomLength : state.roomWidth;
      final across = state.cutWall.runsAlongLength ? state.roomWidth : state.roomLength;
      final acrossWall = !state.cutWall.runsAlongLength;
      final symmetric = kind.symmetricStem(state);
      // Centred, the notch is measured itself: how far it runs along the wall
      // and how deep it goes. Off centre, the two legs either side of it are
      // what is measured instead and the notch between them is what is left —
      // where the notch sits being the one thing a centred one has no room to
      // say.
      if (symmetric) {
        boxes.add(_RoomBox(
          controller: midSpanController,
          inchController: midSpanInchController,
          focusNode: midSpanFocusNode,
          inchFocusNode: midSpanInchFocusNode,
          label: acrossWall ? appStrings.notch_width_mm : appStrings.notch_length_mm,
          title: acrossWall ? appStrings.notch_width : appStrings.notch_length,
          minMm: MIN_NOTCH_MM,
          maxMm: WallNotchRoomShape.maxSpan(along ?? MIN_ROOM_MM),
          valueMm: state.midSpan,
          walls: walls.notchSpan,
          derived: walls.notchEnds,
          minFeet: 0,
          apply: cubit.setMidSpan,
        ));
      } else {
        // The two legs, each by how far it runs along the wall.
        final ends = [state.notchLength, state.notchLength2];
        final apply = [cubit.setNotchLength, cubit.setNotchLength2];
        final leg = acrossWall ? appStrings.stub_width_n : appStrings.stub_length_n;
        final legMm =
            acrossWall ? appStrings.stub_width_n_mm : appStrings.stub_length_n_mm;
        for (var i = 0; i < 2; i++) {
          boxes.add(_cutBox(
            slot: i,
            reach: true,
            walls: i < walls.notchEnds.length ? [walls.notchEnds[i]] : const [],
            // The notch between them is what the room works out from the pair,
            // so it is a guess while either of them is.
            derived: walls.notchSpan,
            label: legMm(i + 1),
            title: leg(i + 1),
            minMm: MIN_NOTCH_MM,
            // Bounded by what the other leg already takes and by the notch that
            // has to be left between them.
            maxMm: WallNotchRoomShape.maxOffset(along ?? MIN_ROOM_MM, ends[1 - i]),
            valueMm: ends[i],
            apply: apply[i],
          ));
        }
      }
      // How far the legs come out, which is the same thing as how deep the
      // notch goes — one number either way round. Not one per leg: the two
      // stand on one crossbar, so a second box would be a second name for the
      // first, and two names for one number is a form that can disagree with
      // itself.
      boxes.add(_RoomBox(
        controller: notchWidthController,
        inchController: notchWidthInchController,
        focusNode: notchWidthFocusNode,
        inchFocusNode: notchWidthInchFocusNode,
        label: symmetric
            ? (acrossWall ? appStrings.notch_length_mm : appStrings.notch_width_mm)
            : (acrossWall ? appStrings.stub_length_mm : appStrings.stub_width_mm),
        title: symmetric
            ? (acrossWall ? appStrings.notch_length : appStrings.notch_width)
            : (acrossWall ? appStrings.stub_length : appStrings.stub_width),
        minMm: MIN_NOTCH_MM,
        maxMm: WallNotchRoomShape.maxDepth(across ?? MIN_ROOM_MM),
        valueMm: state.notchWidth,
        walls: walls.notchLegs,
        minFeet: 0,
        apply: cubit.setNotchWidth,
      ));
      return boxes;
    }

    // Which corner each cut sits in, numbered the way the boxes are. A pair
    // standing on one wall is numbered along that wall; a lone cut is the
    // tapped corner itself; a pair across the room is numbered left to right,
    // starting from whichever of its two corners is the left one.
    //
    // Left to right because the boxes are read down the screen beside the
    // drawing: a "cut 1" that changed sides when the pair was tapped across the
    // room would have the user typing into the box for the other end of the
    // floor. [RoomCornerSides.leftOfPair] is where that is decided, and the
    // outline is built the same way round, so the two cannot drift.
    final corners = kind.isPaired
        ? state.cutWall.corners
        : kind.cutCount > 1
            ? [state.notchCorner.leftOfPair, state.notchCorner.leftOfPair.opposite]
            : [state.notchCorner];
    final reachTyped = [state.notchLength, state.notchLength2];
    final reachApply = [cubit.setNotchLength, cubit.setNotchLength2];

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
      //
      // A chamfer's pair is named by which of the two it is on the drawing, not
      // 1 and 2. The wall they stand on is chosen by tapping, so a number named
      // nothing the user could point at; [RoomWallCorners.corners] runs the
      // pair left to right along the near and far walls and top to bottom down
      // the other two, and these names follow it.
      final legs = state.cutWall.runsAlongLength
          ? [appStrings.chamfer_leg_left, appStrings.chamfer_leg_right]
          : [appStrings.chamfer_leg_near, appStrings.chamfer_leg_far];
      final legsMm = state.cutWall.runsAlongLength
          ? [appStrings.chamfer_leg_left_mm, appStrings.chamfer_leg_right_mm]
          : [appStrings.chamfer_leg_near_mm, appStrings.chamfer_leg_far_mm];
      // A notch's two measurements are named for the room's own axes, not for
      // their part in the cut. The reach runs along the wall the pair stands on,
      // and that wall turns: on a side wall the reach runs across the room's
      // width and the depth runs along its length, so calling the reach "length"
      // there put the word on the number drawn up and down the page.
      final acrossWall = !state.cutWall.runsAlongLength;
      // A T measured by the stem it leaves rather than by the two cuts that
      // leave it. One number along the wall and one out from it, and the cuts
      // either side are what is left — which is how a room with an alcove comes
      // off a tape, the stem being a thing in the room and the cuts being what
      // is not. The depth box below is shared with the four-box form: it means
      // the same thing either way round.
      if (kind.symmetricStem(state)) {
        final side = acrossWall ? state.roomWidth : state.roomLength;
        // Both cuts' legs along the wall are what the stem leaves, so they are
        // what this one number works out; both their depths *are* this one
        // number, so the depth box lights them rather than deriving them.
        final legs = [
          for (final corner in corners) ...walls.cutLegOf(corner, along: !acrossWall)
        ];
        final depths = [
          for (final corner in corners) ...walls.cutLegOf(corner, along: acrossWall)
        ];
        boxes.add(_RoomBox(
          controller: midSpanController,
          inchController: midSpanInchController,
          focusNode: midSpanFocusNode,
          inchFocusNode: midSpanInchFocusNode,
          label: acrossWall ? appStrings.stub_width_mm : appStrings.stub_length_mm,
          title: acrossWall ? appStrings.stub_width : appStrings.stub_length,
          // Wide enough to be the room the stem is, and narrow enough to leave
          // a cut worth cutting at either end of it.
          minMm: CutCornersRoomShape.minArmMm,
          maxMm: (side ?? MIN_ROOM_MM) - MIN_NOTCH_MM * 2,
          valueMm: state.midSpan,
          walls: walls.stemBetween(corners),
          derived: legs,
          minFeet: 0,
          apply: cubit.setMidSpan,
        ));
        boxes.add(_RoomBox(
          controller: notchWidthController,
          inchController: notchWidthInchController,
          focusNode: notchWidthFocusNode,
          inchFocusNode: notchWidthInchFocusNode,
          label: acrossWall ? appStrings.stub_length_mm : appStrings.stub_width_mm,
          title: acrossWall ? appStrings.stub_length : appStrings.stub_width,
          minMm: MIN_NOTCH_MM,
          maxMm: notchMax(acrossWall ? state.roomLength : state.roomWidth),
          valueMm: state.notchWidth,
          walls: depths,
          minFeet: 0,
          apply: cubit.setNotchWidth,
        ));
        return boxes;
      }
      final shoulder = kind.hasOneLeg
          ? (int n) => legs[n - 1]
          : (acrossWall ? appStrings.notch_width_n : appStrings.notch_length_n);
      final shoulderMm = kind.hasOneLeg
          ? (int n) => legsMm[n - 1]
          : (acrossWall ? appStrings.notch_width_n_mm : appStrings.notch_length_n_mm);
      final alongSide =
          state.cutWall.runsAlongLength ? state.roomLength : state.roomWidth;
      for (var i = 0; i < 2; i++) {
        boxes.add(_cutBox(
          slot: i,
          reach: true,
          // A notch leaves its corner two legs, one square to each axis, and
          // which of them this box measures turns on which way the wall runs. A
          // chamfer leaves one, slanted, and it is filed as the along leg
          // whatever wall the pair stands on — asking for the across leg of a
          // chamfer standing on a side wall found nothing, and the box lit no
          // part of the drawing at all.
          walls: walls.cutLegOf(corners[i],
              along: kind.hasOneLeg || state.cutWall.runsAlongLength),
          derived: walls.shortenedBy(corners[i]),
          label: shoulderMm(i + 1),
          title: shoulder(i + 1),
          minMm: kind.hasOneLeg ? CornerSize.wallOfLeg(MIN_NOTCH_MM) : MIN_NOTCH_MM,
          maxMm: shoulderMax(alongSide, reachTyped[1 - i]),
          valueMm: reachTyped[i],
          apply: reachApply[i],
        ));
      }
    } else if (kind.cutCount > 1) {
      // Two cuts across the room from each other. They share no wall to be
      // measured off, so each is given its own length and its own width, and
      // each is bounded by the room alone — what stops them meeting in the
      // middle is [RoomProblem.cutsOverlap] under the sketch rather than a
      // ceiling on either box, because either one of them may be the deep one.
      for (var i = 0; i < 2; i++) {
        boxes.add(_cutBox(
          slot: i,
          reach: true,
          walls: walls.cutLegOf(corners[i], along: true),
          derived: walls.shortenedBy(corners[i]),
          label: appStrings.notch_length_n_mm(i + 1),
          title: appStrings.notch_length_n(i + 1),
          minMm: MIN_NOTCH_MM,
          maxMm: notchMax(state.roomLength),
          valueMm: reachTyped[i],
          apply: reachApply[i],
        ));
      }
    } else {
      // A chamfer is given by the wall it leaves and reaches the same way
      // along both sides, so what bounds it is the shorter of the two — and
      // the bound is stated in the wall's own length, which is what the box
      // asks for.
      final lone = kind.hasOneLeg
          ? math.min(state.roomLength ?? MIN_ROOM_MM, state.roomWidth ?? MIN_ROOM_MM)
          : state.roomLength;
      boxes.add(_cutBox(
        slot: 0,
        reach: true,
        walls: walls.cutLegOf(corners[0], along: true),
        derived: walls.shortenedBy(corners[0]),
        label: kind.hasOneLeg ? appStrings.chamfer_leg_mm : appStrings.notch_length_mm,
        title: kind.hasOneLeg ? appStrings.chamfer_leg : appStrings.notch_length,
        minMm: kind.hasOneLeg ? CornerSize.wallOfLeg(MIN_NOTCH_MM) : MIN_NOTCH_MM,
        maxMm: kind.hasOneLeg
            ? CornerSize.wallOfLeg(notchMax(lone))
            : notchMax(lone),
        valueMm: state.notchLength,
        apply: cubit.setNotchLength,
      ));
    }
    if (!kind.hasOneLeg) {
      // How deep each square cut goes: across the wall for a pair standing on
      // one, and down the width for every other.
      //
      // One box per cut, and that is the point of the pair of them. A T used to
      // ask once and give both its cuts that depth, which is a boxed-in riser
      // and a cupboard on one wall being the same depth by assumption — and
      // they are not, so a user with the usual kitchen wall had to pick which
      // of the two to get wrong.
      final into = kind.isPaired
          ? (state.cutWall.runsAlongLength ? state.roomWidth : state.roomLength)
          : state.roomWidth;
      final depthIsLength = kind.isPaired && !state.cutWall.runsAlongLength;
      final depthTyped = [state.notchWidth, state.notchWidth2];
      final depthApply = [cubit.setNotchWidth, cubit.setNotchWidth2];
      for (var i = 0; i < kind.cutCount; i++) {
        boxes.add(_cutBox(
          slot: i,
          reach: false,
          walls: walls.cutLegOf(corners[i],
              along: kind.isPaired && !state.cutWall.runsAlongLength),
          derived: walls.shortenedBy(corners[i]),
          // One name for a cut's reach and one for its depth, whether the pair
          // stands on a wall or straddles the room: a notch is a notch, and two
          // sets of words for the same two measurements only left the user
          // deciding whether they meant different things.
          //
          // The depth goes into the room from the wall the pair stands on, so
          // it is the across-the-width measurement for a pair on the near or
          // far wall and the along-the-length one for a pair on either side —
          // the opposite way round from the reach above, and named the same way
          // round as the room.
          label: kind.cutCount == 1
              ? appStrings.notch_width_mm
              : depthIsLength
                  ? appStrings.notch_length_n_mm(i + 1)
                  : appStrings.notch_width_n_mm(i + 1),
          title: kind.cutCount == 1
              ? appStrings.notch_width
              : depthIsLength
                  ? appStrings.notch_length_n(i + 1)
                  : appStrings.notch_width_n(i + 1),
          minMm: MIN_NOTCH_MM,
          maxMm: notchMax(into),
          valueMm: depthTyped[i],
          apply: depthApply[i],
        ));
      }
    }
    return boxes;
  }

  /// One box for one measurement of one cut.
  ///
  /// Which box it is typed into is the one thing every cut shape agrees on: a
  /// cut is the first or the second, and the measurement is the one along the
  /// wall or the one into the room — four boxes, and the shape picks among them
  /// by those two answers. Everything else differs between a shoulder off a
  /// shared wall and a cut standing on its own, so it is asked for rather than
  /// worked out here.
  _RoomBox _cutBox({
    required int slot,
    required bool reach,
    required List<int> walls,
    required List<int> derived,
    required String label,
    required String title,
    required int minMm,
    required int maxMm,
    required int? valueMm,
    required void Function(int) apply,
  }) {
    final first = slot == 0;
    return _RoomBox(
      controller: reach
          ? (first ? notchLengthController : notchLength2Controller)
          : (first ? notchWidthController : notchWidth2Controller),
      inchController: reach
          ? (first ? notchLengthInchController : notchLength2InchController)
          : (first ? notchWidthInchController : notchWidth2InchController),
      focusNode: reach
          ? (first ? notchLengthFocusNode : notchLength2FocusNode)
          : (first ? notchWidthFocusNode : notchWidth2FocusNode),
      inchFocusNode: reach
          ? (first ? notchLengthInchFocusNode : notchLength2InchFocusNode)
          : (first ? notchWidthInchFocusNode : notchWidth2InchFocusNode),
      label: label,
      title: title,
      minMm: minMm,
      maxMm: maxMm,
      valueMm: valueMm,
      walls: walls,
      derived: derived,
      // A cut may be a hand's width, so its boxes have no floor of a whole foot
      // the way a wall does.
      minFeet: 0,
      apply: apply,
    );
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
  int diagonalMin(RoomState state) => RoomShape.minDiagonal(
        lengthNear: state.roomLength ?? MIN_ROOM_MM,
        lengthFar: state.roomLength2 ?? state.roomLength ?? MIN_ROOM_MM,
        widthLeft: state.roomWidth ?? MIN_ROOM_MM,
        widthRight: state.roomWidth2 ?? state.roomWidth ?? MIN_ROOM_MM,
      );

  int diagonalMax(RoomState state) => RoomShape.maxDiagonal(
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

  bool areAllFieldsValid(BuildContext context, RoomState state, MeasurementSystem system) {
    // The same list the boxes are drawn from, so a shape cannot put a box on
    // screen that nothing checks, or check one it never shows.
    for (final box in _roomBoxes(context, state)) {
      if (!roomSizeValid(context, system,
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

  /// What tapping the sketch does, in the words of the shape it is drawing.
  String tapCaption(AppLocalizations appStrings, RoomKind kind) {
    if (kind.isWallNotch) return appStrings.tap_wall_notch;
    if (kind.isPaired) {
      return kind.hasOneLeg ? appStrings.tap_wall_to_cut : appStrings.tap_wall_stem;
    }
    if (kind.hasOneLeg) return appStrings.tap_corner_to_cut;
    return kind.cutCount > 1
        ? appStrings.tap_corner_to_move
        : appStrings.tap_corner_notched;
  }

  /// Whether a T is measured by the stem it leaves or by the two cuts that
  /// leave it. Only a T is ever asked.
  ///
  /// Under the boxes rather than over them, where it reads as a note on what
  /// was just typed. Over them it was a question to answer before the form
  /// began, and most users have no answer to it until they have seen what the
  /// form asks.
  ///
  /// On by default: a room with an alcove is read off a tape as the alcove, and
  /// the two cuts either side of it are usually the same by construction — a
  /// chimney breast centred on its wall, a doorway recess. The user who has the
  /// other kind turns it off and gets four boxes back, with what they typed in
  /// them still there.
  Widget symmetryField(BuildContext context, RoomState state) {
    if (!state.roomKind.isPaired || state.roomKind.hasOneLeg) {
      return const SizedBox.shrink();
    }
    final appStrings = AppStrings.of(context);
    final cubit = context.read<RoomCubit>();
    return Padding(
      padding: const EdgeInsets.only(top: kFormGap),
      child: InkWell(
        onTap: () => cubit.setSymmetricCut(!state.symmetricCut),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                key: const ValueKey('symmetric-cut'),
                value: state.symmetricCut,
                // The form's own blue, not the theme's purple: every other
                // thing on this card that answers back is blue.
                activeColor: Colors.blue,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (on) => cubit.setSymmetricCut(on ?? true),
              ),
            ),
            SizedBox(width: _GAP),
            Text(
              appStrings.symmetric_cut,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.8), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  /// The room boxes the shape asks for, laid out for the unit system in use:
  /// two to a row in millimetres, one stack of title-and-two-boxes each in feet
  /// and inches. The order is [_roomBoxes]' order, and so is the keyboard's walk
  /// from one to the next.
  List<Widget> roomFields(
      BuildContext context, RoomState state, MeasurementSystem system) {
    final boxes = _roomBoxes(context, state);
    // The last box has nowhere to send the keyboard on: the laminate is on a
    // screen of its own now, and the Next button is the way to it.
    FocusNode? after(int i) => i + 1 < boxes.length ? boxes[i + 1].focusNode : null;

    if (system != MeasurementSystem.metric) {
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
  String roomKindName(BuildContext context, RoomKind kind) =>
      roomKindNameOf(AppStrings.of(context), kind);

  /// What the room is, as a grid of shapes rather than a list of words.
  ///
  /// This was a dropdown while there were three shapes, chosen because three
  /// segmented buttons on a 360 dp phone leave about a word each and "Wände
  /// unterschiedlicher Länge" is not a word. Seven shapes would be seven lines
  /// of prose in a menu nobody opens, and the shapes are the one thing here that
  /// needs no translating: a user looking for the room they are standing in
  /// recognises it faster than they read it. A grid of outlines has no
  /// three-item ceiling, and it shows the trapezium and the parallelogram that
  /// the engine has always been able to lay and the word "uneven walls" never
  /// admitted to.
  ///
  /// Four to a line, with the name of the chosen one directly under its own
  /// tile. All of them on one line was what six fitted into and seven does not:
  /// the tile would come down to 33 dp, which is smaller than the thing pressing
  /// it. The break falls where the shapes themselves divide — the first line is
  /// every shape that stays convex and so keeps the 45° layout, the second is
  /// the three with a corner taken out square, which is what costs them it.
  ///
  /// One caption rather than one per tile. Seven names under seven tiles is what
  /// would force the grid wider still: a quarter of a 360 dp card is about seven
  /// characters, and "Wände unterschiedlicher Länge" is not seven characters in
  /// any language we ship. Named one at a time the caption has the whole card to
  /// itself, so it is read rather than guessed at — and the six shapes nobody
  /// picked say what they are by their outline, which is what they were drawn
  /// for.
  ///
  /// It does have to be under the tile it names, though, and under the grid is
  /// not that: with two lines of tiles the name of a shape on the first line
  /// ends up a whole row away from it, pointing at a column of the second. So
  /// the caption goes under its own line, and only that line carries one.
  Widget roomKindField(BuildContext context, RoomState state) {
    // How tall one line of the caption is at the font size the user asked for,
    // not the one written here: the line is laid out before the name is
    // measured, so its height is given rather than discovered.
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(_CAPTION_SIZE) * _CAPTION_HEIGHT;
    return LayoutBuilder(
      builder: (context, constraints) {
        final kinds = RoomKind.values;
        final perRow = math.min(_TILES_PER_ROW, kinds.length);
        final width = constraints.maxWidth;
        final cell = (width - _TILE_GAP * (perRow - 1)) / perRow;
        // The square is the cell, up to a ceiling: on a tablet a quarter of the
        // card is wider than a thumb, and a button much bigger than that reads
        // as a picture of something rather than as something to press.
        final side = math.min(cell, _TILE_MAX);
        // Spread rather than packed, so the first tile of a line is flush with
        // the left edge of the boxes below and the last of a full line with
        // their right. Only visible once the squares stop filling their cells —
        // on a phone they fill them exactly. The tiles then stand one [step]
        // apart, which is what the caption below needs to find the one it names,
        // and what holds a short last line in the same columns as the first.
        final step = (width - side) / (perRow - 1);
        final chosen = kinds.indexOf(state.roomKind);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No heading over the tiles. Little rooms under the word "Room" are
            // rooms to choose from however they are captioned, and the caption
            // only pushed the first box of the form further down the screen.
            // Laid out rather than scrolled: a row that has to be scrolled hides
            // whatever is off the end of it — which is how a user with a
            // T-shaped room would never learn the calculator takes one.
            for (var start = 0; start < kinds.length; start += perRow) ...[
              if (start > 0) SizedBox(height: _TILE_GAP),
              Row(
                children: [
                  for (var i = start; i < math.min(start + perRow, kinds.length); i++) ...[
                    if (i > start) SizedBox(width: step - side),
                    shapeTile(context, kinds[i], kinds[i] == state.roomKind, side),
                  ],
                ],
              ),
              // The name, under the row the chosen tile is on and under no
              // other. One line, and it is only there once — the row that does
              // not hold the chosen tile carries nothing and takes no height
              // for it.
              //
              // So the block is a line taller when the chosen tile is on the
              // bottom row than when it is on the top one, and the boxes under
              // it sit a line lower. That is the trade: the alternative is a
              // line of reserved air under whichever row is not chosen, which
              // holds everything still at the price of a visible gap between
              // the rows most of the time. A step of one line as the user tries
              // the shapes on is the smaller of the two.
              if (chosen >= start && chosen < start + perRow) ...[
                SizedBox(height: 6),
                SizedBox(
                  // Written down rather than left to the text, because the line
                  // is laid out before the name is measured and a line short by
                  // a pixel clips the descenders.
                  height: lineHeight,
                  child: CustomSingleChildLayout(
                    // The column the chosen tile stands in, counted from the
                    // start of its own row.
                    delegate: _CaptionUnder((chosen - start) * step + side / 2),
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
            ],
          ],
        );
      },
    );
  }

  /// One shape to choose: its outline, boxed, and blue when it is the shape the
  /// room is. What it is called is written once, under whichever tile is lit —
  /// see [roomKindField].
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
    RoomKind.zShaped: [
      Offset(_ICON_CUT, 0), Offset(1, 0), Offset(1, 1 - _ICON_CUT), Offset(1 - _ICON_CUT, 1 - _ICON_CUT),
      Offset(1 - _ICON_CUT, 1), Offset(0, 1), Offset(0, _ICON_CUT), Offset(_ICON_CUT, _ICON_CUT)
    ],
    // The notch is drawn in the near wall, which is the wall the form starts
    // on, and deeper than a third so that it reads as a bite out of the wall
    // rather than a nick in it.
    RoomKind.uShaped: [
      Offset(0, 0), Offset(_ICON_CUT, 0), Offset(_ICON_CUT, _ICON_CUT),
      Offset(1 - _ICON_CUT, _ICON_CUT), Offset(1 - _ICON_CUT, 0), Offset(1, 0),
      Offset(1, 1), Offset(0, 1)
    ],
  };

  // Read with a `!`: a shape added to [RoomKind.values] and forgotten here
  // fails the first widget test that builds the row, rather than quietly
  // drawing somebody else's room.
  List<Offset> kindIconCorners(RoomKind kind) => _ICON_CORNERS[kind]!;

  // The sketch that says which wall is which and which corner is cut, and the
  // one thing the fields cannot say on their own: that the measurements
  // describe no room at all.
  Widget roomSketch(
      BuildContext context, RoomState state, MeasurementSystem system) {
    final appStrings = AppStrings.of(context);
    final shape = state.shape;
    // No room yet, nothing to draw. Every shape is drawn once there is one,
    // including the rectangle: it has four walls and two of them are the
    // numbers just typed, and seeing them on an outline is how a user catches
    // the length and the width the wrong way round.
    if (shape == null) return const SizedBox.shrink();
    final problem = shape.problem;
    // Which numbers on the drawing are guesses, and which one is being typed.
    // Both come off the same list the boxes are built from, so a box and the
    // number beside its wall cannot disagree about which is which.
    final boxes = _roomBoxes(context, state);
    final unknownWalls = <int>{};
    final litWalls = <int>{};
    var unknownDiagonal = false;
    var litDiagonal = false;
    // Whether the diagonal is on the drawing at all: it is there when a box
    // asked for it and not otherwise. Read off the same list as everything else
    // the sketch is told, so the drawing cannot carry a measurement the form
    // never asked for — which is what a rectangle's hypotenuse would be.
    var withDiagonal = false;
    for (final box in boxes) {
      withDiagonal |= box.isDiagonal;
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
          system: system,
          cutCorner:
              state.cutCorners && !state.roomKind.isPaired ? state.notchCorner : null,
          cutWall: state.cutCorners && state.roomKind.isPaired ? state.cutWall : null,
          onCorner: state.cutCorners && !state.roomKind.isPaired
              ? (corner) => context.read<RoomCubit>().setNotchCorner(corner)
              : null,
          onWall: state.cutCorners && state.roomKind.isPaired
              ? (wall) => context.read<RoomCubit>().setCutWall(wall)
              : null,
          unknownWalls: unknownWalls,
          unknownDiagonal: unknownDiagonal,
          litWalls: litWalls,
          litDiagonal: litDiagonal,
          withDiagonal: withDiagonal,
        ),
        if (state.cutCorners && problem == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              // One line per shape, because what the tap does differs: a lone
              // cut names the corner it is in, a pair across the room is named
              // by either of its two, and a pair on a wall is named by the
              // wall. And a 45° cut is a cut while a square one is a notch —
              // the words the boxes use, so the caption uses them too.
              tapCaption(appStrings, state.roomKind),
              style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 13),
            ),
          ),
        if (problem != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              // Two cuts that have reached each other get their own words. "The
              // cut leaves no room" is true of them and no help: both boxes are
              // inside the bounds printed under them, and what is wrong is the
              // pair rather than either one.
              problem == RoomProblem.cutsOverlap
                  ? appStrings.notches_overlap
                  : state.cutCorners
                      ? appStrings.notch_does_not_fit
                      : appStrings.walls_do_not_close,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings.of(context);

    // Two builders: what the room is, and what it is measured in. The second
    // changes from the gear on this very screen, and every label, bound and
    // number on the drawing turns with it.
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (was, now) => was.system != now.system,
      builder: (context, settings) => BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) {
          final system = settings.system;
          return ParametersCard(
            title: appStrings.room,
            // The shape the room is, drawn the way the tiles below draw it.
            // A house icon said "this is the room section" to somebody who has
            // not scrolled to the tiles yet and nothing at all to somebody who
            // has; the outline says which of the eight is chosen, from the top
            // of the card, where the eye lands first.
            icon: CustomPaint(
              painter: RoomKindIcon(
                corners: kindIconCorners(state.roomKind),
                colour: Colors.blue,
              ),
            ),
            canProceed: areAllFieldsValid(context, state, system),
            onNext: () => context.router.push(LaminateAndLayingRoute()),
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
              ...roomFields(context, state, system),
              symmetryField(context, state),
              roomSketch(context, state, system),
            ],
          );
        },
      ),
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

  /// A notch in the middle of a wall, which is keyed to no corner at all: the
  /// two pieces of its wall left at the ends, in the order the boxes number
  /// them; the notch's two legs, which are both its depth; and the notch's own
  /// width, which nobody typed and the room worked out from the two ends.
  final List<int> notchEnds;
  final List<int> notchLegs;
  final List<int> notchSpan;

  const _WallMap({
    this.alongLength = const [],
    this.acrossWidth = const [],
    this.farLength = const [],
    this.farWidth = const [],
    this.cutAlong = const {},
    this.cutAcross = const {},
    this.shortened = const {},
    this.notchEnds = const [],
    this.notchLegs = const [],
    this.notchSpan = const [],
  });

  /// The wall a cut's leg is written on, whichever way round the cut is.
  List<int> cutLegOf(RoomCorner corner, {required bool along}) =>
      (along ? cutAlong : cutAcross)[corner] ?? const [];

  /// What that cut also makes a guess of while it is not typed.
  List<int> shortenedBy(RoomCorner corner) => shortened[corner] ?? const [];

  /// The piece of wall a pair of cuts leaves between them: the stem of a T.
  /// The one wall both of them shortened, which is what makes it theirs.
  List<int> stemBetween(List<RoomCorner> pair) => [
        for (final wall in shortenedBy(pair.first))
          if (shortenedBy(pair.last).contains(wall)) wall
      ];
}
