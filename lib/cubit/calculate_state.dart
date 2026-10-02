import 'package:equatable/equatable.dart';
import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/utils/units.dart';

/// Which of the three shapes the user says the room is.
///
/// One choice rather than a switch per shape: they are alternatives, not
/// options. A room is measured wall by wall *or* it has a corner cut out of
/// it, and the second assumes the square corners the first exists to avoid.
enum RoomKind { rectangle, uneven, lShaped }

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
  /// and which corner it is — asked for only when the room is Г-shaped.
  final int? notchLength;
  final int? notchWidth;
  final RoomCorner notchCorner;

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
      case RoomKind.lShaped:
        return LRoomShape(
          length: length,
          width: width,
          notchLength: notchLength ?? defaultNotch(length),
          notchWidth: notchWidth ?? defaultNotch(width),
          corner: notchCorner,
        );
      case RoomKind.uneven:
        return RoomShape(
          lengthNear: length,
          lengthFar: roomLength2 ?? length,
          widthLeft: width,
          widthRight: roomWidth2 ?? width,
          diagonal: roomDiagonal ?? RoomShape.rectangleDiagonal(length, width),
        );
    }
  }

  /// The cut a room of this size is given when the user first says it has one:
  /// a third of the side, which is an L anybody recognises on the sketch and
  /// is inside the bounds for every room the form takes. The same courtesy
  /// turning the walls on pays — the form stays valid and only what was
  /// actually measured needs typing.
  static int defaultNotch(int side) =>
      (side ~/ 3).clamp(MIN_NOTCH_MM, side - LRoomShape.minArmMm);

  CalculateState copyWith({
    final int? roomLength,
    final int? roomWidth,
    final int? roomLength2,
    final int? roomWidth2,
    final int? roomDiagonal,
    final int? notchLength,
    final int? notchWidth,
    final RoomCorner? notchCorner,
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
