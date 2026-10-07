import 'dart:math' as math;

import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/room_shape.dart';

/// Which shape the user says the room is.
///
/// One choice rather than a switch per shape: they are alternatives, not
/// options. A room is measured wall by wall *or* it has corners cut out of it,
/// and the second assumes the square corners the first exists to avoid.
///
/// Each of the cut shapes is a fixed shape and not a starting point — pick a T
/// and a T is what the sketch keeps drawing, with the tap moving its stem to
/// another wall rather than adding a third cut. [CutCornersRoomShape] would
/// take any set of corners; the form offers the sets a room is actually built
/// in, so that the name on the tile and the shape on the sketch can never
/// disagree.
///
/// A class each rather than one name each. What the six differ in is not a
/// label but a room: which corners come off, how the cut is measured, and what
/// outline the drawing and the calculation are handed. Written as a list of
/// names that would be four switches in two files, and a seventh shape would
/// be a visit to all four. Written as six classes it is one new class, and
/// anything it forgets to say the compiler asks for.
abstract class RoomKind {
  const RoomKind();

  /// Square or straight across, or null where the room has no cuts at all.
  CornerCut? get cutKind;

  /// Whether the cuts come in a pair on one wall rather than singly in a
  /// corner — which decides whether the form asks for a wall or a corner, and
  /// whether there are one or two shoulders to type.
  bool get isPaired;

  bool get isCut => cutKind != null;

  /// Whether a cut is measured by one number rather than two.
  ///
  /// A chamfer is offered at 45° and nothing else, so the form asks once — for
  /// the wall the cut leaves, which is the only one of the three lengths a tape
  /// can be laid along once the corner is gone. That is a deliberate narrowing of what
  /// [CutCornersRoomShape] can hold, and it pays twice: one number instead of
  /// two to type, and a cut wall that leans at exactly 45° to the rows either
  /// way the floor is laid. [Bevel.fromLean] refuses to cut an end steeper
  /// than that, so a chamfer at any other angle would leave a wedge of floor
  /// bare along it in one of the two laying directions and not the other —
  /// which is a hard thing to explain and an easy thing not to offer.
  bool get hasOneLeg => cutKind == CornerCut.chamfer;

  /// The room the calculation and the drawing both work from, at the two sizes
  /// every room has.
  ///
  /// A wall left blank is the same as the wall opposite it, a diagonal left
  /// blank is the one that makes the room a rectangle, and a cut left blank is
  /// a third of the room — so a half-filled form still describes a room rather
  /// than nothing. Which of those defaults apply is the shape's own business,
  /// and that is why this is asked of the shape rather than worked out around
  /// it.
  RoomOutline outlineFor(CalculateState state, int length, int width);

  // Declared as [RoomKind] rather than left to inference. The shape picker
  // keys its tiles on the instance — `ValueKey(kind)` — and a `ValueKey<
  // LShapedRoom>` is not equal to the `ValueKey<RoomKind>` the row builds, so
  // a test looking one up by name would never find it.
  static const RoomKind rectangle = RectangleRoom();
  static const RoomKind uneven = UnevenRoom();
  static const RoomKind chamfer = ChamferRoom();
  static const RoomKind chamferPair = ChamferPairRoom();
  static const RoomKind lShaped = LShapedRoom();
  static const RoomKind tShaped = TShapedRoom();

  /// Every shape the form offers, in the order the row of tiles draws them.
  ///
  /// The order is the screen's: a rectangle first because most rooms are one,
  /// then the walls that do not square up, then the four that have a corner
  /// off them — the two 45° cuts before the two square ones, each lone shape
  /// beside its pair.
  static const List<RoomKind> values = [
    rectangle,
    uneven,
    chamfer,
    chamferPair,
    lShaped,
    tShaped,
  ];

  /// The cut a room of this size is given when the user first says it has one:
  /// a third of the side, which is an L anybody recognises on the sketch and
  /// is inside the bounds for every room the form takes. The same courtesy
  /// turning the walls on pays — the form stays valid and only what was
  /// actually measured needs typing.
  static int defaultNotch(int side) =>
      heldBetween(side ~/ 3, MIN_NOTCH_MM, side - LRoomShape.minArmMm);
}

/// Four square corners: the room every user types, and the one the form is in
/// until they say otherwise.
class RectangleRoom extends RoomKind {
  const RectangleRoom();

  @override
  CornerCut? get cutKind => null;

  @override
  bool get isPaired => false;

  @override
  RoomOutline outlineFor(CalculateState state, int length, int width) =>
      RoomShape.rectangle(length, width);
}

/// A room measured wall by wall, which may be a trapezium or a parallelogram
/// or anything else four walls close around.
///
/// Four wall lengths are one measurement short of a shape, and the diagonal is
/// the one that closes it; see [RoomShape].
class UnevenRoom extends RoomKind {
  const UnevenRoom();

  @override
  CornerCut? get cutKind => null;

  @override
  bool get isPaired => false;

  @override
  RoomOutline outlineFor(CalculateState state, int length, int width) =>
      RoomShape(
        lengthNear: length,
        lengthFar: state.roomLength2 ?? length,
        widthLeft: width,
        widthRight: state.roomWidth2 ?? width,
        diagonal:
            state.roomDiagonal ?? RoomShape.rectangleDiagonal(length, width),
      );
}

/// A rectangle with something taken out of a corner of it.
///
/// The two sizes the form always has are the bounding rectangle, and what the
/// shape adds to that is which corners come off and how far each cut reaches.
abstract class CutRoomKind extends RoomKind {
  const CutRoomKind();

  /// Which corners this room has taken off and how far each cut reaches.
  ///
  /// The form collects a cut the way it is measured — a chamfer by its one leg,
  /// a T by two shoulders and a depth — and this is where that turns into the
  /// along-and-across pairs the outline wants.
  Map<RoomCorner, CornerSize> cutsFor(
      CalculateState state, int length, int width);

  @override
  RoomOutline outlineFor(CalculateState state, int length, int width) =>
      CutCornersRoomShape(
        length: length,
        width: width,
        cut: cutKind!,
        cuts: cutsFor(state, length, width),
      );
}

/// One corner off, wherever on the room the user has put it.
abstract class LoneCutRoomKind extends CutRoomKind {
  const LoneCutRoomKind();

  @override
  bool get isPaired => false;

  @override
  Map<RoomCorner, CornerSize> cutsFor(
          CalculateState state, int length, int width) =>
      {state.notchCorner: cutAt(state, length, width)};

  /// How far the one cut reaches, in the room's own two directions.
  CornerSize cutAt(CalculateState state, int length, int width);
}

/// One corner run straight across at 45°.
class ChamferRoom extends LoneCutRoomKind {
  const ChamferRoom();

  @override
  CornerCut? get cutKind => CornerCut.chamfer;

  @override
  CornerSize cutAt(CalculateState state, int length, int width) {
    // A chamfer is given by the wall it leaves, and reaches the same distance
    // along each of the two walls it joins — so what it has to fit against is
    // the shorter side of the room.
    final cutWallMm = state.notchLength ??
        RoomKind.defaultNotch(math.min(length, width));
    return CornerSize.chamfer(cutWallMm);
  }
}

/// One corner taken out square.
///
/// The one cut shape that keeps a name of its own. A room with a single square
/// cut is an L to everyone who has ever stood in one, and [LRoomShape] says so
/// to everything downstream that was written before there were others — at no
/// cost, since it is the same outline under a different name. The sizes still
/// come from [cutsFor], so there is one place that knows how a cut is measured.
class LShapedRoom extends LoneCutRoomKind {
  const LShapedRoom();

  @override
  CornerCut? get cutKind => CornerCut.notch;

  @override
  CornerSize cutAt(CalculateState state, int length, int width) => CornerSize(
        along: state.notchLength ?? RoomKind.defaultNotch(length),
        across: state.notchWidth ?? RoomKind.defaultNotch(width),
      );

  @override
  RoomOutline outlineFor(CalculateState state, int length, int width) {
    final only = cutsFor(state, length, width).entries.single;
    return LRoomShape(
      length: length,
      width: width,
      notchLength: only.value.along,
      notchWidth: only.value.across,
      corner: only.key,
    );
  }
}

/// Both ends of one wall taken off, leaving a stem.
///
/// [CalculateState.notchLength] is the first shoulder and
/// [CalculateState.notchLength2] the second, both measured along
/// [CalculateState.cutWall] from its two ends.
abstract class PairedCutRoomKind extends CutRoomKind {
  const PairedCutRoomKind();

  @override
  bool get isPaired => true;

  @override
  Map<RoomCorner, CornerSize> cutsFor(
      CalculateState state, int length, int width) {
    final pair = state.cutWall.corners;
    // Two cuts share the wall, so each is offered a quarter of it rather than
    // the third a lone cut gets: a third each would leave them meeting in the
    // middle with barely a room between.
    final side = state.cutWall.runsAlongLength ? length : width;
    final quarter = heldBetween(side ~/ 4, MIN_NOTCH_MM, side - MIN_ROOM_MM);
    return {
      pair[0]: shoulderAt(state, length, width, state.notchLength ?? quarter),
      pair[1]: shoulderAt(state, length, width, state.notchLength2 ?? quarter),
    };
  }

  /// One of the two cuts, given how far along the wall they share it reaches.
  CornerSize shoulderAt(
      CalculateState state, int length, int width, int shoulder);
}

/// Both ends of one wall run across at 45°.
class ChamferPairRoom extends PairedCutRoomKind {
  const ChamferPairRoom();

  @override
  CornerCut? get cutKind => CornerCut.chamfer;

  @override
  CornerSize shoulderAt(
          CalculateState state, int length, int width, int shoulder) =>
      CornerSize.chamfer(shoulder);
}

/// Both ends of one wall taken out square, leaving a stem.
class TShapedRoom extends PairedCutRoomKind {
  const TShapedRoom();

  @override
  CornerCut? get cutKind => CornerCut.notch;

  @override
  CornerSize shoulderAt(
      CalculateState state, int length, int width, int shoulder) {
    final depth = state.notchWidth ??
        RoomKind.defaultNotch(state.cutWall.runsAlongLength ? width : length);
    // A shoulder is measured along the wall the pair stands on and the depth
    // across it, so which of the two is [CornerSize.along] turns on the wall.
    return state.cutWall.runsAlongLength
        ? CornerSize(along: shoulder, across: depth)
        : CornerSize(along: depth, across: shoulder);
  }
}
