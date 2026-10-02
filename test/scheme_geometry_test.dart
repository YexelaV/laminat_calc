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
import 'package:floor_calculator/room_shape.dart';
import 'package:floor_calculator/scheme_geometry.dart';
import 'package:floor_calculator/utils/units.dart';

const roomLength = 3000;
const roomWidth = 1200;
const indent = 10;

/// How far inside one wall a point is: the wall runs through [corner] with
/// [inward] pointing into the room, and the result is negative outside it.
double _depthOf(Offset point, Offset corner, Offset inward) =>
    (point.dx - corner.dx) * inward.dx + (point.dy - corner.dy) * inward.dy;

/// How far inside [polygon] a point is, in millimetres; negative when it is
/// out. A polygon rather than a bounding box, because a room whose opposite
/// walls differ has planks that a box would let stray past a wall unnoticed —
/// and a polygon measured against its walls rather than against their lines,
/// because the line of a wall that stops at an inside corner carries on
/// through the other arm of the room and would report the planks there as
/// being nowhere near the floor.
double _depthInside(Offset point, List<Offset> polygon) =>
    LaidFloor(polygon).insideDepth(point);

// A room measured wall by wall, with all four walls different, so that a label
// can be told from the wall it belongs to.
Result laidSkewed(Direction direction) {
  final results = Calculation(
    shape: RoomShape(
      lengthNear: 3000,
      lengthFar: 2880,
      widthLeft: 1200,
      widthRight: 1320,
      diagonal: 3300,
    ),
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

Result laid(Direction direction, {int length = roomLength, int width = roomWidth}) {
  final results = Calculation(
    shape: RoomShape.rectangle(length, width),
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
            expect(_depthInside(point, scheme.room), greaterThanOrEqualTo(-0.5),
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

    // The only thing on the drawing that says how big the room is. It matters
    // most where it shows least: a room fifteen millimetres out of square is a
    // pixel or two of slant, so the walls have to be read, not looked at.
    test('every wall carries its own measurement, written outside it', () {
      for (final direction in Direction.values) {
        final scheme = schemeOf(laidSkewed(direction));
        final normals = normalsOf(scheme.room);
        // The corners run near length, right width, far length, left width.
        const measured = [3000, 1320, 2880, 1200];
        for (var i = 0; i < measured.length; i++) {
          final matching =
              scheme.labels.where((l) => l.text == '${measured[i]}').toList();
          expect(matching, hasLength(1), reason: '$direction, wall $i');
          final depth = _depthOf(matching.single.centre, scheme.room[i], normals[i]);
          expect(depth, lessThan(0),
              reason: '$direction, wall $i: its measurement is inside the room');
          // Past the row widths written against the same wall, not on top of
          // them. A row width is the one label written with a trailing space.
          for (final other in scheme.labels.where((l) => l.text.endsWith(' '))) {
            final otherDepth = _depthOf(other.centre, scheme.room[i], normals[i]);
            if (otherDepth >= 0) continue;
            expect(depth, lessThan(otherDepth),
                reason: '$direction, wall $i: the row width "${other.text}" '
                    'is written further out than the wall itself');
          }
        }
      }
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
        RoomShape.rectangle(1400, 400),
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
      final room = boundsOf(scheme.room);
      expect(scheme.bounds.contains(room.topLeft), isTrue);
      expect(scheme.bounds.width, greaterThanOrEqualTo(room.width));
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
      RoomShape.rectangle(1400, 400),
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
    // One per row, and beyond them the wall's own length.
    expect(gutter.length, result.lines.length + 1);
    expect(gutter.where((l) => l.text == '$roomWidth').length, 1,
        reason: 'the wall the rows start against carries its own measurement');
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
  // than landscape.
  test('laying across the room turns the drawing a quarter of a turn', () {
    final along = schemeOf(laid(Direction.length)).room;
    final across = schemeOf(laid(Direction.width)).room;
    expect([boundsOf(along).width, boundsOf(along).height], [roomLength, roomWidth]);
    expect([boundsOf(across).width, boundsOf(across).height], [roomWidth, roomLength]);

    // And a turn, not a mirror. Transposing `(x, y) → (y, x)` stands the room
    // on its side too and passes every check above — a reflection keeps the
    // bounding box — but it prints the room back to front, so a wall's own
    // measurement would be written along the wall opposite it. What tells the
    // two apart is which way the corners run: a turn keeps the winding, a
    // reflection reverses it.
    expect(twiceArea(across).sign, twiceArea(along).sign,
        reason: 'the corners run the other way round, so the room is mirrored');
  });

  group('a room with a corner cut away', () {
    // 4000 by 3000 with 1500 by 1000 out of the far right corner. Big enough
    // that rows run above the cut, below it and across it.
    const cutLength = 1500;
    const cutWidth = 1000;

    Result laidCut(Direction direction, {RoomCorner corner = RoomCorner.farRight}) {
      final results = Calculation(
        shape: LRoomShape(
          length: 4000,
          width: 3000,
          notchLength: cutLength,
          notchWidth: cutWidth,
          corner: corner,
        ),
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

    test('a plank beside the cut is cut to the cut, not to its line', () {
      // The failure this replaces: Sutherland–Hodgman against every wall's
      // line leaves only the little rectangle where the two arms of the room
      // overlap, so a plank standing in either arm came back empty.
      final floor = LaidFloor([
        const Offset(10, 10),
        const Offset(3990, 10),
        const Offset(3990, 1990),
        const Offset(2490, 1990),
        const Offset(2490, 2990),
        const Offset(10, 2990),
      ]);
      expect(floor.isConvex, isFalse);

      List<Offset> clipRect(double x0, double y0, double x1, double y1) => clipToFloor(
          [Offset(x0, y0), Offset(x1, y0), Offset(x1, y1), Offset(x0, y1)], floor);

      // Wholly in the long arm, below the step: untouched.
      expect(clipRect(2600, 100, 3800, 290), [
        const Offset(2600, 100),
        const Offset(3800, 100),
        const Offset(3800, 290),
        const Offset(2600, 290),
      ]);
      // Wholly in the short arm, past the step: untouched.
      expect(clipRect(100, 2100, 1300, 2290), [
        const Offset(100, 2100),
        const Offset(1300, 2100),
        const Offset(1300, 2290),
        const Offset(100, 2290),
      ]);
      // Across the step: an L of its own, with the inside corner put back.
      expect(clipRect(1800, 1900, 3000, 2090), [
        const Offset(1800, 1900),
        const Offset(3000, 1900),
        const Offset(3000, 1990),
        const Offset(2490, 1990),
        const Offset(2490, 2090),
        const Offset(1800, 2090),
      ]);
      // Wholly inside the cut: nothing left.
      expect(clipRect(2700, 2100, 3500, 2290), isEmpty);
    });

    for (final direction in [Direction.length, Direction.width]) {
      test('$direction planks add up to the laid area', () {
        final scheme = schemeOf(laidCut(direction));
        final area = scheme.planks
            .map((s) => twiceArea(s.outline).abs() / 2)
            .fold<double>(0, (a, b) => a + b);
        final floor = (4000 - 2 * indent) * (3000 - 2 * indent) - cutLength * cutWidth;
        expect(area, closeTo(floor, 1));
      });

      test('$direction planks stay inside the walls', () {
        final scheme = schemeOf(laidCut(direction));
        for (final shape in scheme.planks) {
          for (final point in shape.outline) {
            expect(_depthInside(point, scheme.room), greaterThanOrEqualTo(-0.5),
                reason: 'plank ${shape.plank.number}');
          }
        }
      });

      test('$direction draws every plank as one piece, six-sided at most', () {
        final scheme = schemeOf(laidCut(direction));
        final result = laidCut(direction);
        expect(scheme.planks.length,
            result.lines.fold<int>(0, (n, line) => n + line.planks.length));
        for (final shape in scheme.planks) {
          expect(shape.outline.length, inInclusiveRange(3, 6),
              reason: 'plank ${shape.plank.number}');
          // Every wall of this room is square to the rows, so every edge of
          // every plank is too.
          for (var i = 0; i < shape.outline.length; i++) {
            final from = shape.outline[i];
            final to = shape.outline[(i + 1) % shape.outline.length];
            expect(
                (from.dx - to.dx).abs() < 1e-6 || (from.dy - to.dy).abs() < 1e-6, isTrue,
                reason: 'plank ${shape.plank.number} edge $i');
          }
        }
      });

      test('$direction writes all six wall measurements, each outside its wall', () {
        final result = laidCut(direction);
        final scheme = schemeOf(result);
        final measured = LRoomShape(
          length: 4000,
          width: 3000,
          notchLength: cutLength,
          notchWidth: cutWidth,
          corner: RoomCorner.farRight,
        ).wallLengths();
        expect(scheme.room.length, 6);
        for (final wall in measured) {
          expect(scheme.labels.where((l) => l.text == '$wall').length, greaterThanOrEqualTo(1),
              reason: 'the $wall mm wall carries its own measurement');
        }
        // And none of them is written on the floor.
        final floor = LaidFloor(drawnFloor(result));
        for (final wall in measured.toSet()) {
          for (final label in scheme.labels.where((l) => l.text == '$wall')) {
            expect(floor.insideDepth(label.centre), lessThan(1),
                reason: 'the $wall mm measurement is written on the floor');
          }
        }
      });

      test('$direction writes one row width per row, outside the floor', () {
        // The regression test for the inside corner. Read off a wall's line
        // rather than the wall itself, every row above the step would have
        // its width written into the middle of the room.
        final result = laidCut(direction);
        final scheme = schemeOf(result);
        final floor = LaidFloor(drawnFloor(result));
        final widths = result.lines.map((l) => '${l.planks.first.width} ').toSet();
        var written = 0;
        for (final label in scheme.labels.where((l) => widths.contains(l.text))) {
          written++;
          expect(floor.insideDepth(label.centre), lessThan(1),
              reason: 'the row width "${label.text}" is written on the floor');
        }
        expect(written, greaterThanOrEqualTo(result.lines.length));
      });
    }

    test('every corner can be the one cut away', () {
      for (final corner in RoomCorner.values) {
        for (final direction in [Direction.length, Direction.width]) {
          final scheme = schemeOf(laidCut(direction, corner: corner));
          final area = scheme.planks
              .map((s) => twiceArea(s.outline).abs() / 2)
              .fold<double>(0, (a, b) => a + b);
          final floor = (4000 - 2 * indent) * (3000 - 2 * indent) - cutLength * cutWidth;
          expect(area, closeTo(floor, 1), reason: '$corner $direction');
          for (final shape in scheme.planks) {
            for (final point in shape.outline) {
              expect(_depthInside(point, scheme.room), greaterThanOrEqualTo(-0.5),
                  reason: '$corner $direction: plank ${shape.plank.number}');
            }
          }
        }
      }
    });

    test('a 45° layout in such a room yields nothing rather than nonsense', () {
      final results = Calculation(
        shape: LRoomShape(
          length: 4000,
          width: 3000,
          notchLength: cutLength,
          notchWidth: cutWidth,
          corner: RoomCorner.farRight,
        ),
        laminateLength: 1200,
        laminateWidth: 190,
        planksInPack: 8,
        indentFromWall: indent,
        minimumLaminateLength: 300,
        rowOffset: 300,
        direction: Direction.diagonal,
      ).calculate();
      expect(results, isEmpty);
    });
  });
}
