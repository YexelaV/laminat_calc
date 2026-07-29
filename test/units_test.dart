// The imperial side of the app is a round trip: the form parses what the user
// typed and picked, the calculation stores millimetres, and the scheme, the cut
// list and the PDF format those millimetres back. These tests pin both ends and
// the fact that the pair agrees.
import 'package:flutter_test/flutter_test.dart';

import 'package:floor_calculator/constants.dart';
import 'package:floor_calculator/utils/units.dart';

void main() {
  group('fractions', () {
    test('sixteenths are reduced the way a tape measure names them', () {
      expect([
        for (var n = 1; n < INCH_DENOMINATOR; n++) fractionLabel(n)
      ], [
        '1/16', '1/8', '3/16', '1/4', '5/16', '3/8', '7/16', //
        '1/2', '9/16', '5/8', '11/16', '3/4', '13/16', '7/8', '15/16',
      ]);
    });

    test('a whole number carries no fraction', () {
      expect(formatInches(12), '12');
      expect(formatInches(0), '0');
    });

    test('a value below an inch is just the fraction', () {
      expect(formatInches(0.4375), '7/16');
    });

    test('anything between marks snaps to the nearest one', () {
      expect(formatInches(190 / MM_PER_INCH), '7 1/2', reason: '190mm is 7.480 inches');
      expect(formatInches(47.9), '47 7/8', reason: 'nearer to 47.875 than to 47.9375');
    });
  });

  group('parsing', () {
    test('accepts every shape the form can produce', () {
      expect(parseInches('47'), 47);
      expect(parseInches('47 7/8'), 47.875);
      expect(parseInches('7/8'), 0.875);
      expect(parseInches('  47   7/8 '), 47.875);
    });

    test('still accepts the decimals the app used to write', () {
      expect(parseInches('47.5'), 47.5);
      expect(parseInches('47,5'), 47.5);
    });

    test('rejects what it cannot read', () {
      for (final value in ['', 'abc', '1 2 3', '7/', '/8', '1/0', '1/2/3']) {
        expect(parseInches(value), isNull, reason: value);
      }
    });

    test('round trips every mark of an inch', () {
      for (var n = 0; n < INCH_DENOMINATOR * 4; n++) {
        final inches = n / INCH_DENOMINATOR;
        expect(parseInches(formatInches(inches)), inches);
      }
    });
  });

  group('feet and inches', () {
    test('formats the sizes the scheme labels', () {
      expect(formatFeetInches(190), "7 1/2''");
      expect(formatFeetInches(115), "4 1/2''");
      expect(formatFeetInches(581), "1'-10 7/8''");
      expect(formatFeetInches(1200), "3'-11 1/4''");
    });

    test('keeps the whole-inch zero so feet cannot be misread', () {
      // 319mm is 1 foot and 9/16'', not 1 foot 9 inches.
      expect(formatFeetInches(319), "1'-0 9/16''");
    });

    test('an inch part that rounds up to twelve becomes a foot', () {
      // 11.9993'' rounds to 12/12 of a foot, not to 0'-12''.
      expect(formatFeetInches(inchToMm(11.9993)), "1'-0''");
    });
  });

  group('bounds', () {
    test('stay inside the millimetre range they came from', () {
      for (final mm in [MIN_PLANK_LENGTH, MIN_PLANK_WIDTH, MIN_ROW_OFFSET, MIN_MIN_LENGTH]) {
        expect(inchToMm(ceilInch(mm)), greaterThanOrEqualTo(mm), reason: '$mm');
      }
      for (final mm in [MAX_PLANK_LENGTH, MAX_PLANK_WIDTH, MAX_INDENT_FROM_WALL]) {
        expect(inchToMm(floorInch(mm)), lessThanOrEqualTo(mm), reason: '$mm');
      }
    });

    test('are shown as fractions, not decimals', () {
      expect(formatInches(ceilInch(MIN_PLANK_LENGTH)), '11 13/16');
      expect(formatInches(floorInch(MAX_PLANK_LENGTH)), '118 1/16');
    });

    test('the largest inch part of a foot is a sixteenth short of twelve', () {
      expect(MAX_INCHES_IN_FOOT, 12 - 1 / INCH_DENOMINATOR);
      expect(formatInches(MAX_INCHES_IN_FOOT), '11 15/16');
    });
  });
}
