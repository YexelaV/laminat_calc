import 'package:equatable/equatable.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_kind.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';

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
  /// What the shape is made of is the shape's own business — see
  /// [RoomKind.outlineFor]. All this knows is that no room is anything until
  /// those two sizes are.
  RoomOutline? get shape {
    final length = roomLength;
    final width = roomWidth;
    if (length == null || width == null) return null;
    return roomKind.outlineFor(this, length, width);
  }

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
