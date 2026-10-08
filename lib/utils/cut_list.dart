import '../l10n/gen/app_localizations.dart';
import '../models.dart';
import 'units.dart';

/// A piece of one line of the report, and whether it is set in bold.
class CutSpan {
  final String text;
  final bool bold;

  const CutSpan(this.text, {this.bold = false});
}

/// One line of the report.
///
/// Pieces rather than a string, because a line is read for its measurements and
/// a row of plain digits hides them: the sizes and the word for a plank that
/// needs no cutting are set in bold, and the numbers naming the planks are not.
/// [text] is the same line unset, which is what the share button sends and what
/// a test matches on — plain text is the one form all three renderers agree on.
class CutLine {
  final List<CutSpan> spans;

  const CutLine(this.spans);

  CutLine.plain(String text) : spans = [CutSpan(text)];

  String get text => spans.map((span) => span.text).join();

  bool get isEmpty => spans.every((span) => span.text.isEmpty);
}

/// The report, a line at a time.
///
/// Built as lines rather than as a widget tree so that the sheet on screen, the
/// text the share button sends and the pages appended to the PDF cannot drift
/// apart: all three render this list.
List<CutLine> cutList(
  Result result,
  int number,
  MeasurementSystem system,
  AppLocalizations s,
) {
  String size(num mm) =>
      system == MeasurementSystem.imperial ? sizeLabel(mm, system) : '$mm ${s.mm}';

  /// A measurement with no unit after it, for the places a list of them stands
  /// together: a row is a column of cut lengths in one unit, and writing the
  /// unit on each of them triples the line for nothing.
  String bare(num mm) =>
      system == MeasurementSystem.imperial ? sizeLabel(mm, system) : '$mm';
  String grouped(Map<int, int> counts) =>
      counts.entries.map((e) => '${size(e.key)} × ${e.value}').join(', ');

  /// One run of planks, as the fitter will cut them: the numbers it covers, the
  /// length they are all cut to, and whether that is a cut at all.
  ///
  /// Mostly only the length. How wide a row is ripped is a property of the row
  /// rather than of what went into it, so the width is said once in front of
  /// the row and the pieces are a list of lengths, which is the order they are
  /// cut in. The exception is a row the floor steps sideways inside: the planks
  /// out past the step are ripped narrower than the rest of their own row, and
  /// [ripTo] is what they are ripped to.
  List<CutSpan> runLabel(List<Plank> run, {required bool fullWidth, int? ripTo}) {
    final numbers = run.length == 1
        ? s.variant(run.first.number)
        : '${s.variant(run.first.number)}–${s.variant(run.last.number)}';
    // Nothing to measure at all: a plank the full width of the pack and the
    // full length of the pack is laid as it comes out of it. Both numbers were
    // typed on the laminate screen and neither is a cut. Bold like a size,
    // because it stands where a size would and says what to set the saw to.
    if (ripTo == null && fullWidth && run.first.length == result.laminateLength) {
      return [CutSpan('$numbers '), CutSpan(s.whole(run.length), bold: true)];
    }
    // Two cuts, so two measurements, written as a size — 290×30. The row's own
    // width stays in front of the row where it is said once; this is the one
    // place a plank is ripped to something other than its row.
    final cut = ripTo == null
        ? bare(run.first.length)
        : '${bare(run.first.length)}×${bare(ripTo)}';
    return [CutSpan('$numbers '), CutSpan(cut, bold: true)];
  }

  /// What each plank of [line] is ripped to, or null where it is ripped to the
  /// row's own width like every other plank in it.
  ///
  /// Planks sit end to end from the row's start and [RowStep] is measured from
  /// there too, so the two are walked together without either having to know
  /// where on the floor the row lies. A plank the step falls *inside* is not in
  /// this list: it is notched round the inside corner rather than ripped, and
  /// the sentence below sends the fitter to the drawing for it.
  List<int?> ripWidths(Line line) {
    final steps = result.rowSteps.where((step) => step.row == line.number).toList();
    final out = <int?>[];
    var u = 0;
    for (final plank in line.planks) {
      final lo = u;
      u += plank.length;
      final step = steps.where((s) => s.holds(lo, u));
      out.add(step.isEmpty ? null : step.first.width);
    }
    return out;
  }

  final lines = <CutLine>[
    CutLine.plain('${s.laying_scheme} ${s.variant(number)}'),
    CutLine.plain('${s.packages_required}: ${totalPacks(result)}'),
    CutLine.plain('${result.totalPlanks} ${s.panels(result.totalPlanks)}'),
    CutLine.plain(''),
  ];
  for (final line in result.lines) {
    if (line.planks.isEmpty) continue;
    final width = line.planks.first.width;
    // The width in front of the row, but only where the row was ripped to it.
    // A row still the width of a plank has nothing to rip and nothing to say:
    // its width is on the pack, and repeating it down thirty rows buries the
    // two or three rows where it is a measurement the fitter has to act on.
    final fullWidth = width == result.laminateWidth;
    // Runs do not span a change of rip width: two planks the same length are
    // not the same cut if one of them is also ripped narrower.
    final rips = ripWidths(line);
    final cut = <List<CutSpan>>[];
    var from = 0;
    for (var i = 1; i <= line.planks.length; i++) {
      if (i < line.planks.length && rips[i] == rips[from]) continue;
      for (final run in runsOf(line.planks.sublist(from, i))) {
        cut.add(runLabel(run, fullWidth: fullWidth, ripTo: rips[from]));
      }
      from = i;
    }
    final spans = <CutSpan>[];
    if (fullWidth) {
      spans.add(CutSpan('${s.row(line.number + 1)}: '));
    } else {
      spans.add(CutSpan('${s.row(line.number + 1)} (×'));
      spans.add(CutSpan(size(width), bold: true));
      spans.add(const CutSpan('): '));
    }
    for (final run in cut) {
      if (!identical(run, cut.first)) spans.add(const CutSpan(', '));
      spans.addAll(run);
    }
    lines.add(CutLine(spans));
  }
  lines.add(CutLine.plain(''));
  // The row that crosses the inside corner of a cut-away corner is laid to the
  // longer of the two lengths the floor has there, and the planks at its far
  // end are notched round that corner rather than cut straight across. Their
  // lengths above are the long side of that cut; the step itself is only on
  // the drawing, so this says where to look for it.
  for (final row in {for (final step in result.rowSteps) step.row}) {
    lines.add(CutLine.plain(s.row_steps_at_notch(row + 1)));
    lines.add(CutLine.plain(''));
  }
  // Plain, both of them. They are a stocktake of what is left over rather than
  // anything to cut, and a line of bold sizes beside a line of counts reads as
  // if the saw were wanted on it.
  if (result.pieces.isNotEmpty) {
    lines.add(CutLine.plain('${s.leftovers}: ${grouped(groupByLength(result.pieces))}'));
  }
  final trash = groupByLength(result.trash);
  final waste = '${s.waste} (${wastePercent(result)}%)';
  lines.add(CutLine.plain(trash.isEmpty ? waste : '$waste: ${grouped(trash)}'));
  return lines;
}

/// A row broken into runs that can be written as one line each.
///
/// A row is mostly planks straight out of the pack, all the same size and all
/// cut from boards the fitter opened one after another — eight lines that say
/// the same thing but for the number. One line with the numbers it spans says
/// it once: `№1–№8 1270 × 270 (whole)`.
///
/// Consecutive numbers as well as equal sizes, because the number is which
/// board a piece came off and not a running count: a row usually opens with
/// the offcut of a board laid two rows ago, and that piece keeps its own
/// number. A range that skipped it would be a lie about where to look for it.
List<List<Plank>> runsOf(List<Plank> planks) {
  final runs = <List<Plank>>[];
  for (final plank in planks) {
    final last = runs.isEmpty ? null : runs.last.last;
    if (last != null &&
        last.length == plank.length &&
        last.width == plank.width &&
        last.number + 1 == plank.number) {
      runs.last.add(plank);
    } else {
      runs.add([plank]);
    }
  }
  return runs;
}

/// Distinct lengths in descending order, each with how many pieces share it.
Map<int, int> groupByLength(List<Plank> planks) {
  final counts = <int, int>{};
  for (final plank in planks) {
    counts.update(plank.length, (n) => n + 1, ifAbsent: () => 1);
  }
  final lengths = counts.keys.toList()..sort((a, b) => b.compareTo(a));
  return {for (final length in lengths) length: counts[length]!};
}

int totalPacks(Result result) => (result.totalPlanks / result.quantityPerPack).ceil();

/// Share of the bought material that never reaches the floor: offcuts too short
/// to reuse, leftovers that stayed unused, and whole planks left in the last
/// pack. Measured in plank lengths, because a row narrowed across its width
/// still consumes planks over their full length.
int wastePercent(Result result) {
  final bought = totalPacks(result) * result.quantityPerPack * result.laminateLength;
  final laid =
      result.lines.expand((line) => line.planks).fold<int>(0, (sum, plank) => sum + plank.length);
  return ((bought - laid) * 100 / bought).round();
}
