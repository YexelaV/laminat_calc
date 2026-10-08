import 'dart:math' as math;

import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/cubit/room_cubit.dart';
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
/// A class each rather than one name each. What they differ in is not a label
/// but a room: which corners come off, how the cut is measured, and what
/// outline the drawing and the calculation are handed. Written as a list of
/// names that would be four switches in two files, and every new shape a visit
/// to all four. Written as classes it is one new class — which is what the Z
/// cost — and anything it forgets to say the compiler asks for.
abstract class RoomKind {
  const RoomKind();

  /// Square or straight across, or null where the room has no cuts at all.
  CornerCut? get cutKind;

  /// Whether the cuts come in a pair standing on one wall — which decides
  /// whether the form asks for a wall or a corner, and whether the two cuts
  /// are measured as shoulders off the ends of a wall or each in its own
  /// right.
  ///
  /// Not the same question as [cutCount], though it was until a room could be
  /// cut at two corners that share no wall. A Z has two cuts and is still
  /// pointed at by a corner, because its pair is named by either end of it.
  bool get isPaired;

  /// How many pieces this shape takes out: none, one, or two.
  int get cutCount;

  /// Whether this room is being measured by the stem its pair of cuts leaves
  /// rather than by the cuts themselves. Only a T ever is, and only while the
  /// form is asking that way round — see [RoomState.symmetricCut].
  bool symmetricStem(RoomState state) => false;

  /// Whether what it takes out is a notch in the middle of a wall rather than
  /// a corner.
  ///
  /// The one shape where it is, and the one shape that can only be laid one way
  /// — see [WallNotchRoomShape]. It is measured the way a pair on one wall is
  /// and asks for a wall the same way, so most of the form does not care; what
  /// it changes is what the three numbers are called and what bounds them.
  bool get isWallNotch => false;

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
  RoomOutline outlineFor(RoomState state, int length, int width);

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
  static const RoomKind zShaped = ZShapedRoom();
  static const RoomKind uShaped = UShapedRoom();

  /// Every shape the form offers, in the order the tiles draw them.
  ///
  /// The order is the screen's, and it falls into the two rows the tiles are
  /// laid out in. First the shapes that stay convex — a rectangle because most
  /// rooms are one, then the walls that do not square up, then the two 45°
  /// cuts — which between them are every shape a 45° layout is offered in.
  /// Then the three with a corner taken out square, which is the thing that
  /// costs them the diagonal: lone, in a pair on one wall, and in a pair
  /// across the room.
  static const List<RoomKind> values = [
    rectangle,
    uneven,
    chamfer,
    chamferPair,
    lShaped,
    tShaped,
    zShaped,
    uShaped,
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
  int get cutCount => 0;

  @override
  RoomOutline outlineFor(RoomState state, int length, int width) =>
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
  int get cutCount => 0;

  @override
  RoomOutline outlineFor(RoomState state, int length, int width) =>
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
      RoomState state, int length, int width);

  @override
  RoomOutline outlineFor(RoomState state, int length, int width) =>
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
  int get cutCount => 1;

  @override
  Map<RoomCorner, CornerSize> cutsFor(
          RoomState state, int length, int width) =>
      {state.notchCorner: cutAt(state, length, width)};

  /// How far the one cut reaches, in the room's own two directions.
  CornerSize cutAt(RoomState state, int length, int width);
}

/// One corner run straight across at 45°.
class ChamferRoom extends LoneCutRoomKind {
  const ChamferRoom();

  @override
  CornerCut? get cutKind => CornerCut.chamfer;

  @override
  CornerSize cutAt(RoomState state, int length, int width) {
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
  CornerSize cutAt(RoomState state, int length, int width) => CornerSize(
        along: state.notchLength ?? RoomKind.defaultNotch(length),
        across: state.notchWidth ?? RoomKind.defaultNotch(width),
      );

  @override
  RoomOutline outlineFor(RoomState state, int length, int width) {
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
/// [RoomState.notchLength] is the first shoulder and
/// [RoomState.notchLength2] the second, both measured along
/// [RoomState.cutWall] from its two ends.
abstract class PairedCutRoomKind extends CutRoomKind {
  const PairedCutRoomKind();

  @override
  bool get isPaired => true;

  @override
  int get cutCount => 2;

  @override
  Map<RoomCorner, CornerSize> cutsFor(
      RoomState state, int length, int width) {
    final pair = state.cutWall.corners;
    // Two cuts share the wall, so each is offered a quarter of it rather than
    // the third a lone cut gets: a third each would leave them meeting in the
    // middle with barely a room between.
    final side = state.cutWall.runsAlongLength ? length : width;
    final quarter = heldBetween(side ~/ 4, MIN_NOTCH_MM, side - MIN_ROOM_MM);
    return {
      pair[0]: shoulderAt(state, length, width, state.notchLength ?? quarter, 0),
      pair[1]:
          shoulderAt(state, length, width, state.notchLength2 ?? quarter, 1),
    };
  }

  /// One of the two cuts, given how far along the wall they share it reaches
  /// and which of the two it is.
  ///
  /// [which] is 0 for the shoulder at the left or near end of the wall and 1
  /// for the one at the other, in the order [RoomWallCorners.corners] lists
  /// them — which is the order the form numbers its boxes in. A chamfer is the
  /// same cut either end and ignores it; a square pair is not, because the two
  /// things cut out of one wall are a boxed-in riser and a cupboard, and those
  /// are the same depth only by coincidence.
  CornerSize shoulderAt(
      RoomState state, int length, int width, int shoulder, int which);
}

/// Both ends of one wall run across at 45°.
class ChamferPairRoom extends PairedCutRoomKind {
  const ChamferPairRoom();

  @override
  CornerCut? get cutKind => CornerCut.chamfer;

  @override
  CornerSize shoulderAt(
          RoomState state, int length, int width, int shoulder, int which) =>
      CornerSize.chamfer(shoulder);
}

/// Both ends of one wall taken out square, leaving a stem.
class TShapedRoom extends PairedCutRoomKind {
  const TShapedRoom();

  @override
  CornerCut? get cutKind => CornerCut.notch;

  @override
  bool symmetricStem(RoomState state) => state.symmetricCut;

  /// What each end of a wall [side] long is left with when the stem in the
  /// middle of it runs [stub] along it: half of what the stem does not take.
  ///
  /// Rounded down, so a wall and a stem of unlike parity leave the odd
  /// millimetre in the stem. A stem a millimetre wider than asked is still a
  /// stem; two shoulders a millimetre apart is not the symmetry that was asked
  /// for, and it would show on the drawing as a T leaning.
  static int shoulderFor(int side, int stub) =>
      math.max(0, (side - math.min(stub, side)) ~/ 2);

  /// And back: the stem two shoulders of [shoulder] leave in a wall [side]
  /// long. What the form writes in the box when the symmetry is turned on.
  static int midSpanFor(int side, int shoulder) => math.max(0, side - shoulder * 2);

  /// Measured by the stem rather than by the two cuts, when the form is asking
  /// that way: one number for how far it runs along the wall, one for how far
  /// it stands out, and the cuts either side of it are what is left.
  @override
  Map<RoomCorner, CornerSize> cutsFor(RoomState state, int length, int width) {
    if (!state.symmetricCut) return super.cutsFor(state, length, width);
    final pair = state.cutWall.corners;
    final side = state.cutWall.runsAlongLength ? length : width;
    final shoulder = shoulderFor(side, state.midSpan ?? defaultMidSpan(side));
    return {
      pair[0]: shoulderAt(state, length, width, shoulder, 0),
      pair[1]: shoulderAt(state, length, width, shoulder, 1),
    };
  }

  /// The stem a wall gets before anyone has measured one: the middle third,
  /// which is the T on the tile.
  static int defaultMidSpan(int side) =>
      heldBetween(side ~/ 3, MIN_ROOM_MM, side - MIN_NOTCH_MM * 2);

  @override
  CornerSize shoulderAt(
      RoomState state, int length, int width, int shoulder, int which) {
    // Each shoulder goes as deep as it was measured. The second box left empty
    // means the second cut is as deep as the first — the same courtesy a wall
    // left blank is paid, and the one that keeps a symmetrical T two numbers
    // rather than three. Measured by the stem there is only ever one depth, and
    // it is how far the stem stands out.
    final typed = which == 0 || state.symmetricCut
        ? state.notchWidth
        : state.notchWidth2 ?? state.notchWidth;
    final depth = typed ??
        RoomKind.defaultNotch(state.cutWall.runsAlongLength ? width : length);
    // A shoulder is measured along the wall the pair stands on and the depth
    // across it, so which of the two is [CornerSize.along] turns on the wall.
    return state.cutWall.runsAlongLength
        ? CornerSize(along: shoulder, across: depth)
        : CornerSize(along: depth, across: shoulder);
  }
}

/// Two corners taken out square, diagonally across the room from each other.
///
/// A studio with the hall cut out of one corner and a cupboard out of the one
/// opposite. Two cuts, and still a lone corner's shape to choose: the pair is
/// named by either end of it, so the sketch asks for a corner the way an L
/// does and the other cut follows across the room.
///
/// Each cut is measured in its own right rather than as a shoulder, because
/// they share no wall to be measured off. That also means nothing holds them
/// apart but the room itself — two cuts each legal alone can meet in the
/// middle and take the same floor twice, which [RoomProblem.cutsOverlap] is
/// what says.
class ZShapedRoom extends CutRoomKind {
  const ZShapedRoom();

  @override
  CornerCut? get cutKind => CornerCut.notch;

  @override
  bool get isPaired => false;

  @override
  int get cutCount => 2;

  @override
  Map<RoomCorner, CornerSize> cutsFor(
      RoomState state, int length, int width) {
    // The left-hand cut of the pair is the first one — see
    // [RoomCornerSides.leftOfPair], and the boxes on the form, which are
    // numbered down the drawing.
    final first = state.notchCorner.leftOfPair;
    return {
      first: CornerSize(
        along: state.notchLength ?? RoomKind.defaultNotch(length),
        across: state.notchWidth ?? RoomKind.defaultNotch(width),
      ),
      // The second cut left blank is the first one again, which is the Z a
      // user picking the shape has in mind until they measure otherwise.
      first.opposite: CornerSize(
        along: state.notchLength2 ??
            state.notchLength ??
            RoomKind.defaultNotch(length),
        across: state.notchWidth2 ??
            state.notchWidth ??
            RoomKind.defaultNotch(width),
      ),
    };
  }
}

/// A notch cut into the middle of one wall: the boxed-in riser on a kitchen
/// wall, a chimney breast, a column standing against the plaster.
///
/// The only shape here that takes a piece out of a wall rather than off a
/// corner, and the only one that can be laid in one direction and not the
/// other — see [WallNotchRoomShape] for why, which is the whole of what makes
/// it a room this calculator can take at all.
///
/// Asks for a wall and three numbers, like the T does, and means the opposite
/// by them: a T cuts the two ends of its wall and leaves the middle, this cuts
/// the middle and leaves the two ends. So [CalculateState.notchLength] and
/// [CalculateState.notchLength2] are the floor left at each end rather than the
/// cuts taken off them, and the notch is what is left between the two.
class UShapedRoom extends RoomKind {
  const UShapedRoom();

  /// Square, like every other notch. Not a [CutRoomKind] all the same: that one
  /// builds a room out of corners, and this room has none to build from.
  @override
  CornerCut? get cutKind => CornerCut.notch;

  /// The cut stands on a wall and is chosen by tapping it, which is what this
  /// answers for the sketch and the form.
  @override
  bool get isPaired => true;

  /// One piece out, however many numbers it takes to say where.
  @override
  int get cutCount => 1;

  @override
  bool get isWallNotch => true;

  @override
  bool symmetricStem(RoomState state) => state.symmetricCut;

  /// What the wall is left with at each end when the notch in the middle of it
  /// runs [span] along it. The same halving a T's shoulders get, and for the
  /// same reason — see [TShapedRoom.shoulderFor].
  static int offsetFor(int side, int span) =>
      math.max(0, (side - math.min(span, side)) ~/ 2);

  /// And back: the notch two offsets of [offset] leave in a wall [side] long.
  static int spanFor(int side, int offset) => math.max(0, side - offset * 2);

  @override
  RoomOutline outlineFor(RoomState state, int length, int width) {
    final along = state.cutWall.runsAlongLength ? length : width;
    final across = state.cutWall.runsAlongLength ? width : length;
    // A third of the wall left at each end leaves a third of it as the notch,
    // which is a shape anybody recognises on the sketch before a tape has been
    // anywhere near the room.
    final third = RoomKind.defaultNotch(along);
    // Measured by the notch itself: one number for how far it runs along the
    // wall and one for how deep it goes. Where it sits along the wall is the
    // middle unless the user says otherwise — a riser boxed in on a kitchen
    // wall is centred far more often than not, and the one who has the other
    // kind turns the symmetry off and says how far in it starts.
    final span = state.midSpan ?? RoomKind.defaultNotch(along);
    final centred = offsetFor(along, span);
    return WallNotchRoomShape(
      length: length,
      width: width,
      wall: state.cutWall,
      offsetFirst: state.symmetricCut ? centred : state.notchLength ?? third,
      offsetSecond: state.symmetricCut
          ? math.max(0, along - centred - span)
          : state.notchLength2 ?? third,
      depth: state.notchWidth ?? RoomKind.defaultNotch(across),
    );
  }
}
