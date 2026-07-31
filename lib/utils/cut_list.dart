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

  final lines = <String>[
    '${s.laying_scheme} ${s.variant(number)}',
    '${s.packages_required}: ${totalPacks(result)}',
    '${result.totalPlanks} ${s.panels(result.totalPlanks)}',
    '',
  ];
  for (final line in result.lines) {
    final planks = line.planks.map((p) => '${s.variant(p.number)} ${size(p.length)}').join(', ');
    lines.add('${s.row(line.number + 1)}: $planks');
  }
  lines.add('');
  if (result.pieces.isNotEmpty) {
    lines.add('${s.leftovers}: ${grouped(groupByLength(result.pieces))}');
  }
  final trash = groupByLength(result.trash);
  final waste = '${s.waste} (${wastePercent(result)}%)';
  lines.add(trash.isEmpty ? waste : '$waste: ${grouped(trash)}');
  return lines;
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
