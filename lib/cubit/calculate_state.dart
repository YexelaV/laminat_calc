import 'package:equatable/equatable.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/utils/units.dart';

class CalculateState extends Equatable {
  final double? roomLength;
  final double? roomWidth;
  final int? laminateLength;
  final int? laminateWidth;
  final int? quantityPerPack;
  final int? indentFromWall;
  final int? rowOffset;
  final int? minimumLaminateLength;
  final Direction direction;
  final MeasurementSystem system;

  CalculateState(
      {this.roomLength,
      this.roomWidth,
      this.laminateLength,
      this.laminateWidth,
      this.quantityPerPack,
      this.indentFromWall,
      this.rowOffset,
      this.minimumLaminateLength,
      this.direction = Direction.length,
      this.system = MeasurementSystem.metric});

  CalculateState copyWith({
    final double? roomLength,
    final double? roomWidth,
    final int? laminateLength,
    final int? laminateWidth,
    final int? quantityPerPack,
    final int? indentFromWall,
    final int? rowOffset,
    final int? minimumLaminateLength,
    final Direction? direction,
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
      system: system ?? this.system,
    );
  }

  bool layingParametersEntered() =>
      indentFromWall != null && rowOffset != null && minimumLaminateLength != null;

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
        system,
      ];
}
