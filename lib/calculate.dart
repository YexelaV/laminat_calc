import 'dart:math' as math;

import 'models.dart';
import 'row_plan.dart';

// All dimensions are in millimetres. The field validators and the calculation
// itself must derive the row geometry from here and nowhere else: feasibility
// is not monotone in the minimum plank length, so even a 1 mm disagreement
// between them flips it.
// Rows laid parallel to a wall are all one length. Rows at 45° are not — they
// grow and then shrink across the room — so there is no single number to give
// and the caller has to ask [planFor] for the row it means.
int rowLengthMm({
  required int roomLength,
  required int roomWidth,
  required int indentFromWall,
  required Direction direction,
}) {
  assert(direction != Direction.diagonal, 'a 45° layout has no one row length');
  return (direction == Direction.length ? roomLength : roomWidth) - indentFromWall * 2;
}

int numberOfRowsMm({
  required int roomLength,
  required int roomWidth,
  required int indentFromWall,
  required int laminateWidth,
  required Direction direction,
}) {
  if (direction == Direction.diagonal) {
    // Rows at 45° are stacked across the diagonal of the room, not across one
    // of its sides, so there are more of them than either side would suggest.
    return diagonalRowCount(
      a: roomLength - indentFromWall * 2,
      b: roomWidth - indentFromWall * 2,
      laminateWidth: laminateWidth,
    );
  }
  final across = direction == Direction.length ? roomWidth : roomLength;
  return ((across - indentFromWall * 2) / laminateWidth).ceil();
}

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
bool exactOffsetFeasible(
    int rowLength, int laminateLength, int rowOffset, int minimumLength, int numberOfRows) {
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

/// An upper bound for the minimum plank length of a 45° layout.
///
/// A bound and nothing more. A row that takes more than one plank needs a
/// first and a last one, so the minimum cannot pass half the shortest such
/// row; and a first plank is cut on the slant, so it cannot pass the row's
/// reach either. Whether a value under the bound can be laid is a search, and
/// [diagonalFeasible] is the one that runs it.
int maxMinimumLaminateLengthDiagonal({
  required int roomLength,
  required int roomWidth,
  required int indentFromWall,
  required int laminateLength,
  required int laminateWidth,
}) {
  final plan = planFor(
    roomLength: roomLength,
    roomWidth: roomWidth,
    indentFromWall: indentFromWall,
    laminateLength: laminateLength,
    laminateWidth: laminateWidth,
    direction: Direction.diagonal,
  );
  var bound = laminateLength;
  for (var i = 0; i < plan.numberOfRows; i++) {
    // A row one plank spans holds whatever the geometry leaves it, however
    // short: there is no joint in it to keep away from anything.
    if (plan.capWhole[i] >= plan.lengths[i]) continue;
    bound = math.min(bound, math.min(plan.lengths[i] ~/ 2, plan.capFirst[i]));
  }
  return bound;
}

String? _feasibleKey;
bool _feasibleAnswer = false;

/// Whether a 45° layout exists for these parameters.
///
/// Straight laying is answered in closed form by [exactOffsetFeasible]: the
/// rows are all one length, so the pattern either fits or it does not.
/// Diagonal rows are not, and where their joints can go has to be searched
/// for. A search is not a formula, and a second implementation of it would
/// drift from the first — so the form asks the engine itself, and what it
/// promises is exactly what the user then gets.
///
/// The answer is kept for the last question asked, because the form asks the
/// same one several times per keystroke.
bool diagonalFeasible({
  required int roomLength,
  required int roomWidth,
  required int indentFromWall,
  required int laminateLength,
  required int laminateWidth,
  required int minimumLaminateLength,
  required int rowOffset,
}) {
  final key = '$roomLength/$roomWidth/$indentFromWall/$laminateLength/'
      '$laminateWidth/$minimumLaminateLength/$rowOffset';
  if (key == _feasibleKey) return _feasibleAnswer;
  _feasibleKey = key;
  _feasibleAnswer = Calculation(
    roomLength: roomLength,
    roomWidth: roomWidth,
    laminateLength: laminateLength,
    laminateWidth: laminateWidth,
    planksInPack: 1,
    indentFromWall: indentFromWall,
    minimumLaminateLength: minimumLaminateLength,
    rowOffset: rowOffset,
    direction: Direction.diagonal,
  ).calculate().isNotEmpty;
  return _feasibleAnswer;
}

class Calculation {
  final int roomLength;
  final int roomWidth;
  final int laminateLength;
  final int laminateWidth;
  final int planksInPack;
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
  // Rows that hold more than one plank, in order. A row a single plank spans
  // has no joint, so the staircase steps straight over it; a diagonal layout
  // starts and ends with a run of such rows.
  List<int> _jointed = [];
  // The joint the staircase restarts from, and the last one laid. Null until a
  // row with a joint has been laid.
  int _patternStartJoint = 0;
  int? _lastJoint;
  // Length to cut off, set by the last successful findCut call.
  int _cut = 0;
  // Running plank counter; holds the total once the rows are laid.
  int _plankCount = 0;

  bool check(Result result, RowPlan plan) {
    for (var i = 0; i < result.lines.length; i++) {
      final planks = result.lines[i].planks;
      for (var j = 0; j < planks.length; j++) {
        if (planks[j].length > _cap(plan, i, j, planks.length)) return false;
        if (planks[j].length < minimumLaminateLength && planks[j].length != plan.lengths[i]) {
          return false;
        }
      }
    }
    for (var i = 1; i < result.lines.length; i++) {
      final prevFirst = result.lines[i - 1].planks.first.length;
      final curFirst = result.lines[i].planks.first.length;
      if (prevFirst == plan.lengths[i - 1] || curFirst == plan.lengths[i]) continue;
      // Rows are parallel but need not start at the same place, so what has to
      // step is the joint on the shared axis, not the first plank's length.
      // Straight laying has startU ≡ 0 and the two coincide.
      final prev = plan.startU[i - 1] + prevFirst;
      final cur = plan.startU[i] + curFirst;
      if (plan.isUniform) {
        // Rows of one length can all carry the same grid of joints, so the
        // pattern is exact: one step down, or a restart a whole number of steps
        // up.
        if (prev == cur || (prev - cur) % rowOffset != 0) return false;
      } else {
        // Rows of different lengths cannot: the joints a row can hold are a
        // window set by its own length, and the windows of two rows need share
        // no point of any one grid. What the offset is actually for — keeping
        // the joints of neighbouring rows apart — survives without it.
        if ((prev - cur).abs() < rowOffset) return false;
      }
    }
    return true;
  }

  // The longest centreline a plank may have in slot [j] of row [i]. A bevelled
  // end has to be cut out of the plank on the slant and costs reach, so a plank
  // that fills a whole row on its own is capped hardest.
  int _cap(RowPlan plan, int row, int slot, int planksInRow) {
    if (planksInRow == 1) return plan.capWhole[row];
    if (slot == 0) return plan.capFirst[row];
    if (slot == planksInRow - 1) return plan.capLast[row];
    return laminateLength;
  }

  int _lastOf(int firstLength, int rowLength) {
    final remaining = rowLength - firstLength;
    return remaining % laminateLength == 0 ? laminateLength : remaining % laminateLength;
  }

  // A pattern start f0 for the jointed row [from] is feasible when the
  // staircase it starts reaches every later jointed row with a first and a last
  // plank that row can hold. It is walked with the same [_nextJoint] the laying
  // uses, so what the search promises is what the rows get.
  bool _patternFeasible(int f0, RowPlan plan, int from) {
    final start = plan.startU[_jointed[from]] + f0;
    var joint = start;
    for (var k = from; k < _jointed.length; k++) {
      final i = _jointed[k];
      final f = joint - plan.startU[i];
      if (f < minimumLaminateLength || f > plan.capFirst[i]) return false;
      if (!_lastFits(f, plan, i)) return false;
      if (k + 1 >= _jointed.length) break;
      final next = _jointed[k + 1];
      final step = _nextJoint(joint, plan, next, plan.capFirst[next], start);
      if (step == null) return false;
      joint = step;
    }
    return true;
  }

  // The row's closing plank must be long enough to be worth laying and short
  // enough to be cut out of one plank, bevel included.
  bool _lastFits(int firstLength, RowPlan plan, int row) =>
      _tailPlanks(_lastOf(firstLength, plan.lengths[row]), plan, row) != null;

  /// The planks that close a row once the whole ones are down, or null when
  /// [tail] cannot be closed at all.
  ///
  /// Usually one offcut. A bevelled row cannot end with a plank longer than
  /// its [RowPlan.capLast], though, and a row of n planks holds at most
  /// (n-1)·laminateLength + capLast — so a tail that overruns is closed by one
  /// more plank rather than rejected. One more is always enough, and going
  /// further only makes the pieces shorter than the minimum. Straight laying
  /// has capLast == laminateLength and never reaches the split.
  List<int>? _tailPlanks(int tail, RowPlan plan, int row) {
    if (tail < minimumLaminateLength) return null;
    if (tail <= plan.capLast[row]) return [tail];
    final inner = math.max(minimumLaminateLength, tail - plan.capLast[row]);
    final last = tail - inner;
    if (last < minimumLaminateLength) return null;
    return [inner, last];
  }

  int get rowLength => rowLengthMm(
        roomLength: roomLength,
        roomWidth: roomWidth,
        indentFromWall: indentFromWall,
        direction: direction,
      );

  List<Result> calculate() {
    final plan = planFor(
      roomLength: roomLength,
      roomWidth: roomWidth,
      indentFromWall: indentFromWall,
      laminateLength: laminateLength,
      laminateWidth: laminateWidth,
      direction: direction,
    );
    numberOfRows = plan.numberOfRows;

    final result = <Result>[];

    for (final cutPieces in [false, true]) {
      for (final optimizePieces in [false, true]) {
        if (!calculateFirstRow(plan, optimizePieces: optimizePieces)) continue;
        if (!calculateRows(plan, cutPieces: cutPieces, optimizePieces: optimizePieces)) {
          continue;
        }
        result.add(Result(
          laminateLength,
          roomLength,
          roomWidth,
          planksInPack,
          _plankCount,
          lines,
          pieces,
          trash,
          direction: direction,
          indentFromWall: indentFromWall,
        ));
      }
    }
    result.removeWhere((result) => check(result, plan) == false);
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

  void addPlank(int number, int laminateLength, int laminateWidth,
      {Bevel leftBevel = Bevel.square, Bevel rightBevel = Bevel.square}) {
    planks.add(Plank(number, laminateLength, laminateWidth,
        leftBevel: leftBevel, rightBevel: rightBevel));
  }

  void addPiece(int number, int pieceLength, int pieceWidth,
      {bool hasLeftLock = true,
      bool hasRightLock = true,
      Bevel leftBevel = Bevel.square,
      Bevel rightBevel = Bevel.square}) {
    if (pieceLength >= minimumLaminateLength) {
      pieces.add(Plank(number, pieceLength, pieceWidth,
          hasLeftLock: hasLeftLock,
          hasRightLock: hasRightLock,
          leftBevel: leftBevel,
          rightBevel: rightBevel));
    } else {
      if (pieceLength > 0) {
        trash.add(Plank(number, pieceLength, pieceWidth,
            leftBevel: leftBevel, rightBevel: rightBevel));
      }
    }
  }

  // Looks for how much to cut off a plank/piece of length `available` so that
  // the resulting first plank of the row fits the exact staircase pattern, and
  // reports whether such a cut exists; the amount lands in [_cut]. For the
  // first row (prevFirstLength == null) the pattern start f0 is searched from
  // the top down; for subsequent rows the first length is fully determined by
  // the pattern. With optimizePieces, prefers a cut that produces a reusable
  // offcut (_cut >= minimumLaminateLength).
  //
  // How much material is on hand and how far it may reach are two different
  // numbers: a bevelled end is cut on the slant, so the piece keeps its full
  // length but covers less of the row. Straight laying has them equal.
  bool findCut(
      int available, int reachLoss, RowPlan plan, int row, int? prevJoint, bool optimizePieces) {
    final cap = math.min(available - reachLoss, plan.capFirst[row]);
    if (optimizePieces) {
      if (_searchDown(cap, available, plan, row, prevJoint) && _cut == 0) return true;
      if (_searchDown(
          math.min(cap, available - minimumLaminateLength), available, plan, row, prevJoint)) {
        return true;
      }
    }
    return _searchDown(cap, available, plan, row, prevJoint);
  }

  /// What a piece has to give up so that its end becomes the one the row wants.
  ///
  /// Trimming a square end on the slant produces the bevel as a by-product, so
  /// the only cost is reach — the same half width a bevel costs a full plank,
  /// which is exactly what [RowPlan.capFirst] is short by. An end already cut
  /// the right way costs nothing, and one cut the other way is unusable: a 45°
  /// cut cannot be turned round.
  int? _reachLoss(RowPlan plan, int row, Bevel have, Bevel want) {
    if (have == want) return 0;
    if (have == Bevel.square) return laminateLength - plan.capFirst[row];
    return null;
  }

  bool _searchDown(int startLength, int available, RowPlan plan, int row, int? prevJoint) {
    if (prevJoint != null) {
      final joint = _nextJoint(prevJoint, plan, row, startLength, _patternStartJoint);
      if (joint == null) return false;
      final required = joint - plan.startU[row];
      if (!_lastFits(required, plan, row)) return false;
      _cut = available - required;
      return true;
    }
    final from = _jointed.indexOf(row);
    for (var f0 = startLength; f0 >= minimumLaminateLength; f0--) {
      if (_patternFeasible(f0, plan, from)) {
        _cut = available - f0;
        return true;
      }
    }
    return false;
  }

  /// The joint of row [row], one step down from [prevJoint] where the row can
  /// hold that and as near below it as the row allows where it cannot.
  ///
  /// The staircase lives on the joint, not on the first plank's length: rows of
  /// a diagonal layout begin at different places, so one joint is a different
  /// first plank in every row. Straight laying starts every row at zero, and
  /// there the joint and the first plank's length are the same number.
  ///
  /// The two layouts also want different things of the offset. Rows of one
  /// length share one grid of joints, and the pattern can be exact — step down
  /// by [rowOffset] until the row runs out of room, then restart from
  /// [patternStart]. Rows of different lengths share no grid: each row can only
  /// hold joints inside a window of its own, and for some rooms no grid meets
  /// every window, so insisting on one leaves the room unlayable. There the
  /// offset keeps the meaning it is for — neighbouring joints stay at least
  /// [rowOffset] apart — and the exact step is only a preference.
  ///
  /// [cap] is how far the material on hand reaches, [plan.capFirst] how far the
  /// row lets it: only the latter is worth searching around, because a piece
  /// too short for this row may still be right for the next one.
  int? _nextJoint(int prevJoint, RowPlan plan, int row, int cap, int patternStart) {
    final limit = math.min(cap, plan.capFirst[row]);
    bool usable(int joint) {
      final f = joint - plan.startU[row];
      return f >= minimumLaminateLength && f <= limit && _lastFits(f, plan, row);
    }

    final down = prevJoint - rowOffset;
    if (plan.isUniform) {
      final joint = down < minimumLaminateLength ? patternStart : down;
      if (joint == prevJoint || !usable(joint)) return null;
      return joint;
    }
    final low = plan.startU[row] + minimumLaminateLength;
    final high = plan.startU[row] + limit;
    if (high < low) return null;
    // Keep descending while the row can take it — that is the staircase the
    // straight layout draws — and only climb back over the previous joint when
    // the row cannot hold anything below it.
    for (var joint = math.min(down, high); joint >= low; joint--) {
      if (usable(joint)) return joint;
    }
    for (var joint = math.max(low, prevJoint + rowOffset); joint <= high; joint++) {
      if (usable(joint)) return joint;
    }
    return null;
  }

  bool checkRow(int length, int reachLoss, RowPlan plan, bool optimizePieces) {
    return findCut(length, reachLoss, plan, 0, null, optimizePieces);
  }

  bool checkPiece(
      int length, int reachLoss, RowPlan plan, int row, int? prevJoint, bool optimizePieces) {
    return findCut(length, reachLoss, plan, row, prevJoint, optimizePieces);
  }

  bool calculateFirstRow(
    RowPlan plan, {
    required bool optimizePieces,
  }) {
    final rowLength = plan.lengths[0];
    planks = [];
    trash = [];
    lines = [];
    pieces = [];
    var currentLength = 0;
    _plankCount = 0;
    _lastJoint = null;
    _jointed = [
      for (var i = 0; i < plan.numberOfRows; i++)
        if (plan.capWhole[i] < plan.lengths[i]) i
    ];
    if (plan.capWhole[0] >= rowLength) {
      _plankCount++;
      addPlank(_plankCount, rowLength, laminateWidth,
          leftBevel: plan.startBevel[0], rightBevel: plan.endBevel[0]);
      addPiece(_plankCount, laminateLength - rowLength, laminateWidth,
          hasRightLock: false, rightBevel: plan.startBevel[0].complement);
      lines.add(Line(0, planks, startOffsetMm: plan.startU[0]));
      return true;
    }
    final fromPlank = laminateLength - plan.capFirst[0];
    if (!checkRow(laminateLength, fromPlank, plan, optimizePieces)) return false;
    final diff = _cut;
    final firstlaminateLength = laminateLength - diff;
    _patternStartJoint = plan.startU[0] + firstlaminateLength;
    _lastJoint = _patternStartJoint;
    _plankCount++;
    addPlank(_plankCount, firstlaminateLength, laminateWidth, leftBevel: plan.startBevel[0]);
    addPiece(_plankCount, diff, laminateWidth,
        hasRightLock: false, rightBevel: plan.startBevel[0].complement);
    currentLength += firstlaminateLength;

    while (currentLength + laminateLength < rowLength) {
      currentLength += laminateLength;
      _plankCount++;
      addPlank(_plankCount, laminateLength, laminateWidth);
    }
    final tail = _tailPlanks(rowLength - currentLength, plan, 0);
    if (tail == null) return false;
    if (tail.length > 1) {
      _plankCount++;
      addPlank(_plankCount, tail.first, laminateWidth);
      addPiece(_plankCount, laminateLength - tail.first, laminateWidth, hasRightLock: false);
    }
    final lastlaminateLength = tail.last;
    _plankCount++;
    addPlank(_plankCount, lastlaminateLength, laminateWidth, rightBevel: plan.endBevel[0]);
    addPiece(_plankCount, laminateLength - lastlaminateLength, laminateWidth,
        hasLeftLock: false, leftBevel: plan.endBevel[0].complement);
    lines.add(Line(0, planks, startOffsetMm: plan.startU[0]));
    return true;
  }

  bool calculateRows(
    RowPlan plan, {
    required bool cutPieces,
    required bool optimizePieces,
  }) {
    for (int i = 1; i < plan.numberOfRows; i++) {
      final rowLength = plan.lengths[i];
      planks = [];
      if (plan.capWhole[i] >= rowLength) {
        _plankCount++;
        addPlank(_plankCount, rowLength, laminateWidth,
            leftBevel: plan.startBevel[i], rightBevel: plan.endBevel[i]);
        addPiece(_plankCount, laminateLength - rowLength, laminateWidth,
            hasRightLock: false, rightBevel: plan.startBevel[i].complement);
        lines.add(Line(i, planks, startOffsetMm: plan.startU[i]));
        continue;
      }
      var currentLength = 0;
      final prevJoint = _lastJoint;
      var index = -1;
      var minDiff = laminateLength;
      for (int p = 0; p < pieces.length; p++) {
        if (pieces[p].hasRightLock) {
          final loss = _reachLoss(plan, i, pieces[p].leftBevel, plan.startBevel[i]);
          if (loss == null) continue;
          if (!checkPiece(
              pieces[p].length, loss, plan, i, prevJoint, optimizePieces)) {
            continue;
          }
          final diff = _cut;
          if (diff == 0) {
            minDiff = 0;
            index = p;
            break;
          }
          if (diff < minDiff && cutPieces) {
            minDiff = diff;
            index = p;
          }
        }
      }
      if (index != -1) {
        if (cutPieces) {
          currentLength += pieces[index].length - minDiff;
          pieces[index].length -= minDiff;
          addPlank(pieces[index].number, pieces[index].length, laminateWidth,
              leftBevel: plan.startBevel[i]);
          if (minDiff > 0) {
            trash.add(Plank(pieces[index].number, minDiff, laminateWidth));
          }
          pieces.removeAt(index);
        } else {
          currentLength += pieces[index].length;
          addPlank(pieces[index].number, pieces[index].length, laminateWidth,
              leftBevel: plan.startBevel[i]);
          pieces.removeAt(index);
        }
      } else {
        if (!checkPiece(laminateLength, laminateLength - plan.capFirst[i], plan, i, prevJoint,
            optimizePieces)) {
          return false;
        }
        final firstlaminateLength = laminateLength - _cut;
        currentLength += firstlaminateLength;
        _plankCount++;
        addPlank(_plankCount, firstlaminateLength, laminateWidth, leftBevel: plan.startBevel[i]);
        addPiece(_plankCount, laminateLength - firstlaminateLength, laminateWidth,
            hasRightLock: false, rightBevel: plan.startBevel[i].complement);
      }
      // currentLength is still just the first plank, so this is its joint.
      final joint = plan.startU[i] + currentLength;
      if (prevJoint == null) _patternStartJoint = joint;
      _lastJoint = joint;

      while (currentLength + laminateLength < rowLength) {
        currentLength += laminateLength;
        _plankCount++;
        addPlank(_plankCount, laminateLength, laminateWidth);
      }

      final tail = _tailPlanks(rowLength - currentLength, plan, i);
      if (tail == null) return false;
      if (tail.length > 1) {
        currentLength += tail.first;
        _plankCount++;
        addPlank(_plankCount, tail.first, laminateWidth);
        addPiece(_plankCount, laminateLength - tail.first, laminateWidth, hasRightLock: false);
      }
      final lastlaminateLength = tail.last;
      index = -1;
      minDiff = laminateLength;
      for (int p = 0; p < pieces.length; p++) {
        if (pieces[p].hasLeftLock) {
          final loss = _reachLoss(plan, i, pieces[p].rightBevel, plan.endBevel[i]);
          if (loss == null) continue;
          if (pieces[p].length - loss >= lastlaminateLength) {
            if (pieces[p].length - lastlaminateLength < minDiff) {
              minDiff = pieces[p].length - lastlaminateLength;
              if (minDiff == 0) {
                index = p;
                break;
              } else if (cutPieces) {
                index = p;
              }
            }
          }
        }
      }

      if (index != -1) {
        if (cutPieces) {
          currentLength += pieces[index].length - minDiff;
          pieces[index].length -= minDiff;
          addPlank(pieces[index].number, pieces[index].length, laminateWidth,
              rightBevel: plan.endBevel[i]);
          if (minDiff > 0) {
            trash.add(Plank(pieces[index].number, minDiff, laminateWidth));
          }
          pieces.removeAt(index);
        } else {
          currentLength += pieces[index].length;
          addPlank(pieces[index].number, pieces[index].length, laminateWidth,
              rightBevel: plan.endBevel[i]);
          pieces.removeAt(index);
        }
      } else {
        _plankCount++;
        addPiece(_plankCount, laminateLength - lastlaminateLength, laminateWidth,
            hasLeftLock: false, leftBevel: plan.endBevel[i].complement);
        addPlank(_plankCount, lastlaminateLength, laminateWidth, rightBevel: plan.endBevel[i]);
      }

      lines.add(Line(i, planks, startOffsetMm: plan.startU[i]));
    }
    if (direction == Direction.diagonal) {
      // The far corner leaves a sliver of a row. Unlike straight laying it
      // cannot be evened out against the first row — that one is a sliver too,
      // in the near corner — so each row simply takes the width the plan gives.
      for (var i = 0; i < lines.length; i++) {
        for (final plank in lines[i].planks) {
          plank.width = plan.widths[i];
        }
      }
      return true;
    }
    // The dimension across the rows: room width when laying along the
    // length, room length when laying along the width.
    final acrossSize = direction == Direction.length ? roomWidth : roomLength;
    final actualWidth = acrossSize - indentFromWall * 2;
    var newWidth = laminateWidth - (laminateWidth * lines.length - actualWidth);
    if (newWidth >= 50) {
      for (final plank in lines.last.planks) {
        plank.width = newWidth;
      }
    } else {
      newWidth = ((newWidth + laminateWidth) ~/ 2);
      for (final plank in [...lines.first.planks, ...lines.last.planks]) {
        plank.width = newWidth;
      }
    }
    return true;
  }
}
