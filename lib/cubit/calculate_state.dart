import 'package:equatable/equatable.dart';

class CalculateState extends Equatable {
  final double? roomLength;
  final double? roomWidth;
  final int? laminateLength;
  final int? laminateWidth;
  final int? quantityPerPack;
  final int? indentFromWall;
  final int? rowOffset;
  final int? minimumLaminateLength;

  CalculateState(
      {this.roomLength,
      this.roomWidth,
      this.laminateLength,
      this.laminateWidth,
      this.quantityPerPack,
      this.indentFromWall,
      this.rowOffset,
      this.minimumLaminateLength});

  CalculateState copyWith({
    final double? roomLength,
    final double? roomWidth,
    final int? laminateLength,
    final int? laminateWidth,
    final int? quantityPerPack,
    final int? indentFromWall,
    final int? rowOffset,
    final int? minimumLaminateLength,
  }) {
    return CalculateState(
      roomLength: roomLength ?? this.roomLength,
      roomWidth: roomWidth ?? this.roomWidth,
      laminateLength: laminateLength ?? this.laminateLength,
      laminateWidth: laminateWidth ?? this.laminateWidth,
      quantityPerPack: quantityPerPack ?? this.quantityPerPack,
      indentFromWall: indentFromWall ?? this.quantityPerPack,
      rowOffset: rowOffset ?? this.rowOffset,
      minimumLaminateLength: minimumLaminateLength ?? this.minimumLaminateLength,
    );
  }

  bool roomAndLaminateParametersEntered() =>
      roomLength != null &&
      roomWidth != null &&
      laminateLength != null &&
      laminateWidth != null &&
      quantityPerPack != null;

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
      ];
}
