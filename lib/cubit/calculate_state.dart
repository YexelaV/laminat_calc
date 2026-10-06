import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';

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
enum RoomKind {
  rectangle,
  uneven,

  /// One corner run straight across at 45°.
  chamfer,

  /// Both ends of one wall run across at 45°.
  chamferPair,

  /// One corner taken out square.
  lShaped,

  /// Both ends of one wall taken out square, leaving a stem.
  tShaped,
}

/// What the room's cut corners are, for the [RoomKind]s that have any.
extension RoomKindCuts on RoomKind {
  bool get isCut => cutKind != null;

  /// Square or straight across, or null where the room has no cuts at all.
  CornerCut? get cutKind {
    switch (this) {
      case RoomKind.chamfer:
      case RoomKind.chamferPair:
        return CornerCut.chamfer;
      case RoomKind.lShaped:
      case RoomKind.tShaped:
        return CornerCut.notch;
      case RoomKind.rectangle:
      case RoomKind.uneven:
        return null;
    }
  }

  /// Whether the cuts come in a pair on one wall rather than singly in a
  /// corner — which decides whether the form asks for a wall or a corner, and
  /// whether there are one or two shoulders to type.
  bool get isPaired =>
      this == RoomKind.chamferPair || this == RoomKind.tShaped;

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
}

class CalculateState extends Equatable {
  // Every dimension is in millimetres.

  /// The wall the rows are laid along, and the one they start against. These
  /// two are the room every user types, and on their own they describe a
  /// rectangle.
  final int? roomLength;
  final int? roomWidth;

  /// The walls opposite those two, and the diagonal between the corners they do
  /// not share — asked for only when the user says the room is not square.
  ///
  /// Four wall lengths are one measurement short of a shape, and the diagonal
  /// is the one that closes it; see [RoomShape].
  final int? roomLength2;
  final int? roomWidth2;
  final int? roomDiagonal;

  /// How far the missing corner reaches along the length and along the width,
  /// and which corner it is — asked for only when the room has a cut in it.
  ///
  /// A chamfer is cut at 45°, so it uses [notchLength] alone and [notchWidth]
  /// sits unread until the user picks a square cut again. Left in place rather
  /// than cleared: a user trying the shapes on for size gets their L back
  /// where they left it.
  final int? notchLength;
  final int? notchWidth;
  final RoomCorner notchCorner;

  /// The second cut of a pair, and the wall the pair stands on — asked for only
  /// when the room is T-shaped or has both ends of a wall run across.
  ///
  /// [notchLength] is the first shoulder and this is the second, both measured
  /// along [cutWall] from its two ends. For a T, [notchWidth] is how deep both
  /// of them go; a chamfer's depth is its shoulder.
  final int? notchLength2;
  final RoomWall cutWall;

  /// What the user says the room is. Off is not the same as four equal walls
  /// or a notch of nothing: it means the extra fields are not on screen and
  /// the room is the rectangle it has always been.
  final RoomKind roomKind;

  final int? laminateLength;
  final int? laminateWidth;
  final int? quantityPerPack;
  final int? indentFromWall;
  final int? rowOffset;
  final int? minimumLaminateLength;
  final Direction direction;
  final OffsetMode offsetMode;
  final MeasurementSystem system;

  const CalculateState(
      {this.roomLength,
      this.roomWidth,
      this.roomLength2,
      this.roomWidth2,
      this.roomDiagonal,
      this.notchLength,
      this.notchWidth,
      this.notchCorner = RoomCorner.farRight,
      this.notchLength2,
      this.cutWall = RoomWall.near,
      this.roomKind = RoomKind.rectangle,
      this.laminateLength,
      this.laminateWidth,
      this.quantityPerPack,
      this.indentFromWall,
      this.rowOffset,
      this.minimumLaminateLength,
      this.direction = Direction.length,
      this.offsetMode = OffsetMode.half,
      this.system = MeasurementSystem.metric});

  /// The form reads the shape it is in far more often than it sets it, and
  /// most of what it asks is one of these two.
  bool get unevenWalls => roomKind == RoomKind.uneven;

  bool get lShaped => roomKind == RoomKind.lShaped;

  /// Whether the room has any corner taken off it, however.
  bool get cutCorners => roomKind.isCut;

  /// The room the calculation and the drawing both work from, or null until the
  /// two sizes every room needs have been typed.
  ///
  /// A wall left blank is the same as the wall opposite it, a diagonal left
  /// blank is the one that makes the room a rectangle, and a cut left blank is
  /// a third of the room — so a half-filled form still describes a room rather
  /// than nothing.
  RoomOutline? get shape {
    final length = roomLength;
    final width = roomWidth;
    if (length == null || width == null) return null;
    switch (roomKind) {
      case RoomKind.rectangle:
        return RoomShape.rectangle(length, width);
      case RoomKind.uneven:
        return RoomShape(
          lengthNear: length,
          lengthFar: roomLength2 ?? length,
          widthLeft: width,
          widthRight: roomWidth2 ?? width,
          diagonal: roomDiagonal ?? RoomShape.rectangleDiagonal(length, width),
        );
      case RoomKind.chamfer:
      case RoomKind.chamferPair:
      case RoomKind.lShaped:
      case RoomKind.tShaped:
        final cuts = cutsFor(length, width);
        if (roomKind == RoomKind.lShaped) {
          // The one cut shape that keeps a name of its own. A room with a
          // single square cut is an L to everyone who has ever stood in one,
          // and [LRoomShape] says so to everything downstream that was written
          // before there were others — at no cost, since it is the same outline
          // under a different name. The sizes still come from [cutsFor], so
          // there is one place that knows how a cut is measured.
          final only = cuts.entries.single;
          return LRoomShape(
            length: length,
            width: width,
            notchLength: only.value.along,
            notchWidth: only.value.across,
            corner: only.key,
          );
        }
        return CutCornersRoomShape(
          length: length,
          width: width,
          cut: roomKind.cutKind!,
          cuts: cuts,
        );
    }
  }

  /// Which corners this room has taken off and how far each cut reaches.
  ///
  /// The form collects a cut the way it is measured — a chamfer by its one leg,
  /// a T by two shoulders and a depth — and this is where that turns into the
  /// along-and-across pairs the outline wants. Which of the two a shoulder is
  /// depends on the wall the pair stands on, and that is the whole of the
  /// arithmetic here.
  Map<RoomCorner, CornerSize> cutsFor(int length, int width) {
    // A chamfer is given by the wall it leaves, and reaches the same distance
    // along each of the two walls it joins — so what it has to fit against is
    // the shorter side of the room.
    final cutWallMm = notchLength ?? defaultNotch(math.min(length, width));

    if (!roomKind.isPaired) {
      return {
        notchCorner: roomKind.hasOneLeg
            ? CornerSize.chamfer(cutWallMm)
            : CornerSize(
                along: notchLength ?? defaultNotch(length),
                across: notchWidth ?? defaultNotch(width)),
      };
    }

    final pair = cutWall.corners;
    // Two cuts share the wall, so each is offered a quarter of it rather than
    // the third a lone cut gets: a third each would leave them meeting in the
    // middle with barely a room between.
    final side = cutWall.runsAlongLength ? length : width;
    final quarter = heldBetween(side ~/ 4, MIN_NOTCH_MM, side - MIN_ROOM_MM);
    final first = notchLength ?? quarter;
    final second = notchLength2 ?? quarter;
    if (roomKind.hasOneLeg) {
      return {
        pair[0]: CornerSize.chamfer(first),
        pair[1]: CornerSize.chamfer(second),
      };
    }
    // A shoulder is measured along the wall the pair stands on and the depth
    // across it, so which of the two is [CornerSize.along] turns on the wall.
    final depth =
        notchWidth ?? defaultNotch(cutWall.runsAlongLength ? width : length);
    CornerSize sized(int shoulder) => cutWall.runsAlongLength
        ? CornerSize(along: shoulder, across: depth)
        : CornerSize(along: depth, across: shoulder);
    return {pair[0]: sized(first), pair[1]: sized(second)};
  }

  /// The cut a room of this size is given when the user first says it has one:
  /// a third of the side, which is an L anybody recognises on the sketch and
  /// is inside the bounds for every room the form takes. The same courtesy
  /// turning the walls on pays — the form stays valid and only what was
  /// actually measured needs typing.
  static int defaultNotch(int side) =>
      heldBetween(side ~/ 3, MIN_NOTCH_MM, side - LRoomShape.minArmMm);

  CalculateState copyWith({
    final int? roomLength,
    final int? roomWidth,
    final int? roomLength2,
    final int? roomWidth2,
    final int? roomDiagonal,
    final int? notchLength,
    final int? notchWidth,
    final RoomCorner? notchCorner,
    final int? notchLength2,
    final RoomWall? cutWall,
    final RoomKind? roomKind,
    final int? laminateLength,
    final int? laminateWidth,
    final int? quantityPerPack,
    final int? indentFromWall,
    final int? rowOffset,
    final int? minimumLaminateLength,
    final Direction? direction,
    final OffsetMode? offsetMode,
    final MeasurementSystem? system,
  }) {
    return CalculateState(
      roomLength: roomLength ?? this.roomLength,
      roomWidth: roomWidth ?? this.roomWidth,
      roomLength2: roomLength2 ?? this.roomLength2,
      roomWidth2: roomWidth2 ?? this.roomWidth2,
      roomDiagonal: roomDiagonal ?? this.roomDiagonal,
      notchLength: notchLength ?? this.notchLength,
      notchWidth: notchWidth ?? this.notchWidth,
      notchCorner: notchCorner ?? this.notchCorner,
      notchLength2: notchLength2 ?? this.notchLength2,
      cutWall: cutWall ?? this.cutWall,
      roomKind: roomKind ?? this.roomKind,
      laminateLength: laminateLength ?? this.laminateLength,
      laminateWidth: laminateWidth ?? this.laminateWidth,
      quantityPerPack: quantityPerPack ?? this.quantityPerPack,
      indentFromWall: indentFromWall ?? this.indentFromWall,
      rowOffset: rowOffset ?? this.rowOffset,
      minimumLaminateLength: minimumLaminateLength ?? this.minimumLaminateLength,
      direction: direction ?? this.direction,
      offsetMode: offsetMode ?? this.offsetMode,
      system: system ?? this.system,
    );
  }

  @override
  List<Object?> get props => [
        roomLength,
        roomWidth,
        roomLength2,
        roomWidth2,
        roomDiagonal,
        notchLength,
        notchWidth,
        notchCorner,
        notchLength2,
        cutWall,
        roomKind,
        laminateLength,
        laminateWidth,
        quantityPerPack,
        indentFromWall,
        rowOffset,
        minimumLaminateLength,
        direction,
        offsetMode,
        system,
      ];
}
