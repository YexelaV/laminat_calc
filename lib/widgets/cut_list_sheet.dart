import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../l10n/gen/app_localizations.dart';
import '../models.dart';
import '../utils/cut_list.dart';
import '../utils/units.dart';

// The report is built as a list of lines so the sheet and the shared text
// cannot drift apart: the share button joins the very same lines.
class CutListSheet extends StatelessWidget {
  final Result result;
  final int number;
  final MeasurementSystem system;

  const CutListSheet(this.result, this.number, this.system, {super.key});

  String _size(num mm, AppLocalizations s) =>
      system == MeasurementSystem.imperial ? sizeLabel(mm, system) : '$mm ${s.mm}';

  String _grouped(Map<int, int> counts, AppLocalizations s) =>
      counts.entries.map((e) => '${_size(e.key, s)} × ${e.value}').join(', ');

  List<String> report(AppLocalizations s) {
    final lines = <String>[
      '${s.laying_scheme} ${s.variant(number)}',
      '${s.packages_required}: ${totalPacks(result)}',
      '${result.totalPlanks} ${s.panels(result.totalPlanks)}',
      '',
    ];
    for (final line in result.lines) {
      final planks =
          line.planks.map((p) => '${s.variant(p.number)} ${_size(p.length, s)}').join(', ');
      lines.add('${s.row(line.number + 1)}: $planks');
    }
    lines.add('');
    if (result.pieces.isNotEmpty) {
      lines.add('${s.leftovers}: ${_grouped(groupByLength(result.pieces), s)}');
    }
    final trash = groupByLength(result.trash);
    final waste = '${s.waste} (${wastePercent(result)}%)';
    lines.add(trash.isEmpty ? waste : '$waste: ${_grouped(trash, s)}');
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final lines = report(s);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child:
                      Text(s.cut_list, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  icon: Icon(Icons.share_rounded, size: 24, color: Colors.black),
                  onPressed: () => SharePlus.instance.share(ShareParams(text: lines.join('\n'))),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: lines.length,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text(lines[i], style: TextStyle(fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
