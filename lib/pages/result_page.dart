import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'scheme_page.dart';
import '../models.dart';

class ResultPage extends StatelessWidget {
  final List<Result> result;
  ResultPage(this.result);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final totalPacks = (result[0].totalPlanks / result[0].itemsInPack).ceil();
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black.withOpacity(0.8),
        ),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Image(image: AssetImage('lib/assets/floor.png'), fit: BoxFit.cover),
      ),
      body: Stack(
        children: [
          Container(
            width: width,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/floor.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: 60),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Результат',
                        style: TextStyle(fontSize: 24, color: Colors.black.withOpacity(0.8)),
                      ),
                      Text(
                        "Количество упаковок: $totalPacks",
                        style: TextStyle(fontSize: 18),
                      ),
                      for (int i = 0; i < result.length; i++) ...[
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute(builder: (context) => SchemePage(result[i]))),
                          child: Text(
                            "Вариант ${i + 1}: ${result[i].totalPlanks} ",
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      ],
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
