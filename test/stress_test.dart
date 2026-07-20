// Стресс-тест алгоритма расчёта: прогоняет много конфигураций и проверяет
// инварианты результата. Запуск: dart test/stress_test.dart
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
    // 1. Каждая планка в схеме не короче минимальной
    for (final line in r.lines) {
      for (final p in line.planks) {
        if (p.length < c.minimumLaminateLength) {
          violations.add(Violation(cfg,
              'ряд ${line.number}: планка ${p.length} мм < мин ${c.minimumLaminateLength} мм'));
        }
        if (p.length > c.laminateLength) {
          violations.add(Violation(cfg,
              'ряд ${line.number}: планка ${p.length} мм > длины ламината ${c.laminateLength} мм'));
        }
        if (p.length <= 0) {
          violations.add(Violation(cfg, 'ряд ${line.number}: планка длиной ${p.length} мм'));
        }
      }
    }
    // 2. Сумма длин планок в ряду == длине ряда
    for (final line in r.lines) {
      final sum = line.planks.fold<int>(0, (s, p) => s + p.length);
      if (sum != rowLength) {
        violations.add(Violation(
            cfg, 'ряд ${line.number}: сумма ${sum} мм != длина ряда ${rowLength} мм'));
      }
    }
    // 3. Смещение швов между соседними рядами
    for (var i = 1; i < r.lines.length; i++) {
      final prev = r.lines[i - 1].planks.first.length;
      final cur = r.lines[i].planks.first.length;
      final prevFull = prev >= rowLength; // ряд из одной планки
      final curFull = cur >= rowLength;
      if (prevFull || curFull) continue;
      if ((prev - cur).abs() < c.rowOffset) {
        violations.add(Violation(cfg,
            'ряды ${i - 1}/${i}: смещение швов ${(prev - cur).abs()} мм < ${c.rowOffset} мм'));
      }
    }
    // 4. Баланс материала: планки * длина == уложено + куски + отходы
    final used = r.lines.fold<int>(
        0, (s, l) => s + l.planks.fold<int>(0, (s2, p) => s2 + p.length));
    final leftPieces = r.pieces.fold<int>(0, (s, p) => s + p.length);
    final leftTrash = r.trash.fold<int>(0, (s, p) => s + p.length);
    final bought = r.totalPlanks * c.laminateLength;
    if (used + leftPieces + leftTrash != bought) {
      violations.add(Violation(cfg,
          'баланс: уложено $used + куски $leftPieces + отходы $leftTrash = ${used + leftPieces + leftTrash} != куплено $bought (${r.totalPlanks} планок)'));
    }
  }

  void run(double roomLength, double roomWidth, int lamLength, int lamWidth,
      int pack, int indent, int minLen, int offset) {
    runs++;
    final cfg =
        'room=${roomLength}x${roomWidth}м, ламинат=${lamLength}x${lamWidth}мм, мин=$minLen, смещение=$offset, отступ=$indent';
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
    try {
      final results = c.calculate();
      if (results.isEmpty) {
        violations.add(Violation(cfg, 'пустой результат'));
        return;
      }
      for (final r in results) {
        checkResult(cfg, c, r, rowLength);
      }
    } catch (e) {
      crashes++;
      violations.add(Violation(cfg, 'КРАШ: $e'));
    }
  }

  // Типовые ручные случаи
  run(5.0, 4.0, 1380, 190, 8, 10, 300, 300);
  run(4.1, 3.2, 1380, 190, 8, 10, 300, 300);
  run(3.0, 2.5, 1285, 192, 8, 10, 300, 300);
  run(6.0, 4.5, 1380, 190, 8, 10, 400, 300);
  run(2.8, 2.0, 1380, 190, 8, 10, 300, 300);

  // Случайные конфигурации
  for (var i = 0; i < 3000; i++) {
    final roomLength = (rnd.nextInt(220) + 20) / 10.0; // 2.0 - 24.0 м
    final roomWidth = (rnd.nextInt(140) + 20) / 10.0; // 2.0 - 16.0 м
    final lamLength = 600 + rnd.nextInt(25) * 50; // 600 - 1800
    final lamWidth = 100 + rnd.nextInt(10) * 15;
    final minLen = 200 + rnd.nextInt(5) * 50; // 200 - 400
    final offset = 200 + rnd.nextInt(5) * 50; // 200 - 400
    final indent = rnd.nextInt(3) * 5; // 0/5/10
    run(roomLength, roomWidth, lamLength, lamWidth, 8, indent, minLen, offset);
  }

  print('Прогонов: $runs, крашей: $crashes, нарушений: ${violations.length}');
  final byType = <String, List<Violation>>{};
  for (final v in violations) {
    final key = v.message.split(':').first.replaceAll(RegExp(r'\d+'), 'N');
    byType.putIfAbsent(key, () => []).add(v);
  }
  byType.forEach((type, list) {
    print('\n=== $type — ${list.length} шт. Примеры:');
    for (final v in list.take(3)) {
      print('  [${v.config}]');
      print('    ${v.message}');
    }
  });
}
