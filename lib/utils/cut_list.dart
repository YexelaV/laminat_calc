import '../models.dart';

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
