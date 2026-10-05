// Polygon arithmetic the tests do for themselves.
//
// The engine has its own shoelace (`_signedArea` in lib/room_shape.dart) but it
// is private, and deliberately so: nothing outside that file should be deciding
// what "inside" means. A test checking that the planks cover the floor needs
// the same sum for its own reasons, so it is written once here rather than
// copied into every suite that wants it.
import 'dart:ui';

/// The area a closed polygon encloses, by the shoelace formula, whichever way
/// round its corners run.
double polygonArea(List<Offset> polygon) {
  var sum = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final from = polygon[i];
    final to = polygon[(i + 1) % polygon.length];
    sum += from.dx * to.dy - to.dx * from.dy;
  }
  return sum.abs() / 2;
}
