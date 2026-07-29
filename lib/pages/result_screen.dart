import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:floor_calculator/widgets/app_background.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../utils/cut_list.dart';

class ResultScreen extends StatelessWidget {
  final List<Result> result;
  const ResultScreen(this.result, {super.key});

  @override
  Widget build(BuildContext context) {
    final packs = totalPacks(result[0]);
    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppStrings.of(context).result,
            style: TextStyle(fontSize: 18, color: Colors.black)),
        leading: Padding(
          padding: EdgeInsets.only(left: 12),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 24, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // The same card the two form screens use, so the variants read as a sheet
      // laid on the background rather than text printed on it. It scrolls
      // because the number of variants is not bounded.
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${AppStrings.of(context).packages_required}: ",
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        "$packs",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.blue),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  // Every variant fits the same number of packs and covers the
                  // same floor, so the waste share is a property of the
                  // calculation, not of the variant the user picks.
                  Text(
                    "${AppStrings.of(context).waste}: ${wastePercent(result[0])}%",
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "${AppStrings.of(context).laying_variants}:",
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  ListView.builder(
                    itemCount: result.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, i) {
                      return TextButton(
                        onPressed: () =>
                            context.router.push(SchemeRoute(result: result[i], number: i + 1)),
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.blue,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${AppStrings.of(context).variant(i + 1)} - ${result[i].totalPlanks} "
                                "${AppStrings.of(context).panels(result[i].totalPlanks)}",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "${AppStrings.of(context).leftovers}: "
                                "${result[i].pieces.length} ${AppStrings.of(context).pcs}",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
