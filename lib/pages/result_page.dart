import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        //title:
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
              padding: EdgeInsets.only(left: 20, right: 20, bottom: 56),
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
