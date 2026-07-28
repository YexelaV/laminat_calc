import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:floor_calculator/router/app_router.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';

class ResultScreen extends StatelessWidget {
  final List<Result> result;
  const ResultScreen(this.result, {super.key});

  @override
  Widget build(BuildContext context) {
    final totalPacks = (result[0].totalPlanks / result[0].quantityPerPack).ceil();
    return Scaffold(
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
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 60),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${AppStrings.of(context).packages_required}: ",
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        "$totalPacks",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.blue),
                      ),
                    ],
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
                    itemBuilder: (context, i) {
                      return TextButton(
                        onPressed: () =>
                            context.router.push(SchemeRoute(result: result[i], number: i + 1)),
                        child: Container(
                          alignment: Alignment.center,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.blue,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "№${i + 1} - ${result[i].totalPlanks} "
                                "${AppStrings.of(context).panels(result[i].totalPlanks)}",
                                style: TextStyle(color: Colors.white, fontSize: 18),
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
        ],
      ),
    );
  }
}
