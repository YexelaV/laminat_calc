import 'package:equatable/equatable.dart';
import 'package:floor_calculator/models.dart';
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

  /// Whether the room was measured wall by wall. Off is not the same as four
  /// equal walls: off means the extra fields are not on screen and the room is
  /// the rectangle it has always been.
  final bool unevenWalls;

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
      this.unevenWalls = false,
      this.laminateLength,
      this.laminateWidth,
      this.quantityPerPack,
      this.indentFromWall,
      this.rowOffset,
      this.minimumLaminateLength,
      this.direction = Direction.length,
      this.offsetMode = OffsetMode.half,
      this.system = MeasurementSystem.metric});

  /// The room the calculation and the drawing both work from, or null until the
  /// two sizes every room needs have been typed.
  ///
  /// A wall left blank is the same as the wall opposite it, and a diagonal left
  /// blank is the one that makes the room a rectangle, so a half-filled form
  /// still describes a room rather than nothing.
  RoomShape? get shape {
    final length = roomLength;
    final width = roomWidth;
    if (length == null || width == null) return null;
    if (!unevenWalls) return RoomShape.rectangle(length, width);
    return RoomShape(
      lengthNear: length,
      lengthFar: roomLength2 ?? length,
      widthLeft: width,
      widthRight: roomWidth2 ?? width,
      diagonal: roomDiagonal ?? RoomShape.rectangleDiagonal(length, width),
    );
  }

  CalculateState copyWith({
    final int? roomLength,
    final int? roomWidth,
    final int? roomLength2,
    final int? roomWidth2,
    final int? roomDiagonal,
    final bool? unevenWalls,
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
      unevenWalls: unevenWalls ?? this.unevenWalls,
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
        unevenWalls,
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
