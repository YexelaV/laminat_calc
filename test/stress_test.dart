// Stress test for the calculation algorithm: runs many configurations and
// checks result invariants. Run: dart test/stress_test.dart
import 'dart:math';

import '../lib/calculate.dart';
import '../lib/models.dart';

class Violation {
  final String config;
  final String message;
  Violation(this.config, this.message);
}

void main() {
  final rnd = Random(42);
  final violations = <Violation>[];
  var crashes = 0;
  var runs = 0;

  void checkResult(String cfg, Calculation c, Result r, int rowLength) {
    // 1. Every plank in the layout is not shorter than the minimum
    for (final line in r.lines) {
      for (final p in line.planks) {
        if (p.length < c.minimumLaminateLength) {
          violations.add(Violation(cfg,
              'row ${line.number}: plank ${p.length} mm < min ${c.minimumLaminateLength} mm'));
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
        violations.add(Violation(
            cfg, 'row ${line.number}: sum ${sum} mm != row length ${rowLength} mm'));
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
            'rows ${i - 1}/${i}: first planks $prev -> $cur mm do not follow exact offset ${c.rowOffset} mm'));
      }
    }
    // 4. Material balance: planks * length == laid + pieces + waste
    final used = r.lines.fold<int>(
        0, (s, l) => s + l.planks.fold<int>(0, (s2, p) => s2 + p.length));
    final leftPieces = r.pieces.fold<int>(0, (s, p) => s + p.length);
    final leftTrash = r.trash.fold<int>(0, (s, p) => s + p.length);
    final bought = r.totalPlanks * c.laminateLength;
    if (used + leftPieces + leftTrash != bought) {
      violations.add(Violation(cfg,
          'balance: laid $used + pieces $leftPieces + waste $leftTrash = ${used + leftPieces + leftTrash} != bought $bought (${r.totalPlanks} planks)'));
    }
  }

  void run(double roomLength, double roomWidth, int lamLength, int lamWidth,
      int pack, int indent, int minLen, int offset) {
    runs++;
    final cfg =
        'room=${roomLength}x${roomWidth}m, laminate=${lamLength}x${lamWidth}mm, min=$minLen, offset=$offset, indent=$indent';
    final c = Calculation(
      roomLength: roomLength,
      roomWidth: roomWidth,
      laminateLength: lamLength,
      laminateWidth: lamWidth,
      planksInPack: pack,
      price: 0,
      indentFromWall: indent,
      minimumLaminateLength: minLen,
      rowOffset: offset,
      direction: Direction.length,
    );
    final rowLength = (roomLength * 1000 - indent * 2).toInt();
    final rows = ((roomWidth * 1000 - indent * 2) / lamWidth).ceil();
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
      crashes++;
      violations.add(Violation(cfg, 'CRASH: $e'));
    }
  }

  // Typical manual cases
  run(5.0, 4.0, 1380, 190, 8, 10, 300, 300);
  run(4.1, 3.2, 1380, 190, 8, 10, 300, 300);
  run(3.0, 2.5, 1285, 192, 8, 10, 300, 300);
  run(6.0, 4.5, 1380, 190, 8, 10, 400, 300);
  run(2.8, 2.0, 1380, 190, 8, 10, 300, 300);

  // Random configurations; offsets mix the fraction presets (1/2, 1/3, 1/4
  // of the plank length) with free values like the exact mode allows
  for (var i = 0; i < 3000; i++) {
    final roomLength = (rnd.nextInt(220) + 20) / 10.0; // 2.0 - 24.0 m
    final roomWidth = (rnd.nextInt(140) + 20) / 10.0; // 2.0 - 16.0 m
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

  print('Runs: $runs, crashes: $crashes, violations: ${violations.length}');
  final byType = <String, List<Violation>>{};
  for (final v in violations) {
    final key = v.message.split(':').first.replaceAll(RegExp(r'\d+'), 'N');
    byType.putIfAbsent(key, () => []).add(v);
  }
  byType.forEach((type, list) {
    print('\n=== $type — ${list.length} pcs. Examples:');
    for (final v in list.take(3)) {
      print('  [${v.config}]');
      print('    ${v.message}');
    }
  });
}
