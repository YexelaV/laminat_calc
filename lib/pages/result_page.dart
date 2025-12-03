import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'scheme_page.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';

class ResultPage extends StatelessWidget {
  final List<Result> result;
  ResultPage(this.result);

  String ending(BuildContext context, int number) {
    final str = number.toString();
    if (str.endsWith('1')) return AppStrings.of(context).panel_1;
    if (str.endsWith('2') || str.endsWith('3') || str.endsWith('4'))
      return AppStrings.of(context).panel_2_3_4;
    return AppStrings.of(context).panel_more;
  }

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
        //   elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            //color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: 60),
              child: Container(
                // color: Colors.black,
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(20), color: Colors.black.withOpacity(0.05)),
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
                        itemBuilder: (context, i) {
                          return TextButton(
                              child: Container(
                                  alignment: Alignment.center,
                                  //      width: 100,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.blue,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "№${i + 1} - ${result[i].totalPlanks} " +
                                            ending(context, result[i].totalPlanks),
                                        style: TextStyle(color: Colors.white, fontSize: 18),
                                      ),
                                    ],
                                  )),
                              onPressed: () => Navigator.of(context).push(CupertinoPageRoute(
                                  builder: (context) => SchemePage(result[i], i + 1))));
                        },
                        shrinkWrap: true,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          //   ),
        ],
      ),
    );
  }
}
