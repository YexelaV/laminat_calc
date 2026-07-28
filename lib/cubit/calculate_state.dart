import 'package:equatable/equatable.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/utils/units.dart';

class CalculateState extends Equatable {
  // Every dimension is in millimetres.
  final int? roomLength;
  final int? roomWidth;
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
      this.laminateLength,
      this.laminateWidth,
      this.quantityPerPack,
      this.indentFromWall,
      this.rowOffset,
      this.minimumLaminateLength,
      this.direction = Direction.length,
      this.offsetMode = OffsetMode.half,
      this.system = MeasurementSystem.metric});

  CalculateState copyWith({
    final int? roomLength,
    final int? roomWidth,
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
