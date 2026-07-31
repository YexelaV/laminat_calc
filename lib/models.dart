import 'package:equatable/equatable.dart';

enum Direction { length, width, diagonal }

/// Which corner of a plank end carries the material. A 45° cut leaves one
/// parallel side longer than the other: [up] when the long corner sits on the
/// far side of the row, [down] when it sits on the near side. Straight laying
/// meets every wall head on and only ever produces [square].
///
/// Cutting one plank in two yields complementary ends — the offcut owns the
/// corner the plank gave up — which is what decides whether a leftover can be
/// slotted into a later row.
enum Bevel { square, up, down }

extension BevelComplement on Bevel {
  Bevel get complement {
    switch (this) {
      case Bevel.square:
        return Bevel.square;
      case Bevel.up:
        return Bevel.down;
      case Bevel.down:
        return Bevel.up;
    }
  }
}

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

  /// The shape of each end. [length] is the centreline, so a bevelled end
  /// reaches half a width further on one side and half a width less on the
  /// other; which side is what [Bevel] records.
  Bevel leftBevel;
  Bevel rightBevel;

  Plank(
    this.number,
    this.length,
    this.width, {
    this.hasLeftLock = true,
    this.hasRightLock = true,
    this.leftBevel = Bevel.square,
    this.rightBevel = Bevel.square,
  });

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

  /// Where the row begins on the axis all rows share. Rows of a diagonal
  /// layout start at different places, and the drawing has to take the shift
  /// from here rather than derive it again, or the two will disagree.
  final int startOffsetMm;

  const Line(this.number, this.planks, {this.startOffsetMm = 0});

  @override
  List<Object> get props => [number, planks, startOffsetMm];
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

  /// The expansion gap left around the floor. The drawing needs it to know
  /// where the laid area sits inside the room, which for a 45° layout is the
  /// difference between meeting the walls and floating free of them.
  final int indentFromWall;

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
    required this.indentFromWall,
  }) {
    this.lines.addAll(lines);
    this.pieces.addAll(pieces);
    this.trash.addAll(trash);
  }

  @override
  List<Object> get props => [lines, pieces, trash, direction];
}
