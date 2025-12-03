import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StartScreen extends StatefulWidget {
  StartScreen({Key? key}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(AppStrings.of(context).title, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Center(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          GestureDetector(
            onTap: () {
              MyApp.of(context)?.setLocale(Locale('ru'));
              context.router.push(RoomAndLaminateParametersRoute());
            },
            child: Container(
              width: 100,
              height: 100,
              padding: EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.black12),
              child: SvgPicture.asset(
                'assets/ru.svg',
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              MyApp.of(context)?.setLocale(Locale('en'));
              context.router.push(RoomAndLaminateParametersRoute());
            },
            child: Container(
              width: 100,
              height: 100,
              padding: EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.black12),
              child: SvgPicture.asset(
                'assets/gb.svg',
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
