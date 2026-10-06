import '../l10n/gen/app_localizations.dart';
import '../models.dart';
import 'units.dart';

/// The report, a line at a time.
///
/// Built as lines rather than as a widget tree so that the sheet on screen, the
/// text the share button sends and the pages appended to the PDF cannot drift
/// apart: all three render this list.
List<String> cutList(
  Result result,
  int number,
  MeasurementSystem system,
  AppLocalizations s,
) {
  String size(num mm) =>
      system == MeasurementSystem.imperial ? sizeLabel(mm, system) : '$mm ${s.mm}';
  String grouped(Map<int, int> counts) =>
      counts.entries.map((e) => '${size(e.key)} × ${e.value}').join(', ');

  /// One run of planks, as the fitter will cut them: the numbers it covers, the
  /// length they are all cut to, and whether that is a cut at all.
  ///
  /// Only the length. How wide a row is ripped is a property of the row and not
  /// of what went into it — every plank in one carries the same width — so the
  /// width is said once in front of the row and the pieces are a list of
  /// lengths, which is the order they are cut in.
  String runLabel(List<Plank> run, {required bool fullWidth}) {
    final numbers = run.length == 1
        ? s.variant(run.first.number)
        : '${s.variant(run.first.number)}–${s.variant(run.last.number)}';
    final length = system == MeasurementSystem.imperial
        ? sizeLabel(run.first.length, system)
        : '${run.first.length}';
    final whole = fullWidth && run.first.length == result.laminateLength;
    return whole ? '$numbers $length (${s.whole})' : '$numbers $length';
  }

  final lines = <String>[
    '${s.laying_scheme} ${s.variant(number)}',
    '${s.packages_required}: ${totalPacks(result)}',
    '${result.totalPlanks} ${s.panels(result.totalPlanks)}',
    '',
  ];
  for (final line in result.lines) {
    if (line.planks.isEmpty) continue;
    final width = line.planks.first.width;
    final cut = runsOf(line.planks)
        .map((run) => runLabel(run, fullWidth: width == result.laminateWidth))
        .join(', ');
    lines.add('${s.row(line.number + 1)} (×${size(width)}): $cut');
  }
  lines.add('');
  // The row that crosses the inside corner of a cut-away corner is laid to the
  // longer of the two lengths the floor has there, and the planks at its far
  // end are notched round that corner rather than cut straight across. Their
  // lengths above are the long side of that cut; the step itself is only on
  // the drawing, so this says where to look for it.
  for (final row in result.steppedRows) {
    lines.add(s.row_steps_at_notch(row + 1));
    lines.add('');
  }
  if (result.pieces.isNotEmpty) {
    lines.add('${s.leftovers}: ${grouped(groupByLength(result.pieces))}');
  }
  final trash = groupByLength(result.trash);
  final waste = '${s.waste} (${wastePercent(result)}%)';
  lines.add(trash.isEmpty ? waste : '$waste: ${grouped(trash)}');
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
