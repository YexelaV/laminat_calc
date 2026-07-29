enum MeasurementSystem { metric, imperial }

const double MM_PER_INCH = 25.4;
const double M_PER_FOOT = 0.3048;

// Installers read a tape measure in sixteenths, so every imperial value the app
// shows or accepts is snapped to that grid. Fractions stay ASCII: the PDF font
// is latin-1 only and throws on '½'.
const int INCH_DENOMINATOR = 16;

int inchToMm(double inch) => (inch * MM_PER_INCH).round();

int feetInchesToMm(double feet, double inches) => inchToMm(feet * 12 + inches);

int maxWholeFeet(int mm) => (mm / 1000 / M_PER_FOOT).floor();

// Bounds converted to inches so that any accepted inch value maps back into
// the original mm bounds: round the minimum up and the maximum down to 1/16''.
double ceilInch(num mm) => (mm / MM_PER_INCH * INCH_DENOMINATOR).ceil() / INCH_DENOMINATOR;

double floorInch(num mm) => (mm / MM_PER_INCH * INCH_DENOMINATOR).floor() / INCH_DENOMINATOR;

// 8 -> '1/2', 6 -> '3/8'. Reduced, because that is how the marks are named.
String fractionLabel(int sixteenths) {
  var numerator = sixteenths;
  var denominator = INCH_DENOMINATOR;
  while (numerator.isEven && numerator != 0) {
    numerator ~/= 2;
    denominator ~/= 2;
  }
  return '$numerator/$denominator';
}

// 47.875 -> '47 7/8', 12 -> '12', 0.4375 -> '7/16'.
String formatInches(num inches) {
  final sixteenths = (inches * INCH_DENOMINATOR).round();
  final whole = sixteenths ~/ INCH_DENOMINATOR;
  final rest = sixteenths % INCH_DENOMINATOR;
  if (rest == 0) return '$whole';
  return whole == 0 ? fractionLabel(rest) : '$whole ${fractionLabel(rest)}';
}

// '47 7/8', '7/8', '47' and '47.5' all mean inches. Null when unparsable.
double? parseInches(String value) {
  final text = value.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  final parts = text.split(RegExp(r'\s+'));
  if (parts.length > 2) return null;
  if (parts.length == 1) {
    return parts.single.contains('/')
        ? _parseFraction(parts.single)
        : double.tryParse(parts.single);
  }
  final whole = double.tryParse(parts.first);
  final fraction = _parseFraction(parts.last);
  if (whole == null || fraction == null) return null;
  return whole + fraction;
}

double? _parseFraction(String text) {
  final parts = text.split('/');
  if (parts.length != 2) return null;
  final numerator = double.tryParse(parts.first);
  final denominator = double.tryParse(parts.last);
  if (numerator == null || denominator == null || denominator <= 0) return null;
  return numerator / denominator;
}

// Size as it appears on the laying scheme: bare millimetres, or feet/inches
// carrying their own marks.
String sizeLabel(num mm, MeasurementSystem system) =>
    system == MeasurementSystem.imperial ? formatFeetInches(mm) : '$mm';

String formatSize(num mm, MeasurementSystem system) =>
    system == MeasurementSystem.imperial ? formatInches(mm / MM_PER_INCH) : '$mm';

// Snap to sixteenths first and split afterwards, so that an inch part can
// never carry over into a foot the caller has already read.
int _sixteenthsOf(num mm) => (mm / MM_PER_INCH * INCH_DENOMINATOR).round();

int wholeFeet(num mm) => _sixteenthsOf(mm) ~/ (12 * INCH_DENOMINATOR);

double remainingInches(num mm) =>
    (_sixteenthsOf(mm) - wholeFeet(mm) * 12 * INCH_DENOMINATOR) / INCH_DENOMINATOR;

// 6300mm -> 20'-8'', 190mm -> 7 1/2''
String formatFeetInches(num mm) {
  final feet = wholeFeet(mm);
  final inches = remainingInches(mm);
  if (feet == 0) return "${formatInches(inches)}''";
  // Keep the whole-inch zero once feet are shown, so that 1'-0 9/16'' cannot
  // be misread as 1'-9''.
  final inchText = inches > 0 && inches < 1 ? '0 ${formatInches(inches)}' : formatInches(inches);
  return "$feet'-$inchText''";
}
