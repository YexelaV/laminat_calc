// What the drawing layer promises: the planks it puts on the floor are the
// planks the engine laid, they cover the floor and they stay inside the walls.
//
// The scheme used to be a widget tree measured by golden images and pinned by
// find.text. Now it is arithmetic, and arithmetic is worth checking directly —
// a golden can only say the picture changed, not which plank moved.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/scheme_geometry.dart';
import 'package:floor_calculator/utils/units.dart';

const roomLength = 3000;
const roomWidth = 1200;
const indent = 10;

Result laid(Direction direction, {int length = roomLength, int width = roomWidth}) {
  final results = Calculation(
    roomLength: length,
    roomWidth: width,
    laminateLength: 1200,
    laminateWidth: 190,
    planksInPack: 8,
    indentFromWall: indent,
    minimumLaminateLength: 300,
    rowOffset: 300,
    direction: direction,
  ).calculate();
  expect(results, isNotEmpty, reason: 'the fixture must be layable');
  return results.first;
}

Scheme schemeOf(Result result, {MeasurementSystem system = MeasurementSystem.metric}) =>
    buildScheme(result, system: system, minTextMm: 0);

/// Twice the signed area of a polygon, by the shoelace formula.
double twiceArea(List<Offset> points) {
  var sum = 0.0;
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    final q = points[(i + 1) % points.length];
    sum += p.dx * q.dy - q.dx * p.dy;
  }
  return sum;
}

void main() {
  group('the floor is covered', () {
    for (final direction in Direction.values) {
      test('$direction planks add up to the laid area', () {
        final scheme = schemeOf(laid(direction));
        final area = scheme.planks
            .map((s) => twiceArea(s.outline).abs() / 2)
            .fold<double>(0, (a, b) => a + b);
        final floor = (roomLength - 2 * indent) * (roomWidth - 2 * indent);
        // Rounding √2 to the millimetre costs a strip half a plank wide at
        // worst; a straight layout is exact.
        expect(area, closeTo(floor, direction == Direction.diagonal ? floor * 0.02 : 1));
      });

      // Against the room as drawn, not as entered: laying across the room turns
      // the drawing a quarter of a turn.
      test('$direction planks stay inside the walls', () {
        final scheme = schemeOf(laid(direction));
        for (final shape in scheme.planks) {
          for (final point in shape.outline) {
            expect(point.dx, inInclusiveRange(-0.5, scheme.room.width + 0.5),
                reason: 'plank ${shape.plank.number}');
            expect(point.dy, inInclusiveRange(-0.5, scheme.room.height + 0.5),
                reason: 'plank ${shape.plank.number}');
          }
        }
      });

      // Numbers repeat: an offcut carries the number of the plank it came off,
      // so what must match is the count, not the set.
      test('$direction draws every plank the engine laid', () {
        final result = laid(direction);
        final scheme = schemeOf(result);
        expect(scheme.planks.length,
            result.lines.fold<int>(0, (n, line) => n + line.planks.length));
      });
    }
  });

  group('45°', () {
    // The row plan measures a diagonal layout from one corner of the room and
    // the drawing has to put it back on the same corner. Nothing else pins the
    // two together: get the map wrong and the scheme is a plausible-looking
    // parallelogram sitting off the floor.
    test('the layout runs corner to corner', () {
      final scheme = schemeOf(laid(Direction.diagonal));
      final corners = <Offset>[];
      for (final shape in scheme.planks) {
        corners.addAll(shape.outline);
      }
      Offset nearest(Offset target) => corners
          .reduce((a, b) => (a - target).distance < (b - target).distance ? a : b);
      for (final corner in [
        const Offset(indent + 0.0, indent + 0.0),
        const Offset(roomLength - indent + 0.0, roomWidth - indent + 0.0),
      ]) {
        expect((nearest(corner) - corner).distance, lessThan(1),
            reason: 'no plank reaches $corner');
      }
    });

    // Rows run at 45° to the walls and their ends are cut at 45° to the rows,
    // which puts every end back square with a wall. So every edge of every
    // plank is either along a wall or across the room at 45° — an edge at any
    // other angle means the bevels and the rows disagree about which way round
    // the cut goes.
    test('every edge lies at a multiple of 45°', () {
      final scheme = schemeOf(laid(Direction.diagonal));
      for (final shape in scheme.planks) {
        for (var i = 0; i < shape.outline.length; i++) {
          final edge = shape.outline[(i + 1) % shape.outline.length] - shape.outline[i];
          if (edge.distance < 0.5) continue;
          final eighths = math.atan2(edge.dy, edge.dx) / (math.pi / 4);
          expect((eighths - eighths.roundToDouble()).abs(), lessThan(0.01),
              reason: 'plank ${shape.plank.number} has an edge at '
                  '${(eighths * 45).toStringAsFixed(1)}°');
        }
      }
    });

    test('the row against the starting corner is a triangle', () {
      final scheme = schemeOf(laid(Direction.diagonal));
      final corners = scheme.planks.first.outline
          .where((p) => scheme.planks.first.outline
              .every((q) => identical(p, q) || (p - q).distance > 0.5))
          .length;
      expect(corners, lessThanOrEqualTo(3));
    });
  });

  // The labels the golden images used to be paired with. A golden cannot tell
  // one string from another — the tester's font draws every glyph as the same
  // box — so the strings are pinned here and the images pin only the geometry.
  group('labels', () {
    List<String> textsOf(Scheme scheme) => scheme.labels.map((l) => l.text).toList();

    test('millimetres', () {
      final texts = textsOf(schemeOf(laid(Direction.length)));
      // 7 rows of 190 mm overshoot the 1180 mm across the rows, leaving 40 mm
      // for the last row. That is under the 50 mm floor, so the shortfall is
      // shared: the first and the last row both become 115 mm.
      expect(texts.where((t) => t == '115 ').length, 2);
      expect(texts.where((t) => t == '190 ').length, 5);
      expect(texts.where((t) => t == ' 581').length, 3, reason: 'the end plank of every third row');
      // A plank left at full length carries no length label.
      expect(texts, isNot(contains(' 1200')));
      expect(texts.where((t) => t == ' 1199').length, 3);
    });

    test('feet and inches', () {
      final texts = textsOf(schemeOf(laid(Direction.length), system: MeasurementSystem.imperial));
      expect(texts.where((t) => t == "4 1/2'' ").length, 2, reason: '115 mm row width');
      expect(texts.where((t) => t == "7 1/2'' ").length, 5, reason: '190 mm row width');
      expect(texts.where((t) => t == " 1'-10 7/8''").length, 3, reason: '581 mm end plank');
    });

    test('every laid plank is numbered', () {
      final result = laid(Direction.length);
      final texts = textsOf(schemeOf(result));
      for (final line in result.lines) {
        for (final plank in line.planks) {
          expect(texts, contains(' ${plank.number}'));
        }
      }
    });

    // The ladder: a plank with no room for its size keeps its number, and one
    // with no room for either is left blank rather than smudged.
    test('a text floor drops the size before the number, and then both', () {
      // A sliver of a plank: 40 mm of room to write in, across a full row.
      // It is the width of the plank, not of the row, that runs out first.
      final result = Result(
        1200,
        1400,
        400,
        8,
        1,
        [
          Line(0, [Plank(1, 40, 190)])
        ],
        [],
        [],
        direction: Direction.length,
        indentFromWall: 10,
      );
      List<String> at(double floor) =>
          buildScheme(result, system: MeasurementSystem.metric, minTextMm: floor)
              .planks
              .isEmpty
              ? const []
              : buildScheme(result, system: MeasurementSystem.metric, minTextMm: floor)
                  .labels
                  .where((l) => l.text.startsWith(' '))
                  .map((l) => l.text)
                  .toList();
      expect(at(0), [' 1', ' 40']);
      expect(at(20), [' 1'], reason: 'no room for the size, still room for the number');
      expect(at(40), isEmpty, reason: 'no room for either');
    });
  });

  test('the bounds hold everything drawn', () {
    for (final direction in Direction.values) {
      final scheme = schemeOf(laid(direction));
      expect(scheme.bounds.contains(scheme.room.topLeft), isTrue);
      expect(scheme.bounds.width, greaterThanOrEqualTo(scheme.room.width));
      for (final shape in scheme.planks) {
        for (final point in shape.outline) {
          expect(scheme.bounds.inflate(0.5).contains(point), isTrue, reason: '$direction');
        }
      }
    }
  });

  test('a room whose sides are equal has no plateau and still draws', () {
    final scheme = schemeOf(laid(Direction.diagonal, length: 3000, width: 3000));
    expect(scheme.planks, isNotEmpty);
    final area = scheme.planks
        .map((s) => twiceArea(s.outline).abs() / 2)
        .fold<double>(0, (a, b) => a + b);
    expect(area, closeTo(2980 * 2980, 2980 * 2980 * 0.02));
  });

  test('degenerate: a scheme of one whole plank still has bounds', () {
    final result = Result(
      1200,
      1400,
      400,
      8,
      1,
      [
        Line(0, [Plank(1, 1200, 190)])
      ],
      [],
      [],
      direction: Direction.length,
      indentFromWall: 10,
    );
    final scheme = schemeOf(result);
    expect(scheme.planks.length, 1);
    expect(scheme.bounds.width, greaterThan(0));
    expect(scheme.bounds.height, greaterThan(0));
  });

  test('the row width is written outside the floor, once per row', () {
    final result = laid(Direction.length);
    final scheme = schemeOf(result);
    final gutter = scheme.labels.where((l) => l.centre.dx < indent).toList();
    expect(gutter.length, result.lines.length);
    for (final label in gutter) {
      expect(label.bold, isFalse);
    }
  });

  // A plank is read along its length, so rows parallel to a wall are always
  // drawn left to right and their text is level. Only the 45° layout writes at
  // an angle.
  test('the rows are written along the direction they run in', () {
    expect(schemeOf(laid(Direction.length)).labels.first.angle, 0);
    expect(schemeOf(laid(Direction.width)).labels.first.angle, 0);
    expect(schemeOf(laid(Direction.diagonal)).labels.first.angle, closeTo(-math.pi / 4, 1e-9));
  });

  // Laying across the room turns the drawing: the room's width goes across the
  // page and its length down it, so the same floor comes out portrait rather
  // than landscape. The scheme screen reads this to decide which way up the
  // phone should be.
  test('laying across the room turns the drawing a quarter of a turn', () {
    final along = schemeOf(laid(Direction.length)).room;
    expect([along.width, along.height], [roomLength, roomWidth]);
    final across = schemeOf(laid(Direction.width)).room;
    expect([across.width, across.height], [roomWidth, roomLength]);
  });
}
