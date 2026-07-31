import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../utils/cut_list.dart';
import '../utils/units.dart';

class CutListSheet extends StatelessWidget {
  final Result result;
  final int number;
  final MeasurementSystem system;

  const CutListSheet(this.result, this.number, this.system, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final lines = cutList(result, number, system, s);
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
