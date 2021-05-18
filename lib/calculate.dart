import 'models.dart';

const FAIL = -1;
const SUCCESS = 0;

class Calculation {
  final double roomLength;
  final double roomWidth;
  final int plankLength;
  final int plankWidth;
  final int planksInPack;
  final double price;
  final int indent;
  final int minLength;
  final int rowOffset;
  final Direction direction;

  Calculation({
    this.roomLength,
    this.roomWidth,
    this.plankLength,
    this.plankWidth,
    this.planksInPack,
    this.price,
    this.indent,
    this.minLength,
    this.rowOffset,
    this.direction,
  });

  List<Plank> pieces = [];
  List<Plank> trash = [];
  List<Plank> planks = [];
  List<Line> lines = [];
  int numberOfRows;

  List<Result> calculate() {
    final actualLength = (roomLength * 1000 - indent * 2).toInt();
    final actualWidth = (roomWidth * 1000 - indent * 2).toInt();
    numberOfRows =
        (direction == Direction.length ? actualWidth / plankWidth : actualLength / plankWidth)
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
      plankLength,
      plankWidth,
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
      plankLength,
      plankWidth,
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
      plankLength,
      plankWidth,
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
      plankLength,
      plankWidth,
      roomLength,
      roomWidth,
      planksInPack,
      totalPlanks,
      lines,
      pieces,
      trash,
    ));
    result.sort((a, b) => a.totalPlanks.compareTo(b.totalPlanks));
    final totalPacks = (result[0].totalPlanks / result[0].itemsInPack).ceil();
    final total = totalPacks * planksInPack;
    result.removeWhere((result) => result.totalPlanks > total);
    final resultCopy = <Result>[];
    resultCopy.addAll(result);
    var i = 0;
    var count = 0;
    while (count < resultCopy.length) {
      var j = i + 1;
      while (j < result.length) {
        if (result[i] == result[j]) {
          result.removeAt(j);
        }
        j++;
      }
      count++;
    }
    return result;
  }

  void addPlank(int number, int plankLength, int plankWidth) {
    planks.add(Plank(number, plankLength, plankWidth));
  }

  void addPiece(int number, int pieceLength, int pieceWidth) {
    if (pieceLength >= minLength) {
      pieces.add(Plank(number, pieceLength, pieceWidth));
    } else {
      if (pieceLength > 0) {
        trash.add(Plank(number, pieceLength, pieceWidth));
      }
    }
  }

  int checkRow(int length, int rowLength, bool optimizePieces) {
    if (length < minLength) return FAIL;
    var currentLength = length;
    while (currentLength + plankLength < rowLength) {
      currentLength += plankLength;
    }
    final lastPlankLength = rowLength - currentLength;
    if (lastPlankLength == 0) {
      return SUCCESS;
    }
    if (lastPlankLength < minLength) {
      var diff;
      if (optimizePieces) {
        diff = minLength;
        if (length - diff - rowOffset >= minLength || length - diff + rowOffset <= plankLength) {
          return diff;
        } else {
          currentLength += minLength;
          diff = currentLength - rowLength;
        }
      } else {
        currentLength += minLength;
        diff = currentLength - rowLength;
      }
      if ((length - diff) >= minLength) {
        return diff;
      }
      if (diff >= length / 2) {
        return length - diff - rowOffset;
      }
      return FAIL;
    }
    return SUCCESS;
  }

  int checkPiece(int length, int rowLength, int prevFirstPlankLength, bool optimizePieces) {
    var diff;
    var newLength;
    if (length < rowOffset) return FAIL;
    if ((prevFirstPlankLength - length).abs() >= rowOffset) {
      diff = checkRow(length, rowLength, optimizePieces);
      switch (diff) {
        case SUCCESS:
        case FAIL:
          return diff;
        default:
          {
            var extraDiff =
                checkPiece(length - diff, rowLength, prevFirstPlankLength, optimizePieces);
            if (extraDiff == FAIL) {
              return FAIL;
            }
            return diff + extraDiff;
          }
      }
    } else {
      final rowsDiff = (prevFirstPlankLength - length).abs();
      if (length < prevFirstPlankLength) {
        newLength = length - (rowOffset - rowsDiff);
      } else {
        newLength = length - rowsDiff - rowOffset;
      }
      diff = checkRow(newLength, rowLength, optimizePieces);
      switch (diff) {
        case SUCCESS:
          return (length - newLength);
        case FAIL:
          return FAIL;
        default:
          return (length - newLength) - diff;
      }
    }
  }

  int calculateFirstRow(
    int rowLength, {
    bool optimizePieces,
  }) {
    planks = [];
    trash = [];
    lines = [];
    pieces = [];
    var currentLength = 0;
    int number = 0;
    final diff = checkRow(plankLength, rowLength, optimizePieces);
    final firstPlankLength = plankLength - diff;
    number++;
    addPlank(number, firstPlankLength, plankWidth);
    addPiece(number, diff, plankWidth);
    currentLength += firstPlankLength;

    while (currentLength + plankLength < rowLength) {
      currentLength += plankLength;
      number++;
      addPlank(number, plankLength, plankWidth);
    }
    var lastPlankLength = rowLength - currentLength;
    number++;
    addPlank(number, lastPlankLength, plankWidth);
    addPiece(number, plankLength - lastPlankLength, plankWidth);
    lines.add(Line(0, planks));
//    print("Row №0");
    var res = "";
    lines[0].planks.forEach((element) {
      res += '№${element.number}:${element.length} ';
    });
    //print(res);
    return number;
  }

  int calculateRows(
    int number,
    int rowLength, {
    bool cutPieces,
    bool optimizePieces,
  }) {
    for (int i = 1; i < numberOfRows; i++) {
      planks = [];
      var currentLength = 0;
      final prevFirstPlankLength = lines[i - 1].planks.first.length;
      var index = -1;
      var minDiff = plankLength;
      var diff;
      for (int i = 0; i < pieces.length; i++) {
        diff = checkPiece(pieces[i].length, rowLength, prevFirstPlankLength, optimizePieces);
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
      if (index != -1) {
        if (cutPieces) {
          currentLength += pieces[index].length - minDiff;
          pieces[index].length -= minDiff;
          addPlank(pieces[index].number, pieces[index].length, plankWidth);
          addPiece(pieces[index].number, minDiff, plankWidth);
          pieces.removeAt(index);
        } else {
          currentLength += pieces[index].length;
          addPlank(pieces[index].number, pieces[index].length, plankWidth);
          pieces.removeAt(index);
        }
      } else {
        var diff = checkPiece(plankLength, rowLength, prevFirstPlankLength, optimizePieces);
        var firstPlankLength = plankLength - diff;
        currentLength += firstPlankLength;
        number++;
        addPlank(number, firstPlankLength, plankWidth);
        addPiece(number, plankLength - firstPlankLength, plankWidth);
      }

      while (currentLength + plankLength < rowLength) {
        currentLength += plankLength;
        number++;
        addPlank(number, plankLength, plankWidth);
      }

      var lastPlankLength = rowLength - currentLength;
      index = -1;
      minDiff = plankLength;
      for (int i = 0; i < pieces.length; i++) {
        if (pieces[i].length >= lastPlankLength) {
          if (pieces[i].length - lastPlankLength < minDiff) {
            minDiff = pieces[i].length - lastPlankLength;
            if (minDiff == 0) {
              index = i;
              break;
            } else if (cutPieces) {
              index = i;
            }
          }
        }
      }

      if (index != -1) {
        if (cutPieces) {
          currentLength += pieces[index].length - minDiff;
          pieces[index].length -= minDiff;
          addPlank(pieces[index].number, pieces[index].length, plankWidth);
          addPiece(pieces[index].number, minDiff, plankWidth);
          pieces.removeAt(index);
        } else {
          currentLength += pieces[index].length;
          addPlank(pieces[index].number, pieces[index].length, plankWidth);
          pieces.removeAt(index);
        }
      } else {
        number++;
        addPiece(number, plankLength - lastPlankLength, plankWidth);
        addPlank(number, lastPlankLength, plankWidth);
      }

      lines.add(Line(i, planks));
      //     print("Row №$i");
      var res = "";
      lines[i].planks.forEach((element) {
        res += '№${element.number}:${element.length} ';
      });
      //    print(res);
    }
    return number;
  }
}
