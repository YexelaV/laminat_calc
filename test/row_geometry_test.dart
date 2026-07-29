// Pins the row geometry that the field validators in
// laying_parameters_screen.dart derive against the geometry
// Calculation.calculate() actually lays out. Feasibility is not monotone in the
// minimum plank length, so a 1 mm disagreement between the two flips it and the
// user gets a green form that then reports no laying variants.
import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/calculate.dart';
import 'package:floor_calculator/cubit/calculate_state.dart';
import 'package:floor_calculator/models.dart';

Calculation calculationFor({
  required int roomLength,
  required int roomWidth,
  required int indentFromWall,
  int laminateLength = 1380,
  int laminateWidth = 190,
  int rowOffset = 120,
  int minimumLaminateLength = 490,
}) =>
    Calculation(
      roomLength: roomLength,
      roomWidth: roomWidth,
      laminateLength: laminateLength,
      laminateWidth: laminateWidth,
      planksInPack: 8,
      indentFromWall: indentFromWall,
      minimumLaminateLength: minimumLaminateLength,
      rowOffset: rowOffset,
      direction: Direction.length,
    );

void main() {
  group('row geometry', () {
    // Room sizes used to be stored as double metres, and converting them back
    // to millimetres lost 1 mm on 175 of the accepted sizes.
    test('the size the user typed reaches the geometry unchanged', () {
      for (var mm = 2000; mm <= 24000; mm++) {
        for (final indent in [0, 5, 10]) {
          final state = CalculateState(roomLength: mm, roomWidth: 3000, indentFromWall: indent);
          expect(
            rowLengthMm(
              roomLength: state.roomLength!,
              roomWidth: state.roomWidth!,
              indentFromWall: indent,
              direction: Direction.length,
            ),
            mm - indent * 2,
            reason: 'room length $mm mm, indent $indent mm',
          );
        }
      }
    });

    test('the calculation lays out the geometry the validators derive', () {
      for (var mm = 2000; mm <= 24000; mm += 1) {
        for (final indent in [0, 10]) {
          final calculation =
              calculationFor(roomLength: mm, roomWidth: 3000, indentFromWall: indent);
          expect(
            calculation.rowLength,
            rowLengthMm(
              roomLength: mm,
              roomWidth: 3000,
              indentFromWall: indent,
              direction: Direction.length,
            ),
            reason: 'room length $mm mm, indent $indent mm',
          );
        }
      }
    });

    test('the calculation lays out the row count the validators derive', () {
      for (var mm = 2000; mm <= 16000; mm++) {
        for (final width in [190, 192, 1000]) {
          final calculation = calculationFor(
              roomLength: 5000, roomWidth: mm, indentFromWall: 10, laminateWidth: width);
          calculation.calculate();
          expect(
            calculation.numberOfRows,
            numberOfRowsMm(
              roomLength: 5000,
              roomWidth: mm,
              indentFromWall: 10,
              laminateWidth: width,
              direction: Direction.length,
            ),
            reason: 'room width $mm mm, plank width $width mm',
          );
        }
      }
    });

    // 2010 mm used to truncate to a row length of 1989 mm for the validators
    // but round to 1990 mm for the calculation, and this configuration is
    // layable at exactly one of the two.
    test('a configuration the minimum length field accepts is actually layable', () {
      const roomLength = 2010;
      const roomWidth = 3000;
      const indentFromWall = 10;
      const laminateLength = 1380;
      const laminateWidth = 190;
      const rowOffset = 120;
      const minimumLaminateLength = 490;

      final accepted = exactOffsetFeasible(
        rowLengthMm(
          roomLength: roomLength,
          roomWidth: roomWidth,
          indentFromWall: indentFromWall,
          direction: Direction.length,
        ),
        laminateLength,
        rowOffset,
        minimumLaminateLength,
        numberOfRowsMm(
          roomLength: roomLength,
          roomWidth: roomWidth,
          indentFromWall: indentFromWall,
          laminateWidth: laminateWidth,
          direction: Direction.length,
        ),
      );

      final results = calculationFor(
        roomLength: roomLength,
        roomWidth: roomWidth,
        indentFromWall: indentFromWall,
      ).calculate();

      expect(results.isNotEmpty, accepted,
          reason: 'the field validator and the calculation must agree on feasibility');
    });
  });
}
