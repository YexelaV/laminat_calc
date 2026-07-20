import 'models.dart';

const FAIL = -1;
const SUCCESS = 0;

class Calculation {
  final double roomLength;
  final double roomWidth;
  final int laminateLength;
  final int laminateWidth;
  final int planksInPack;
  final double price;
  final int indentFromWall;
  final int minimumLaminateLength;
  final int rowOffset;
  final Direction direction;

  Calculation({
    required this.roomLength,
    required this.roomWidth,
    required this.laminateLength,
    required this.laminateWidth,
    required this.planksInPack,
    required this.price,
    required this.indentFromWall,
    required this.minimumLaminateLength,
    required this.rowOffset,
    required this.direction,
  });

  List<Plank> pieces = [];
  List<Plank> trash = [];
  List<Plank> planks = [];
  List<Line> lines = [];
  late int numberOfRows;

  bool check(Result result, int rowLength) {
    for (final line in result.lines) {
      for (final plank in line.planks) {
        if (plank.length > laminateLength) return false;
        if (plank.length < minimumLaminateLength && plank.length != rowLength) return false;
      }
    }
    for (var i = 1; i < result.lines.length; i++) {
      final prev = result.lines[i - 1].planks.first.length;
      final cur = result.lines[i].planks.first.length;
      if (prev == rowLength || cur == rowLength) continue;
      if ((prev - cur).abs() < rowOffset) return false;
    }
    return true;
  }

  List<Result> calculate() {
    final actualLength = (roomLength * 1000).round() - indentFromWall * 2;
    final actualWidth = (roomWidth * 1000).round() - indentFromWall * 2;
    numberOfRows =
        (direction == Direction.length ? actualWidth / laminateWidth : actualLength / laminateWidth)
            .ceil();

    final rowLength = direction == Direction.length ? actualLength : actualWidth;

    final result = <Result>[];

    for (final cutPieces in [false, true]) {
      for (final optimizePieces in [false, true]) {
        final planksInFirstRow = calculateFirstRow(rowLength, optimizePieces: optimizePieces);
        if (planksInFirstRow == FAIL) continue;
        final totalPlanks = calculateRows(
          planksInFirstRow,
          rowLength,
          cutPieces: cutPieces,
          optimizePieces: optimizePieces,
        );
        if (totalPlanks == FAIL) continue;
        result.add(Result(
          laminateLength,
          laminateWidth,
          roomLength,
          roomWidth,
          planksInPack,
          totalPlanks,
          lines,
          pieces,
          trash,
        ));
      }
    }
    result.removeWhere((result) => check(result, rowLength) == false);
    if (result.isEmpty) return [];
    result.sort((a, b) => a.totalPlanks.compareTo(b.totalPlanks));
    final totalPacks = (result[0].totalPlanks / result[0].quantityPerPack).ceil();
    final total = totalPacks * planksInPack;
    result.removeWhere((result) => result.totalPlanks > total);
    final resultCopy = <Result>[];
    resultCopy.add(result[0]);
    for (int i = 1; i < result.length; i++) {
      final res = resultCopy.where((element) => element == result[i]).toList();
      if (res.isEmpty) {
        resultCopy.add(result[i]);
      }
    }
    return resultCopy;
  }

  void addPlank(int number, int laminateLength, int laminateWidth) {
    planks.add(Plank(number, laminateLength, laminateWidth));
  }

  void addPiece(int number, int pieceLength, int pieceWidth,
      {bool hasLeftLock = true, bool hasRightLock = true}) {
    if (pieceLength >= minimumLaminateLength) {
      pieces.add(Plank(number, pieceLength, pieceWidth,
          hasLeftLock: hasLeftLock, hasRightLock: hasRightLock));
    } else {
      if (pieceLength > 0) {
        trash.add(Plank(number, pieceLength, pieceWidth));
      }
    }
  }

  // Finds how much to cut off (diff) from a plank/piece of length `available`
  // so that the resulting first plank of the row is not shorter than the minimum,
  // differs from the first plank of the previous row by at least rowOffset,
  // and the last plank of the row does not end up shorter than the minimum.
  // With optimizePieces, prefers a cut that produces a reusable
  // offcut (diff >= minimumLaminateLength).
  int findCut(int available, int rowLength, int? prevFirstLength, bool optimizePieces) {
    if (optimizePieces) {
      final noCut = _searchDown(available, available, rowLength, prevFirstLength);
      if (noCut == 0) return 0;
      final reusable =
          _searchDown(available - minimumLaminateLength, available, rowLength, prevFirstLength);
      if (reusable != FAIL) return reusable;
    }
    return _searchDown(available, available, rowLength, prevFirstLength);
  }

  int _searchDown(int startLength, int available, int rowLength, int? prevFirstLength) {
    var firstLength = startLength;
    while (firstLength >= minimumLaminateLength) {
      if (prevFirstLength != null && (firstLength - prevFirstLength).abs() < rowOffset) {
        firstLength = prevFirstLength - rowOffset;
        continue;
      }
      final remaining = rowLength - firstLength;
      final lastLength =
          remaining % laminateLength == 0 ? laminateLength : remaining % laminateLength;
      if (lastLength < minimumLaminateLength) {
        firstLength -= minimumLaminateLength - lastLength;
        continue;
      }
      return available - firstLength;
    }
    return FAIL;
  }

  int checkRow(int length, int rowLength, bool optimizePieces) {
    return findCut(length, rowLength, null, optimizePieces);
  }

  int checkPiece(int length, int rowLength, int prevFirstlaminateLength, bool optimizePieces) {
    return findCut(length, rowLength, prevFirstlaminateLength, optimizePieces);
  }

  int calculateFirstRow(
    int rowLength, {
    required bool optimizePieces,
  }) {
    planks = [];
    trash = [];
    lines = [];
    pieces = [];
    var currentLength = 0;
    int number = 0;
    if (laminateLength >= rowLength) {
      number++;
      addPlank(number, rowLength, laminateWidth);
      addPiece(number, laminateLength - rowLength, laminateWidth, hasRightLock: false);
      lines.add(Line(0, planks));
      return 1;
    }
    final diff = checkRow(laminateLength, rowLength, optimizePieces);
    if (diff == FAIL) return FAIL;
    final firstlaminateLength = laminateLength - diff;
    number++;
    addPlank(number, firstlaminateLength, laminateWidth);
    addPiece(number, diff, laminateWidth, hasRightLock: false);
    currentLength += firstlaminateLength;

    while (currentLength + laminateLength < rowLength) {
      currentLength += laminateLength;
      number++;
      addPlank(number, laminateLength, laminateWidth);
    }
    var lastlaminateLength = rowLength - currentLength;
    number++;
    addPlank(number, lastlaminateLength, laminateWidth);
    addPiece(number, laminateLength - lastlaminateLength, laminateWidth, hasLeftLock: false);
    lines.add(Line(0, planks));
    return number;
  }

  int calculateRows(
    int number,
    int rowLength, {
    required bool cutPieces,
    required bool optimizePieces,
  }) {
    for (int i = 1; i < numberOfRows; i++) {
      planks = [];
      if (laminateLength >= rowLength) {
        number++;
        addPlank(number, rowLength, laminateWidth);
        addPiece(number, laminateLength - rowLength, laminateWidth, hasRightLock: false);
        lines.add(Line(i, planks));
        continue;
      }
      var currentLength = 0;
      final prevFirstlaminateLength = lines[i - 1].planks.first.length;
      var index = -1;
      var minDiff = laminateLength;
      var diff;
      for (int i = 0; i < pieces.length; i++) {
        if (pieces[i].hasRightLock) {
          diff = checkPiece(pieces[i].length, rowLength, prevFirstlaminateLength, optimizePieces);
          if (diff == 0) {
            minDiff = 0;
            index = i;
            break;
          }
          if (diff != FAIL && diff < minDiff && cutPieces) {
            minDiff = diff;
            index = i;
          }
        }
      }
      if (index != -1) {
        if (cutPieces) {
          currentLength += pieces[index].length - minDiff;
          pieces[index].length -= minDiff;
          addPlank(pieces[index].number, pieces[index].length, laminateWidth);
          if (minDiff > 0) {
            trash.add(Plank(pieces[index].number, minDiff, laminateWidth));
          }
          pieces.removeAt(index);
        } else {
          currentLength += pieces[index].length;
          addPlank(pieces[index].number, pieces[index].length, laminateWidth);
          pieces.removeAt(index);
        }
      } else {
        var diff = checkPiece(laminateLength, rowLength, prevFirstlaminateLength, optimizePieces);
        if (diff == FAIL) return FAIL;
        var firstlaminateLength = laminateLength - diff;
        currentLength += firstlaminateLength;
        number++;
        addPlank(number, firstlaminateLength, laminateWidth);
        addPiece(number, laminateLength - firstlaminateLength, laminateWidth, hasRightLock: false);
      }

      while (currentLength + laminateLength < rowLength) {
        currentLength += laminateLength;
        number++;
        addPlank(number, laminateLength, laminateWidth);
      }

      var lastlaminateLength = rowLength - currentLength;
      index = -1;
      minDiff = laminateLength;
      for (int i = 0; i < pieces.length; i++) {
        if (pieces[i].hasLeftLock) {
          if (pieces[i].length >= lastlaminateLength) {
            if (pieces[i].length - lastlaminateLength < minDiff) {
              minDiff = pieces[i].length - lastlaminateLength;
              if (minDiff == 0) {
                index = i;
                break;
              } else if (cutPieces) {
                index = i;
              }
            }
          }
        }
      }

      if (index != -1) {
        if (cutPieces) {
          currentLength += pieces[index].length - minDiff;
          pieces[index].length -= minDiff;
          addPlank(pieces[index].number, pieces[index].length, laminateWidth);
          if (minDiff > 0) {
            trash.add(Plank(pieces[index].number, minDiff, laminateWidth));
          }
          pieces.removeAt(index);
        } else {
          currentLength += pieces[index].length;
          addPlank(pieces[index].number, pieces[index].length, laminateWidth);
          pieces.removeAt(index);
        }
      } else {
        number++;
        addPiece(number, laminateLength - lastlaminateLength, laminateWidth, hasLeftLock: false);
        addPlank(number, lastlaminateLength, laminateWidth);
      }

      lines.add(Line(i, planks));
    }
    final actualWidth = (roomWidth * 1000).round() - indentFromWall * 2;
    var newWidth = laminateWidth - (laminateWidth * lines.length - actualWidth);
    if (newWidth >= 50) {
      lines[lines.length - 1].planks.forEach((plank) {
        plank.width = newWidth;
      });
    } else {
      newWidth = ((newWidth + laminateWidth) ~/ 2);
      lines[0].planks.forEach((plank) {
        plank.width = newWidth;
      });
      lines[lines.length - 1].planks.forEach((plank) {
        plank.width = newWidth;
      });
    }
    return number;
  }
}
