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

  bool check(Result result) {
    for (var i = 0; i < result.lines.length; i++) {
      for (var j = 0; j < result.lines[i].planks.length; j++) {
        if (result.lines[i].planks[j].length < minimumLaminateLength) {
          return false;
        }
      }
    }
    return true;
  }

  List<Result> calculate() {
    final actualLength = (roomLength * 1000 - indentFromWall * 2).toInt();
    final actualWidth = (roomWidth * 1000 - indentFromWall * 2).toInt();
    numberOfRows =
        (direction == Direction.length ? actualWidth / laminateWidth : actualLength / laminateWidth)
            .ceil();

    final rowLength = direction == Direction.length ? actualLength : actualWidth;

    final result = <Result>[];

    var planksInFirstRow = calculateFirstRow(rowLength, optimizePieces: false);
    var totalPlanks = calculateRows(
      planksInFirstRow,
      rowLength,
      cutPieces: false,
      optimizePieces: false,
    );
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

    planksInFirstRow = calculateFirstRow(rowLength, optimizePieces: true);
    totalPlanks = calculateRows(
      planksInFirstRow,
      rowLength,
      cutPieces: false,
      optimizePieces: true,
    );
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

    planksInFirstRow = calculateFirstRow(rowLength, optimizePieces: false);
    totalPlanks = calculateRows(
      planksInFirstRow,
      rowLength,
      cutPieces: true,
      optimizePieces: false,
    );
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

    planksInFirstRow = calculateFirstRow(rowLength, optimizePieces: true);
    totalPlanks = calculateRows(
      planksInFirstRow,
      rowLength,
      cutPieces: true,
      optimizePieces: true,
    );
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
    //
    result.removeWhere((result) => check(result) == false);
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

  int checkRow(int length, int rowLength, bool optimizePieces) {
    if (length < minimumLaminateLength) return FAIL;
    var currentLength = length;
    while (currentLength + laminateLength < rowLength) {
      currentLength += laminateLength;
    }
    final lastlaminateLength = rowLength - currentLength;
    if (lastlaminateLength == 0) {
      return SUCCESS;
    }
    if (lastlaminateLength < minimumLaminateLength) {
      var diff;
      if (optimizePieces) {
        diff = minimumLaminateLength;
        if (length - diff - rowOffset >= minimumLaminateLength ||
            length - diff + rowOffset <= laminateLength) {
          return diff;
        } else {
          currentLength += minimumLaminateLength;
          diff = currentLength - rowLength;
        }
      } else {
        currentLength += minimumLaminateLength;
        diff = currentLength - rowLength;
      }
      if ((length - diff) >= minimumLaminateLength) {
        return diff;
      }
      if (diff >= length / 2) {
        return (length - diff - rowOffset).toInt();
      }
      return FAIL;
    }
    return SUCCESS;
  }

  int checkPiece(int length, int rowLength, int prevFirstlaminateLength, bool optimizePieces) {
    var diff;
    var newLength;
    //  if (length < rowOffset) return FAIL;
    if ((prevFirstlaminateLength - length).abs() >= rowOffset) {
      diff = checkRow(length, rowLength, optimizePieces);
      switch (diff) {
        case SUCCESS:
        case FAIL:
          return diff;
        default:
          {
            var extraDiff =
                checkPiece((length - diff).toInt(), rowLength, prevFirstlaminateLength, optimizePieces);
            if (extraDiff == FAIL) {
              return FAIL;
            }
            return (diff + extraDiff).toInt();
          }
      }
    } else {
      final rowsDiff = (prevFirstlaminateLength - length).abs();
      if (length < prevFirstlaminateLength) {
        newLength = length - (rowOffset - rowsDiff);
      } else {
        newLength = length - rowsDiff - rowOffset;
      }
      diff = checkRow(newLength, rowLength, optimizePieces);
      switch (diff) {
        case SUCCESS:
          return (length - newLength).toInt();
        case FAIL:
          return FAIL;
        default:
          return (length - (newLength - diff)).toInt();
      }
    }
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
//    print("Row №0");
    // var res = "";
    // lines[0].planks.forEach((element) {
    //   res += '№${element.number}:${element.length} ';
    // });
    //print(res);
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
          trash.add(Plank(pieces[index].number, minDiff, laminateWidth));
          pieces.removeAt(index);
        } else {
          currentLength += pieces[index].length;
          addPlank(pieces[index].number, pieces[index].length, laminateWidth);
          pieces.removeAt(index);
        }
      } else {
        var diff = checkPiece(laminateLength, rowLength, prevFirstlaminateLength, optimizePieces);
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
          trash.add(Plank(pieces[index].number, minDiff, laminateWidth));
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
      //     print("Row №$i");
      // var res = "";
      // lines[i].planks.forEach((element) {
      //   res += '№${element.number}:${element.length} ';
      // });
      //    print(res);
    }
    final actualWidth = (roomWidth * 1000 - indentFromWall * 2).toInt();
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
