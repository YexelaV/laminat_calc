import 'models.dart';

const FAIL = -1;
const SUCCESS = 0;

// The exact-offset laying pattern is a staircase: each row's first plank is
// exactly rowOffset shorter than the previous one; when the next step would
// drop below the minimum piece length the pattern restarts from the first
// row's length f0. So for a given minimum m the pattern consists of
// k = (f0 - m) ~/ rowOffset + 1 distinct first lengths f0, f0-d, ..., f0-(k-1)d.
//
// Upper bound for the minimum piece length such that some pattern start f0
// keeps every first AND last plank of the used rows at least that long.
// For each f0 and pattern size k the admissible m lie in (f_k - d, f_k]
// (that range is what makes the restart happen after exactly k rows), and
// m is also capped by the shortest first/last plank among the used rows.
int maxMinimumLaminateLengthExact(
    int rowLength, int laminateLength, int rowOffset, int numberOfRows) {
  if (laminateLength >= rowLength) {
    // Single-plank rows: every plank equals the row length and the
    // minimum length constraint never applies.
    return laminateLength;
  }
  if (rowOffset <= 0 || numberOfRows <= 0) return 0;
  int lastOf(int first) {
    final remaining = rowLength - first;
    return remaining % laminateLength == 0 ? laminateLength : remaining % laminateLength;
  }

  var best = 0;
  for (var f0 = laminateLength; f0 > best; f0--) {
    var bound = laminateLength;
    for (var k = 1;; k++) {
      final fk = f0 - (k - 1) * rowOffset;
      if (fk < 1) break;
      if (k <= numberOfRows) {
        if (fk < bound) bound = fk;
        final last = lastOf(fk);
        if (last < bound) bound = last;
      }
      // A pattern of a single row length means aligned joints on every row.
      if (k == 1 && numberOfRows > 1) continue;
      final candidate = bound < fk ? bound : fk;
      if (candidate > fk - rowOffset && candidate > best) best = candidate;
    }
  }
  return best;
}

// Whether a laying variant exists for the given exact offset and minimum
// piece length. Feasibility is NOT monotone in the minimum: a larger minimum
// shortens the staircase, which can avoid row starts whose last plank would
// be too short. So the value must be checked exactly, not against a bound.
bool exactOffsetFeasible(int rowLength, int laminateLength, int rowOffset, int minimumLength,
    int numberOfRows) {
  if (laminateLength >= rowLength) return true;
  if (rowOffset <= 0 || minimumLength < 1 || numberOfRows <= 0) return false;
  int lastOf(int first) {
    final remaining = rowLength - first;
    return remaining % laminateLength == 0 ? laminateLength : remaining % laminateLength;
  }

  for (var f0 = laminateLength; f0 >= minimumLength; f0--) {
    var f = f0;
    var ok = true;
    for (var i = 0; i < numberOfRows; i++) {
      if (lastOf(f) < minimumLength) {
        ok = false;
        break;
      }
      f -= rowOffset;
      if (f < minimumLength) {
        // Restarting right after the first row would align the joints.
        if (i == 0 && numberOfRows > 1) ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

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
  // First plank length of the first row; the staircase pattern restarts
  // from this value.
  int _patternStart = 0;

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
      // Exact staircase: either one step down or a restart of the pattern
      // (a jump up by a whole number of steps).
      final stepDown = prev - cur == rowOffset;
      final restart = cur > prev && (cur - prev) % rowOffset == 0;
      if (!stepDown && !restart) return false;
    }
    return true;
  }

  int _lastOf(int firstLength, int rowLength) {
    final remaining = rowLength - firstLength;
    return remaining % laminateLength == 0 ? laminateLength : remaining % laminateLength;
  }

  // A pattern start f0 is feasible when every used row of the staircase
  // f0, f0-d, ... (restarting from f0 below the minimum) keeps its last
  // plank at least the minimum long. Values repeat after a restart, so
  // checking until the first restart is enough.
  bool _patternFeasible(int f0, int rowLength) {
    var f = f0;
    for (var i = 0; i < numberOfRows; i++) {
      if (_lastOf(f, rowLength) < minimumLaminateLength) return false;
      f -= rowOffset;
      if (f < minimumLaminateLength) {
        // Restarting right after the first row would align the joints.
        if (i == 0 && numberOfRows > 1) return false;
        break;
      }
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
          direction: direction,
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
  // so that the resulting first plank of the row fits the exact staircase
  // pattern. For the first row (prevFirstLength == null) the pattern start f0
  // is searched from the top down; for subsequent rows the first length is
  // fully determined by the pattern. With optimizePieces, prefers a cut that
  // produces a reusable offcut (diff >= minimumLaminateLength).
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
    if (prevFirstLength != null) {
      var required = prevFirstLength - rowOffset;
      if (required < minimumLaminateLength) required = _patternStart;
      if (required == prevFirstLength) return FAIL;
      if (required > startLength || required < minimumLaminateLength) return FAIL;
      if (_lastOf(required, rowLength) < minimumLaminateLength) return FAIL;
      return available - required;
    }
    for (var f0 = startLength; f0 >= minimumLaminateLength; f0--) {
      if (_patternFeasible(f0, rowLength)) return available - f0;
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
      _patternStart = rowLength;
      number++;
      addPlank(number, rowLength, laminateWidth);
      addPiece(number, laminateLength - rowLength, laminateWidth, hasRightLock: false);
      lines.add(Line(0, planks));
      return 1;
    }
    final diff = checkRow(laminateLength, rowLength, optimizePieces);
    if (diff == FAIL) return FAIL;
    final firstlaminateLength = laminateLength - diff;
    _patternStart = firstlaminateLength;
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
    // The dimension across the rows: room width when laying along the
    // length, room length when laying along the width.
    final acrossSize = (direction == Direction.length ? roomWidth : roomLength) * 1000;
    final actualWidth = acrossSize.round() - indentFromWall * 2;
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
