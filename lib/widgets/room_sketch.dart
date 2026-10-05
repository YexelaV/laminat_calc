// A small drawing of the room as its measurements describe it, with each
// measurement written on the wall it belongs to.
//
// Without it the form asks for "length 2" and the user has to guess which wall
// that is, and for a diagonal without saying between which corners. Drawn to
// scale, it answers both without a word of text, and a measurement that makes
// no room shows up as a shape that is obviously wrong before the Next button
// ever explains why.
//
// A room with a corner cut away asks one more question the fields cannot: which
// corner. The sketch answers that one too, and takes the answer — the corners
// are the targets, so the user points at the corner rather than reading four
// names and matching them to a picture.
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../room_shape.dart';
import '../utils/units.dart';

/// What is kept clear around the outline.
///
/// It used to be room for the measurements, which were written outside the
/// walls they belong to: a third of the sketch each way, and the drawing held
/// to whatever was left. The measurements are inside the room now, so what is
/// left out here is only the air that keeps the outline off the edge of the
/// sketch — and enough of it for the one case that still writes a number
/// outside, a room too narrow or too shallow to hold its own.
///
/// Pixels rather than a share of the box. A share takes the same cut out of
/// both axes, so the taller the sketch grew the more of it went to a margin
/// that was already too big — and the room inside stopped growing with it,
/// because the outline is held by whichever axis binds first and that axis was
/// the one the margin was not helping.
///
/// None at all across: the room is drawn out to the same two edges the boxes
/// above it are typed between, so the drawing and the form are one column
/// rather than a column with a picture floating inside it.
const double _marginX = 0;
const double _marginY = 26;

/// How much air is left between a measurement and the wall it belongs to.
///
/// Between the wall and the *edge* of the label, not its middle. Measured to
/// the middle, a number as wide as `6'-6 3/4"` written end-on to a side wall
/// started out lying across that wall, and the search below had to dig it out
/// of there — which it could not always do, because a label that has to move
/// half its own width runs out of the drawing first.
const double _labelPush = 8;

const double _labelSize = 13;

/// Clearance kept around every measurement, in pixels. Two numbers that merely
/// do not overlap still read as one number — '1800' beside '1200' is '18001200'
/// — and the walls of a cut-away corner put two of them side by side.
const double _labelGap = 6;

/// What stands in for a measurement nobody has typed. Short, so that it never
/// crowds its neighbours out of the drawing the way a number would.
const String _unknown = '?';

/// The ink a measurement is written in.
///
/// Plain black, so that the one measurement the cursor is in can be the only
/// coloured thing on the drawing. Written in the outline's own blue before, all
/// five of them at once, which made "picked out" mean nothing.
const Color _labelInk = Colors.black87;

/// The colour a measurement is picked out in while its box has the cursor. The
/// blue the field's own border turns, so the box on the form and the number on
/// the drawing are plainly the same answer.
const Color _litColour = Colors.blue;

/// Material's smallest comfortable target. The outline is over 120 px tall, so
/// four of these at its corners clear each other with room to spare.
const double _cornerTarget = 44;

/// How tall the drawing is. A fixed height rather than a share of the screen:
/// the card is centred and scrolls, so there is nothing to take a share of, and
/// a drawing that changed size with the phone would be a different drawing on
/// every one.
///
/// Raised from 150 once the shape tiles went to one row and the boxes to a
/// 12 px rhythm. That bought the form about 150 px, and the drawing is what the
/// user reads to check they have measured the right wall — so it is where the
/// room went back.
const double _height = 220;

/// Where the sketch puts a point of the room in the box it was given.
///
/// Shared by the painter and the corner targets, so that a tap lands on the
/// corner it is drawn over rather than near it.
class SketchProjection {
  final Rect bounds;
  final double scale;
  final Offset centre;

  const SketchProjection._(this.bounds, this.scale, this.centre);

  factory SketchProjection(List<Offset> corners, Size box) {
    var bounds = Rect.fromPoints(corners.first, corners.first);
    for (final corner in corners.skip(1)) {
      bounds = bounds.expandToInclude(Rect.fromPoints(corner, corner));
    }
    final scale = math.min(
      math.max(box.width - 2 * _marginX, 1) / bounds.width,
      math.max(box.height - 2 * _marginY, 1) / bounds.height,
    );
    return SketchProjection._(bounds, scale, Offset(box.width / 2, box.height / 2));
  }

  bool get isUsable => bounds.width > 0 && bounds.height > 0;

  Offset call(Offset mm) => centre + (mm - bounds.center) * scale;
}

class RoomSketch extends StatelessWidget {
  final RoomOutline shape;
  final MeasurementSystem system;

  /// Which corner is cut away, drawn as the handle that is filled in. Null for
  /// a room with no single corner to point at — one with no cuts at all, and
  /// one whose cuts come in a pair, which is pointed at by its wall instead.
  final RoomCorner? cutCorner;

  /// Which wall the pair of cuts stands on, drawn as the handle that is filled
  /// in. Null for every room whose cuts are not a pair.
  ///
  /// A wall and not two corners because that is the question being asked. A T
  /// has a stem, the stem comes off one wall of four, and a user who wants it
  /// on another wall should not have to work out which two corners that means.
  final RoomWall? cutWall;

  /// What to do when one of the four corners is tapped. Null leaves the sketch
  /// a picture, which is what a room measured wall by wall wants.
  final ValueChanged<RoomCorner>? onCorner;

  /// What to do when one of the four walls is tapped.
  final ValueChanged<RoomWall>? onWall;

  /// Walls whose measurement nobody has typed yet, by their index in
  /// [RoomOutline.wallLengths].
  ///
  /// The outline needs a number for every wall or it is not an outline, so an
  /// empty box is filled in with something that makes a room — the wall
  /// opposite, or a third of the side. Writing that number on the wall would be
  /// the drawing telling the user what they measured. A question mark says what
  /// is true instead: the shape is the calculator's guess until the box is
  /// filled, and the picture is worth no more than the guess.
  final Set<int> unknownWalls;

  /// Whether the diagonal is one of those.
  final bool unknownDiagonal;

  /// Walls whose measurement is being typed this moment, drawn picked out from
  /// the rest. Which of several numbers on a crowded sketch belongs to the box
  /// under the cursor is otherwise a puzzle — and for a room measured wall by
  /// wall, four walls and a diagonal is crowded.
  final Set<int> litWalls;

  /// Whether the cursor is in the diagonal's box.
  final bool litDiagonal;

  const RoomSketch({
    super.key,
    required this.shape,
    required this.system,
    this.cutCorner,
    this.cutWall,
    this.onCorner,
    this.onWall,
    this.unknownWalls = const {},
    this.unknownDiagonal = false,
    this.litWalls = const {},
    this.litDiagonal = false,
  });

  /// The outline to draw. Measurements that describe no room are drawn as the
  /// shape they would be if they did, greyed out: something has to be on
  /// screen while a digit is half typed, and a folded-over outline is worse
  /// than none.
  List<Offset> _outline() {
    final closes = shape.problem == null;
    final RoomOutline drawable;
    if (closes) {
      drawable = shape;
    } else if (shape is CutCornersRoomShape) {
      // Clamped rather than replaced by a rectangle: the user is reading this
      // picture to see which corners are cut, and taking the cuts away while
      // they type the numbers of them answers a question they did not ask.
      //
      // Each leg is held inside the side it is measured on, and where two cuts
      // share a side they are held inside half of it each. Half rather than
      // what the other one leaves, because mid-typing both are nonsense and
      // halves at least stay put while the digits arrive.
      final cut = shape as CutCornersRoomShape;
      int room(int side, bool shared) => math.max(1, (shared ? side ~/ 2 : side) - 1);
      bool sharesAlong(RoomCorner corner) => cut.cuts.keys.any((other) =>
          other != corner && _sameLengthWall(other, corner));
      bool sharesAcross(RoomCorner corner) => cut.cuts.keys.any((other) =>
          other != corner && _sameWidthWall(other, corner));
      drawable = CutCornersRoomShape(
        length: cut.length,
        width: cut.width,
        cut: cut.cut,
        cuts: {
          for (final entry in cut.cuts.entries)
            entry.key: CornerSize(
              along: entry.value.along.clamp(1, room(cut.length, sharesAlong(entry.key))),
              across: entry.value.across.clamp(1, room(cut.width, sharesAcross(entry.key))),
            ),
        },
      );
    } else {
      final quadrilateral = shape as RoomShape;
      drawable = RoomShape.rectangle(quadrilateral.lengthNear, quadrilateral.widthLeft);
    }
    return [for (final p in drawable.corners()) Offset(p.x, p.y)];
  }

  /// What is written beside each wall: the measurement, or a question mark for
  /// a wall whose box is still empty.
  List<String> _labels() {
    final walls = shape.wallLengths();
    return [
      for (var i = 0; i < walls.length; i++)
        if (unknownWalls.contains(i)) _unknown else sizeLabel(walls[i], system)
    ];
  }

  @override
  Widget build(BuildContext context) {
    final closes = shape.problem == null;
    final corners = _outline();
    final quadrilateral = shape is RoomShape ? shape as RoomShape : null;
    return SizedBox(
      height: _height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final box = Size(constraints.maxWidth, constraints.maxHeight);
          final place = SketchProjection(corners, box);
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoomSketchPainter(
                    corners: corners,
                    labels: _labels(),
                    diagonalLabel: quadrilateral == null
                        ? null
                        : unknownDiagonal
                            ? _unknown
                            : sizeLabel(quadrilateral.diagonal, system),
                    litWalls: litWalls,
                    litDiagonal: litDiagonal,
                    cutCorner: cutCorner,
                    cutWall: cutWall,
                    closes: closes,
                    place: place,
                    textStyle: DefaultTextStyle.of(context).style,
                  ),
                ),
              ),
              if (onCorner != null && place.isUsable)
                for (final corner in RoomCorner.values)
                  _target(context, corner, place),
              if (onWall != null && place.isUsable)
                for (final wall in RoomWall.values) _wallTarget(context, wall, place),
            ],
          );
        },
      ),
    );
  }

  /// A tap target over one corner of the bounding rectangle.
  ///
  /// The bounding rectangle and not the outline: the cut corner is the one
  /// corner of the four that is *not* on the outline, and it has to be as easy
  /// to point at as the other three.
  Widget _target(BuildContext context, RoomCorner corner, SketchProjection place) {
    final at = place(_cornerOf(corner, place.bounds));
    return Positioned(
      left: at.dx - _cornerTarget / 2,
      top: at.dy - _cornerTarget / 2,
      width: _cornerTarget,
      height: _cornerTarget,
      child: Semantics(
        button: true,
        selected: corner == cutCorner,
        label: _cornerName(context, corner),
        child: GestureDetector(
          key: ValueKey('cut-corner-${corner.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onCorner!(corner),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  /// A tap target over the middle of one wall of the bounding rectangle.
  Widget _wallTarget(BuildContext context, RoomWall wall, SketchProjection place) {
    final at = place(_wallMiddle(wall, place.bounds));
    return Positioned(
      left: at.dx - _cornerTarget / 2,
      top: at.dy - _cornerTarget / 2,
      width: _cornerTarget,
      height: _cornerTarget,
      child: Semantics(
        button: true,
        selected: wall == cutWall,
        label: _wallName(context, wall),
        child: GestureDetector(
          key: ValueKey('cut-wall-${wall.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onWall!(wall),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Whether two corners sit at the two ends of the same near or far wall, and so
/// share the room's length between their cuts.
bool _sameLengthWall(RoomCorner a, RoomCorner b) =>
    (a == RoomCorner.nearLeft && b == RoomCorner.nearRight) ||
    (a == RoomCorner.nearRight && b == RoomCorner.nearLeft) ||
    (a == RoomCorner.farLeft && b == RoomCorner.farRight) ||
    (a == RoomCorner.farRight && b == RoomCorner.farLeft);

/// The same, for the left and right walls and the room's width.
bool _sameWidthWall(RoomCorner a, RoomCorner b) =>
    (a == RoomCorner.nearLeft && b == RoomCorner.farLeft) ||
    (a == RoomCorner.farLeft && b == RoomCorner.nearLeft) ||
    (a == RoomCorner.nearRight && b == RoomCorner.farRight) ||
    (a == RoomCorner.farRight && b == RoomCorner.nearRight);

/// The middle of each wall of the bounding rectangle — where its handle sits
/// and where it is tapped.
Offset _wallMiddle(RoomWall wall, Rect bounds) {
  switch (wall) {
    case RoomWall.near:
      return bounds.topCenter;
    case RoomWall.right:
      return bounds.centerRight;
    case RoomWall.far:
      return bounds.bottomCenter;
    case RoomWall.left:
      return bounds.centerLeft;
  }
}

/// Named by where it is in the picture, for the reason [_cornerName] gives.
String _wallName(BuildContext context, RoomWall wall) {
  final strings = AppStrings.of(context);
  switch (wall) {
    case RoomWall.near:
      return strings.wall_top;
    case RoomWall.right:
      return strings.wall_right;
    case RoomWall.far:
      return strings.wall_bottom;
    case RoomWall.left:
      return strings.wall_left;
  }
}

/// Which corner of the bounding rectangle each name points at, with the near
/// wall drawn along the top as the finished scheme draws it.
Offset _cornerOf(RoomCorner corner, Rect bounds) {
  switch (corner) {
    case RoomCorner.nearLeft:
      return bounds.topLeft;
    case RoomCorner.nearRight:
      return bounds.topRight;
    case RoomCorner.farRight:
      return bounds.bottomRight;
    case RoomCorner.farLeft:
      return bounds.bottomLeft;
  }
}

/// Named by where it is in the picture rather than by near and far. The sketch
/// is right beside the control, so "top left" is read off the drawing; "near
/// left" would have to be worked out from it.
String _cornerName(BuildContext context, RoomCorner corner) {
  final strings = AppStrings.of(context);
  switch (corner) {
    case RoomCorner.nearLeft:
      return strings.corner_top_left;
    case RoomCorner.nearRight:
      return strings.corner_top_right;
    case RoomCorner.farRight:
      return strings.corner_bottom_right;
    case RoomCorner.farLeft:
      return strings.corner_bottom_left;
  }
}

class _RoomSketchPainter extends CustomPainter {
  final List<Offset> corners;

  /// One per wall, in the order the corners run.
  final List<String> labels;

  /// Null for a room that has no diagonal to measure.
  final String? diagonalLabel;

  /// The corner cut away, drawn as a filled handle among three hollow ones.
  final RoomCorner? cutCorner;

  /// The wall a pair of cuts stands on, drawn the same way but at the middles
  /// of the walls rather than at the corners. Never set at the same time as
  /// [cutCorner]: a room is pointed at one way or the other.
  final RoomWall? cutWall;

  /// Which labels are picked out, and whether the diagonal's is one of them.
  final Set<int> litWalls;
  final bool litDiagonal;

  final bool closes;
  final SketchProjection place;
  final TextStyle textStyle;

  const _RoomSketchPainter({
    required this.corners,
    required this.labels,
    required this.diagonalLabel,
    required this.cutCorner,
    required this.cutWall,
    required this.litWalls,
    required this.litDiagonal,
    required this.closes,
    required this.place,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!place.isUsable) return;
    Offset px(Offset mm) => place(mm);

    // Grey all over when the measurements describe no room: a drawing that is
    // wrong everywhere should not have one part of it looking settled.
    final ink = closes ? _labelInk : Colors.grey;
    final lit = closes ? _litColour : Colors.grey;

    final wall = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = ink;
    final path = Path()..moveTo(px(corners.first).dx, px(corners.first).dy);
    for (final corner in corners.skip(1)) {
      path.lineTo(px(corner).dx, px(corner).dy);
    }
    canvas.drawPath(path..close(), wall);

    // The wall being measured, drawn over the one just drawn rather than
    // instead of it. Laid over, its round caps cover the corners it shares with
    // its neighbours; drawn in place of it, the butt ends of a thicker line
    // would leave a notch at each end of it.
    if (litWalls.isNotEmpty) {
      final litWall = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = lit;
      for (final i in litWalls) {
        if (i >= corners.length) continue;
        canvas.drawLine(px(corners[i]), px(corners[(i + 1) % corners.length]), litWall);
      }
    }

    // The diagonal, dashed so it reads as a measurement rather than a wall.
    if (diagonalLabel != null) {
      _dashed(canvas, px(corners[0]), px(corners[2]), litDiagonal ? lit : ink);
    }

    // Each measurement sits just clear of the wall it belongs to, pushed along
    // that wall's own normal rather than away from the middle of the room: in a
    // badly out-of-square room the middle is not reliably on the other side of
    // the wall, and the label lands back on the drawing.
    //
    // Into the room, not out of it. The measurements used to ring the outline,
    // which meant four margins wide enough to write a number in and a room
    // drawn in whatever was left of the sketch. Over the floor they cost
    // nothing: the floor is empty, and it is the biggest empty thing here.
    final normals = inwardNormals([for (final p in corners) Point(p.dx, p.dy)]);
    final drawn = [for (final corner in corners) px(corner)];
    // Unless the room drawn is too small to hold them, which is decided per
    // direction. A room ten times as long as it is deep comes out a strip:
    // across it there is room for the two numbers pushed in from the sides, and
    // down it none at all — the label is taller than the strip and would lie
    // over both of its walls. Measured on the drawing rather than on the room,
    // because the drawing is where the label has to fit.
    final line = _box('', Offset.zero).height;
    final widest = labels.fold<double>(0, (w, label) => math.max(w, _box(label, Offset.zero).width));
    final drawnWidth = place.bounds.width * place.scale;
    final drawnHeight = place.bounds.height * place.scale;
    final insideSideways = drawnWidth >= 2 * (_labelPush + widest) + _labelGap;
    final insideUpDown = drawnHeight >= 2 * (_labelPush + line) + _labelGap &&
        drawnWidth >= widest + _labelGap;
    // The handles are drawn last but claimed first: a measurement that lands on
    // one reads as a number with a dot through it, and the handle is the
    // control the caption underneath tells the user to press.
    //
    // Only the ones that are drawn. The chosen handle is not, so the space it
    // would have taken is left for whatever measurement wants it — which beside
    // a cut corner is usually the cut's own, and that one has nowhere else to go
    // but further out into the margin.
    final taken = <Rect>[
      if (cutCorner != null)
        for (final corner in RoomCorner.values)
          if (corner != cutCorner)
            Rect.fromCircle(center: place(_cornerOf(corner, place.bounds)), radius: 8)
                .inflate(_labelGap),
      if (cutWall != null)
        for (final wall in RoomWall.values)
          if (wall != cutWall)
            Rect.fromCircle(center: place(_wallMiddle(wall, place.bounds)), radius: 8)
                .inflate(_labelGap),
    ];
    for (var i = 0; i < corners.length && i < labels.length; i++) {
      final middle = (px(corners[i]) + px(corners[(i + 1) % corners.length])) / 2;
      final outward = -Offset(normals[i].x, normals[i].y);
      // Which way the label is pushed decides which of the two bounds it has
      // to clear: a wall the drawing runs up and down carries its number across
      // the room, and one it runs along carries it down the room. A chamfer
      // leans equally both ways and is counted with the second, which is the
      // kinder of the two for a cut that short.
      final inside =
          outward.dx.abs() > outward.dy.abs() ? insideSideways : insideUpDown;
      final span = _box(labels[i], Offset.zero);

      /// How far a label pushed [way] reaches back towards its wall: half its
      /// width going sideways, half its height going up or down, and a mix of
      /// the two off a chamfer. Measured so that [_labelPush] is the air
      /// between the wall and the label's edge rather than its middle.
      double reachOf(Offset way) =>
          way.dx.abs() * span.width / 2 + way.dy.abs() * span.height / 2;

      Offset settledAt(Offset way) => middle + way * (_labelPush + reachOf(way));

      /// Somewhere clear on that side of the wall, or null if there is nowhere.
      ///
      /// The two walls of a cut-away corner are short and meet each other, so
      /// their middles are a few pixels apart: left where they land, their
      /// measurements sit on one another and on the wall running past. Each
      /// looks further off its own wall and then to either side along it —
      /// never across to another wall, so that it still reads as belonging to
      /// the wall it came from.
      ///
      /// Moved, but never off the drawing: the form goes on underneath, so a
      /// measurement nudged past the edge lands on whatever is written there.
      Offset? clearSpot(Offset way) {
        final reach = reachOf(way);
        final along = Offset(-way.dy, way.dx);
        for (var step = 0; step < 4; step++) {
          for (final slide in const [0.0, 10.0, -10.0, 20.0, -20.0]) {
            final candidate =
                middle + way * (_labelPush + reach + step * 8) + along * slide;
            // The clearance is what a measurement keeps from its neighbours and
            // from the walls, not from the edge of the drawing: counted against
            // the edge as well, it turned the last few pixels of the margin
            // into somewhere a label could not go, which is where a label sent
            // out of a crowded room has to go.
            final box = _box(labels[i], candidate);
            if (!(Offset.zero & size).contains(box.topLeft) ||
                !(Offset.zero & size).contains(box.bottomRight)) {
              continue;
            }
            final padded = box.inflate(_labelGap);
            if (!taken.any(padded.overlaps) && !_crossesOutline(padded, drawn)) {
              return candidate;
            }
          }
        }
        return null;
      }

      // Inside if that is where this wall's measurements go, and out in the
      // margin if there is nowhere inside for this one. A room with barely
      // room between its walls for its own numbers — an L six metres deep and
      // three across comes out ninety pixels wide — is better off with one of
      // them in the margin than with two of them on top of each other.
      final want = inside ? -outward : outward;
      final at = clearSpot(want) ?? clearSpot(-want) ?? settledAt(want);
      taken.add(_box(labels[i], at).inflate(_labelGap));
      // A number over the floor has the diagonal to cross, and the diagonal is
      // the one line on the drawing that runs where nothing else does.
      _text(canvas, labels[i], at, litWalls.contains(i) ? lit : ink,
          background: inside || litWalls.contains(i));
    }

    if (cutCorner != null || cutWall != null) _handles(canvas, ink);

    if (diagonalLabel == null) return;
    // The diagonal's own number goes as near the middle of it as it can while
    // still clearing the wall labels. The middle itself is the obvious place
    // and often the wrong one: it is the height the two side walls carry their
    // labels at, and in a badly out-of-square room it is where a corner is.
    final from = px(corners[0]);
    final along = px(corners[2]) - from;
    var best = from + along * 0.5;
    var least = double.infinity;
    for (final fraction in [0.5, 0.42, 0.58, 0.34, 0.66, 0.26, 0.74]) {
      final at = from + along * fraction;
      final box = _box(diagonalLabel!, at).inflate(2);
      final overlap = taken.fold<double>(0, (sum, other) {
        final shared = box.intersect(other);
        return sum + (shared.isEmpty ? 0 : shared.width * shared.height);
      });
      if (overlap < least) {
        least = overlap;
        best = at;
        if (overlap == 0) break;
      }
    }
    _text(canvas, diagonalLabel!, best, litDiagonal ? lit : ink, background: true);
  }

  /// The handles that can still be pressed: the corners of the bounding
  /// rectangle for a room with one cut, the middles of its walls for a room
  /// whose cuts come in a pair.
  ///
  /// The chosen one is not drawn. It used to be, filled and blue, and it was
  /// the one handle that said nothing: where the cut is, is what the outline is
  /// already drawing. Worse, a corner handle sits on the bounding rectangle
  /// rather than on the room, so the chosen one floated in the empty space the
  /// cut left — a blue dot outside the walls, which reads as a part of the room
  /// rather than as a control. What is left says what it means: these three are
  /// the corners the cut could move to.
  void _handles(Canvas canvas, Color ink) {
    final places = <Offset>[
      for (final wall in RoomWall.values)
        if (cutWall != null && wall != cutWall) place(_wallMiddle(wall, place.bounds)),
      for (final corner in RoomCorner.values)
        if (cutWall == null && corner != cutCorner)
          place(_cornerOf(corner, place.bounds)),
    ];
    for (final at in places) {
      canvas.drawCircle(
        at,
        4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = ink.withValues(alpha: 0.4),
      );
    }
  }

  void _dashed(Canvas canvas, Offset from, Offset to, Color colour) {
    const dash = 6.0;
    const gap = 4.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colour.withValues(alpha: 0.6);
    final total = (to - from).distance;
    if (total == 0) return;
    final step = (to - from) / total;
    for (var at = 0.0; at < total; at += dash + gap) {
      canvas.drawLine(from + step * at, from + step * math.min(at + dash, total), paint);
    }
  }

  /// Whether any wall runs through [box].
  ///
  /// A measurement written across a wall is the one thing on this drawing that
  /// cannot be read at all, and the walls of a cut-away corner are short
  /// enough that one wall's label reaches the next.
  bool _crossesOutline(Rect box, List<Offset> drawn) {
    for (var i = 0; i < drawn.length; i++) {
      if (_wallCrosses(drawn[i], drawn[(i + 1) % drawn.length], box)) return true;
    }
    return false;
  }

  /// Whether the segment from [a] to [b] meets [box], by clipping the segment
  /// to each of the box's four sides in turn and seeing whether anything of it
  /// is left (Liang–Barsky).
  bool _wallCrosses(Offset a, Offset b, Rect box) {
    var from = 0.0;
    var to = 1.0;
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    for (var side = 0; side < 4; side++) {
      final double towards;
      final double room;
      if (side == 0) {
        towards = -dx;
        room = a.dx - box.left;
      } else if (side == 1) {
        towards = dx;
        room = box.right - a.dx;
      } else if (side == 2) {
        towards = -dy;
        room = a.dy - box.top;
      } else {
        towards = dy;
        room = box.bottom - a.dy;
      }
      if (towards == 0) {
        // Parallel to this side: either wholly inside it or wholly past it.
        if (room < 0) return false;
        continue;
      }
      final at = room / towards;
      if (towards < 0) {
        if (at > to) return false;
        if (at > from) from = at;
      } else {
        if (at < from) return false;
        if (at < to) to = at;
      }
    }
    return true;
  }

  TextPainter _layout(String text, Color colour) => TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(fontSize: _labelSize, color: colour),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  /// Where [text] would sit if it were written centred on [centre].
  Rect _box(String text, Offset centre) {
    final painter = _layout(text, Colors.black);
    return Rect.fromCenter(center: centre, width: painter.width, height: painter.height);
  }

  void _text(Canvas canvas, String text, Offset centre, Color colour,
      {bool background = false}) {
    final painter = _layout(text, colour);
    final at = centre - Offset(painter.width / 2, painter.height / 2);
    if (background) {
      // The diagonal runs under its own label; blanking the line behind it
      // keeps the number readable.
      canvas.drawRect(
        Rect.fromLTWH(at.dx - 2, at.dy, painter.width + 4, painter.height),
        Paint()..color = Colors.white,
      );
    }
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_RoomSketchPainter old) =>
      !listEquals(old.corners, corners) ||
      !listEquals(old.labels, labels) ||
      old.diagonalLabel != diagonalLabel ||
      old.cutCorner != cutCorner ||
      old.cutWall != cutWall ||
      !setEquals(old.litWalls, litWalls) ||
      old.litDiagonal != litDiagonal ||
      old.closes != closes ||
      // Not derived from anything above: the style comes from the ambient
      // DefaultTextStyle, so a change of system font scale would otherwise
      // leave the measurements drawn at the old size. ([place] needs no
      // comparison — it is a function of the corners and the box, and a change
      // of box repaints through layout.)
      old.textStyle != textStyle;
}
