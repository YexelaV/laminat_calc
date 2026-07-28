import 'package:equatable/equatable.dart';

enum Direction { length, width }

enum OffsetMode { half, third, quarter, exact }

extension OffsetModeFraction on OffsetMode {
  int? get divisor {
    switch (this) {
      case OffsetMode.half:
        return 2;
      case OffsetMode.third:
        return 3;
      case OffsetMode.quarter:
        return 4;
      case OffsetMode.exact:
        return null;
    }
  }
}

class Plank {
  final int number;
  int length;
  int width;
  bool hasLeftLock;
  bool hasRightLock;

  Plank(this.number, this.length, this.width, {this.hasLeftLock = true, this.hasRightLock = true});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Plank &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          length == other.length &&
          width == other.width;

  @override
  int get hashCode => number.hashCode + length.hashCode + width.hashCode;
}

class Line extends Equatable {
  final int number;
  final List<Plank> planks;

  const Line(this.number, this.planks);

  @override
  List<Object> get props => [number, planks];
}

class Result extends Equatable {
  final int totalPlanks;
  final List<Line> lines = [];
  final List<Plank> pieces = [];
  final List<Plank> trash = [];
  final int laminateLength;
  final int roomLength;
  final int roomWidth;
  final int quantityPerPack;
  final Direction direction;

  Result(
    this.laminateLength,
    this.roomLength,
    this.roomWidth,
    this.quantityPerPack,
    this.totalPlanks,
    List<Line> lines,
    List<Plank> pieces,
    List<Plank> trash, {
    required this.direction,
  }) {
    this.lines.addAll(lines);
    this.pieces.addAll(pieces);
    this.trash.addAll(trash);
  }

  @override
  List<Object> get props => [lines, pieces, trash, direction];
}
