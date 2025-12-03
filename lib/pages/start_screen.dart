import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/main.dart';
import 'package:floor_calculator/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

//import 'result_page.dart';
//import '../localization.dart';
//import '../calculate.dart';
//import '../models.dart';
//import '../constants.dart';

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
/*class _StartScreenState extends State<StartScreen> {
  final controller = <TextEditingController>[];
  final focusNode = <FocusNode>[];
  final key = <GlobalKey<FormFieldState>>[];

  double roomLength;
  double roomWidth;
  int laminateLength;
  int laminateWidth;
  int planksInPack;
  double price;
  int indentFromWall;
  int minimumLaminateLength;
  int rowOffset;
  Direction direction;

  double height;
  bool settingsLoaded = false;
  bool showSettingsScreen = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final code = prefs.getString('countryCode');
      if (code != null) {
        AppStrings.preferredLocale = Locale(code);
      } else {
        showSettingsScreen = true;
      }
      settingsLoaded = true;
      setState(() {});
    });
    for (int i = 0; i < 8; i++) {
      controller.add(TextEditingController());
      focusNode.add(FocusNode());
      key.add(GlobalKey<FormFieldState>());
    }
  }

  Widget titleText(String title, IconData icon) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 20).copyWith(color: Colors.blue)),
        SizedBox(width: 8),
        Icon(
          icon,
          size: 20,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget simpleText(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 20),
    );
  }

  Widget textFormField(int index, Function validator, Function callback, String labelText,
      {bool isLast = false}) {
    return TextFormField(
      key: key[index],
      focusNode: focusNode[index],
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 4),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black.withOpacity(0.8), width: 1),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black.withOpacity(0.8), width: 0.5),
        ),
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 16),
      ),
      controller: controller[index],
      keyboardType: TextInputType.number,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      validator: (value) => validator(value),
      onChanged: (value) {
        if (key[index].currentState.validate()) {
          callback(value);
        }
      },
      onFieldSubmitted: (value) {
        if (key[index].currentState.validate()) {
          callback(value);
        }
        if (!isLast) {
          FocusScope.of(context).requestFocus(focusNode[index + 1]);
        }
      },
    );
  }

  int minimumLaminateLengthMax() {
    if (roomLength == null || roomWidth == null || laminateLength == null || rowOffset == null) {
      return 0;
    }
    final actualLength = (roomLength * 1000 - indentFromWall * 2).toInt();
    final actualWidth = (roomWidth * 1000 - indentFromWall * 2).toInt();
    // final rowLength = direction == Direction.length ? actualLength : actualWidth;
    final rowLength = actualLength;
    var currentLength = 0;
    while (currentLength + laminateLength < rowLength) {
      currentLength += laminateLength;
    }
    var lastlaminateLength = rowLength - currentLength;
    var rowRemain = rowLength - currentLength + laminateLength;
    if (lastlaminateLength <= laminateLength / 2) {
      return ((rowRemain - rowOffset) / 2).truncate();
    } else {
      return lastlaminateLength - rowOffset;
    }
  }

  /* int rowOffsetMax() {
    if (roomLength == null || roomWidth == null || laminateLength == null || minimumLaminateLength == null) {
      return 0;
    }
    final actualLength = (roomLength * 1000 - indentFromWall * 2).toInt();
    final actualWidth = (roomWidth * 1000 - indentFromWall * 2).toInt();
    // final rowLength = direction == Direction.length ? actualLength : actualWidth;
    final rowLength = actualLength;
    var currentLength = 0;
    while (currentLength + laminateLength < rowLength) {
      currentLength += laminateLength;
    }
    var rowRemain = rowLength - currentLength;
    return rowRemain - minimumLaminateLength;
  }*/

  bool minimumLaminateLengthValidatorDisabled() {
    return roomLength == null ||
        roomWidth == null ||
        laminateLength == null ||
        indentFromWall == null ||
        rowOffset == null;
  }

  /* bool rowOffsetValidatorDisabled() {
    return roomLength == null ||
        roomWidth == null ||
        laminateLength == null ||
        indentFromWall == null ||
        minimumLaminateLength == null;
  }*/

  String sizeValidator(String value, minValue, maxValue, String measure, {bool disabled = false}) {
    var result = emptyValidator(value);
    if (disabled || result != null) {
      return result;
    }
    if (measure == AppStrings.of(context).mm || measure == AppStrings.of(context).pcs) {
      try {
        int.parse(value);
      } catch (e) {
        return AppStrings.of(context).incorrect_value;
      }
    }
    if (result != null) {
      return result;
    }
    if (double.parse(value) > maxValue) {
      return ("${AppStrings.of(context).maximum} $maxValue $measure");
    }
    if (double.parse(value) < minValue) {
      return ("${AppStrings.of(context).minimum} $minValue $measure");
    }
    return null;
  }

  String emptyValidator(String value) {
    try {
      if (value.isEmpty) {
        return AppStrings.of(context).required_field;
      }
      if (double.parse(value) < 0) {
        return AppStrings.of(context).incorrect_value;
      }
      return null;
    } catch (e) {
      return AppStrings.of(context).incorrect_value;
    }
  }

  Widget parametersScreen() {
    var i = 0;
    return Stack(
      children: [
        SingleChildScrollView(
          child: Container(
            //    color: Colors.white,
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: 60),
              child: Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      titleText(AppStrings.of(context).room, Icons.home_filled),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: textFormField(
                            i,
                            (value) => sizeValidator(
                                value, MIN_LENGTH, MAX_LENGTH, AppStrings.of(context).m),
                            (String value) => roomLength = double.parse(value),
                            AppStrings.of(context).lenth_m,
                          )),
                          SizedBox(width: 40),
                          Expanded(
                              child: textFormField(
                            ++i,
                            (value) => sizeValidator(
                                value, MIN_WIDTH, MAX_WIDTH, AppStrings.of(context).m),
                            (String value) => roomWidth = double.parse(value),
                            AppStrings.of(context).width_m,
                          ))
                        ],
                      ),
                      SizedBox(height: 16),
                      titleText(
                          AppStrings.of(context).laminate, Icons.horizontal_split_sharp),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: textFormField(
                            ++i,
                            (value) => sizeValidator(value, MIN_PLANK_LENGTH, MAX_PLANK_LENGTH,
                                AppStrings.of(context).mm),
                            (String value) => laminateLength = int.parse(value),
                            AppStrings.of(context).length_mm,
                          ),
                        ),
                        SizedBox(width: 40),
                        Expanded(
                          child: textFormField(
                            ++i,
                            (value) => sizeValidator(value, MIN_PLANK_WIDTH, MAX_PLANK_WIDTH,
                                AppStrings.of(context).mm),
                            (String value) => laminateWidth = int.parse(value),
                            AppStrings.of(context).width_mm,
                          ),
                        ),
                      ]),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: textFormField(
                            ++i,
                            (value) => sizeValidator(value, MIN_ITEMS_IN_PACK, MAX_ITEMS_IN_PACK,
                                AppStrings.of(context).pcs),
                            (String value) => planksInPack = int.parse(value),
                            AppStrings.of(context).pieces_per_package,
                          ),
                        ),
                        //  SizedBox(width: 40),
                        /*          Expanded(
                            child: textFormField(
                                ++i,
                                emptyValidator,
                                (String value) => price = double.parse(value.toDouble()),
                                "Цена (руб/уп)"),
                          ),*/
                      ]),
                      SizedBox(height: 16),
                      titleText(AppStrings.of(context).laying, Icons.branding_watermark),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                              ++i,
                              (value) => sizeValidator(
                                  value, 0, MAX_indentFromWall, AppStrings.of(context).mm),
                              (String value) => indentFromWall = int.parse(value),
                              AppStrings.of(context).expansion_gap_mm,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                                ++i,
                                (value) => sizeValidator(value, MIN_ROW_OFFSET,
                                    (laminateLength ?? 0 / 2).floor(), AppStrings.of(context).mm,
                                    disabled: laminateLength == null),
                                (String value) => rowOffset = int.parse(value),
                                AppStrings.of(context).joint_offset_mm),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                              ++i,
                              (value) => sizeValidator(value, MIN_MIN_LENGTH, minimumLaminateLengthMax(),
                                  AppStrings.of(context).mm,
                                  disabled: minimumLaminateLengthValidatorDisabled()),
                              (String value) => minimumLaminateLength = int.parse(value),
                              AppStrings.of(context).minimal_piece_length,
                              isLast: true,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      TextButton(
                          child: Container(
                              alignment: Alignment.center,
                              width: 140,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.blue,
                              ),
                              child: Text(
                                AppStrings.of(context).calculate,
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              )),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            var validate = true;
                            for (int i = 0; i < key.length; i++) {
                              validate &= key[i].currentState.validate();
                            }

                            if (validate) {
                              Calculation calculation = Calculation(
                                roomLength: roomLength,
                                roomWidth: roomWidth,
                                laminateLength: laminateLength,
                                laminateWidth: laminateWidth,
                                planksInPack: planksInPack,
                                price: price,
                                indentFromWall: indentFromWall,
                                minimumLaminateLength: minimumLaminateLength,
                                rowOffset: rowOffset,
                                direction: Direction.length,
                              );
                              final result = calculation.calculate();

                              Navigator.of(context).push(
                                  CupertinoPageRoute(builder: (context) => ResultPage(result)));
                            }
                          })
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> showSettings() async {
    await showDialog(
        context: context,
        builder: (buildContext) {
          return SimpleDialog(
            title: Text(
              AppStrings.of(context).language,
              style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 18),
              textAlign: TextAlign.center,
            ),
            titlePadding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            children: [
              TextButton(
                  child: Container(
                      alignment: Alignment.center,
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.blue,
                      ),
                      child: Text(
                        AppStrings.of(context).english,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )),
                  onPressed: () {
                    AppStrings.preferredLocale = Locale('en');
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setString('countryCode', 'en');
                    });
                    Navigator.of(context).pop();
                    setState(() {});
                  }),
              TextButton(
                  child: Container(
                      alignment: Alignment.center,
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.blue,
                      ),
                      child: Text(
                        AppStrings.of(context).russian,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )),
                  onPressed: () {
                    AppStrings.preferredLocale = Locale('ru');
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setString('countryCode', 'ru');
                    });
                    Navigator.of(context).pop();
                    setState(() {});
                  }),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height - 80;
    if (settingsLoaded) {
      if (AppStrings.preferredLocale == null && showSettingsScreen) {
        SchedulerBinding.instance.addPostFrameCallback((_) async {
          await showSettings();
        });
      }
      return Scaffold(
        appBar: AppBar(
            title: Text(AppStrings.of(context).title,
                style: TextStyle(fontSize: 18, color: Colors.black)),
            leading: null,
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 20),
                child: IconButton(
                  icon: Icon(Icons.settings, size: 24, color: Colors.black),
                  onPressed: () => showSettings(),
                ),
              ),
            ]),
        body: parametersScreen(),
      );
    } else {
      return Container(
        color: Colors.white,
      );
    }
  }
}*/
