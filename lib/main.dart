import 'package:flutter/material.dart';
import 'pages/start_page.dart';
import 'localization.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [AppLocalizationsDelegate()],
      debugShowCheckedModeBanner: false,
      home: StartPage(),
    );
  }
}
