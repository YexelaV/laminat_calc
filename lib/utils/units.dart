enum MeasurementSystem { metric, imperial }

const double MM_PER_INCH = 25.4;
const double M_PER_FOOT = 0.3048;

int inchToMm(double inch) => (inch * MM_PER_INCH).round();

int feetInchesToMm(double feet, double inches) => inchToMm(feet * 12 + inches);

int maxWholeFeet(int mm) => (mm / 1000 / M_PER_FOOT).floor();

// Bounds converted to inches so that any accepted inch value maps back into
// the original mm bounds: round the minimum up and the maximum down to 0.1".
double ceilInch(num mm) => (mm / MM_PER_INCH * 10).ceil() / 10;

double floorInch(num mm) => (mm / MM_PER_INCH * 10).floor() / 10;

String formatSize(num mm, MeasurementSystem system) =>
    system == MeasurementSystem.imperial ? (mm / MM_PER_INCH).toStringAsFixed(1) : '$mm';

// 6300mm -> 20'-8'', 190mm -> 7.5''
String formatFeetInches(num mm) {
  final totalInches = mm / MM_PER_INCH;
  var feet = totalInches ~/ 12;
  // Round the inch part to 0.1'' and carry over when it rounds up to 12.
  var inches = ((totalInches - feet * 12) * 10).round() / 10;
  if (inches >= 12) {
    feet++;
    inches = 0;
  }
  final inchText = inches == inches.truncate() ? '${inches.truncate()}' : '$inches';
  if (feet == 0) return "$inchText''";
  return "$feet'-$inchText''";
}
