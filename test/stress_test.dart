// Stress test for the calculation algorithm: runs many configurations and
// checks result invariants.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/models.dart';

class Violation {
  final String config;
  final String message;
  Violation(this.config, this.message);
}

final violations = <Violation>[];

void checkResult(String cfg, Calculation c, Result r, int rowLength) {
  // 1. Every plank in the layout is not shorter than the minimum
  for (final line in r.lines) {
    for (final p in line.planks) {
      if (p.length < c.minimumLaminateLength) {
        violations.add(Violation(
            cfg, 'row ${line.number}: plank ${p.length} mm < min ${c.minimumLaminateLength} mm'));
      }
      if (p.length > c.laminateLength) {
        violations.add(Violation(cfg,
            'row ${line.number}: plank ${p.length} mm > laminate length ${c.laminateLength} mm'));
      }
      if (p.length <= 0) {
        violations.add(Violation(cfg, 'row ${line.number}: plank of length ${p.length} mm'));
      }
    }
  }
  // 2. Sum of plank lengths in a row == row length
  for (final line in r.lines) {
    final sum = line.planks.fold<int>(0, (s, p) => s + p.length);
    if (sum != rowLength) {
      violations.add(Violation(cfg, 'row ${line.number}: sum $sum mm != row length $rowLength mm'));
    }
  }
  // 3. Exact staircase offset between adjacent rows: one step down by
  // exactly rowOffset, or a pattern restart (jump up by a multiple of it)
  for (var i = 1; i < r.lines.length; i++) {
    final prev = r.lines[i - 1].planks.first.length;
    final cur = r.lines[i].planks.first.length;
    final prevFull = prev >= rowLength; // single-plank row
    final curFull = cur >= rowLength;
    if (prevFull || curFull) continue;
    final stepDown = prev - cur == c.rowOffset;
    final restart = cur > prev && (cur - prev) % c.rowOffset == 0;
    if (!stepDown && !restart) {
      violations.add(Violation(cfg,
          'rows ${i - 1}/$i: first planks $prev -> $cur mm do not follow exact offset ${c.rowOffset} mm'));
    }
  }
  // 4. Material balance: planks * length == laid + pieces + waste
  final used = r.lines.fold<int>(0, (s, l) => s + l.planks.fold<int>(0, (s2, p) => s2 + p.length));
  final leftPieces = r.pieces.fold<int>(0, (s, p) => s + p.length);
  final leftTrash = r.trash.fold<int>(0, (s, p) => s + p.length);
  final bought = r.totalPlanks * c.laminateLength;
  if (used + leftPieces + leftTrash != bought) {
    violations.add(Violation(cfg,
        'balance: laid $used + pieces $leftPieces + waste $leftTrash = ${used + leftPieces + leftTrash} != bought $bought (${r.totalPlanks} planks)'));
  }
}

void run(int roomLength, int roomWidth, int lamLength, int lamWidth, int pack, int indent,
    int minLen, int offset) {
  final cfg =
      'room=${roomLength}x${roomWidth}mm, laminate=${lamLength}x${lamWidth}mm, min=$minLen, offset=$offset, indent=$indent';
  final c = Calculation(
    roomLength: roomLength,
    roomWidth: roomWidth,
    laminateLength: lamLength,
    laminateWidth: lamWidth,
    planksInPack: pack,
    indentFromWall: indent,
    minimumLaminateLength: minLen,
    rowOffset: offset,
    direction: Direction.length,
  );
  final rowLength = c.rowLength;
  final rows = numberOfRowsMm(
    roomLength: roomLength,
    roomWidth: roomWidth,
    indentFromWall: indent,
    laminateWidth: lamWidth,
    direction: Direction.length,
  );
  final feasible = exactOffsetFeasible(rowLength, lamLength, offset, minLen, rows);
  try {
    final results = c.calculate();
    if (results.isEmpty) {
      if (feasible) {
        violations.add(Violation(cfg, 'empty result but bound says feasible'));
      }
      return;
    }
    if (!feasible) {
      violations.add(Violation(cfg, 'result found but bound says infeasible'));
    }
    for (final r in results) {
      checkResult(cfg, c, r, rowLength);
    }
  } catch (e) {
    violations.add(Violation(cfg, 'CRASH: $e'));
  }
}

String report() {
  final byType = <String, List<Violation>>{};
  for (final v in violations) {
    final key = v.message.split(':').first.replaceAll(RegExp(r'\d+'), 'N');
    byType.putIfAbsent(key, () => []).add(v);
  }
  final out = StringBuffer('${violations.length} violations');
  byType.forEach((type, list) {
    out.writeln('\n=== $type — ${list.length} pcs. Examples:');
    for (final v in list.take(3)) {
      out.writeln('  [${v.config}]');
      out.writeln('    ${v.message}');
    }
  });
  return out.toString();
}

void main() {
  setUp(violations.clear);

  test('typical configurations hold the layout invariants', () {
    run(5000, 4000, 1380, 190, 8, 10, 300, 300);
    run(4100, 3200, 1380, 190, 8, 10, 300, 300);
    run(3000, 2500, 1285, 192, 8, 10, 300, 300);
    run(6000, 4500, 1380, 190, 8, 10, 400, 300);
    run(2800, 2000, 1380, 190, 8, 10, 300, 300);
    expect(violations, isEmpty, reason: report());
  });

  test('random configurations hold the layout invariants', () {
    final rnd = Random(42);
    // Offsets mix the fraction presets (1/2, 1/3, 1/4 of the plank length)
    // with free values like the exact mode allows.
    for (var i = 0; i < 3000; i++) {
      final roomLength = rnd.nextInt(22001) + 2000; // 2000 - 24000 mm
      final roomWidth = rnd.nextInt(14001) + 2000; // 2000 - 16000 mm
      final lamLength = 600 + rnd.nextInt(25) * 50; // 600 - 1800
      final lamWidth = 100 + rnd.nextInt(10) * 15;
      final minLen = 200 + rnd.nextInt(5) * 50; // 200 - 400
      final int offset;
      switch (rnd.nextInt(4)) {
        case 0:
          offset = (lamLength / 2).round();
          break;
        case 1:
          offset = (lamLength / 3).round();
          break;
        case 2:
          offset = (lamLength / 4).round();
          break;
        default:
          offset = 200 + rnd.nextInt(5) * 50; // 200 - 400
      }
      final indent = rnd.nextInt(3) * 5; // 0/5/10
      run(roomLength, roomWidth, lamLength, lamWidth, 8, indent, minLen, offset);
    }
    expect(violations, isEmpty, reason: report());
  });
}
