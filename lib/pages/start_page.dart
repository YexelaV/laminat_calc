import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
//import 'package:pdf/widgets.dart' ;
import 'package:shared_preferences/shared_preferences.dart';

import 'result_page.dart';
import '../localization.dart';
import '../calculate.dart';
import '../models.dart';
import '../constants.dart';

class StartPage extends StatefulWidget {
  StartPage({Key key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final controller = <TextEditingController>[];
  final focusNode = <FocusNode>[];
  final key = <GlobalKey<FormFieldState>>[];

  double roomLength;
  double roomWidth;
  int plankLength;
  int plankWidth;
  int planksInPack;
  double price;
  int indent;
  int minLength;
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
        AppLocalizations.preferredLocale = Locale(code);
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

  int minLengthMax() {
    if (roomLength == null || roomWidth == null || plankLength == null || rowOffset == null) {
      return 0;
    }
    final actualLength = (roomLength * 1000 - indent * 2).toInt();
    final actualWidth = (roomWidth * 1000 - indent * 2).toInt();
    // final rowLength = direction == Direction.length ? actualLength : actualWidth;
    final rowLength = actualLength;
    var currentLength = 0;
    while (currentLength + plankLength < rowLength) {
      currentLength += plankLength;
    }
    var lastPlankLength = rowLength - currentLength;
    var rowRemain = rowLength - currentLength + plankLength;
    if (lastPlankLength <= plankLength / 2) {
      return ((rowRemain - rowOffset) / 2).truncate();
    } else {
      return lastPlankLength - rowOffset;
    }
  }

  /* int rowOffsetMax() {
    if (roomLength == null || roomWidth == null || plankLength == null || minLength == null) {
      return 0;
    }
    final actualLength = (roomLength * 1000 - indent * 2).toInt();
    final actualWidth = (roomWidth * 1000 - indent * 2).toInt();
    // final rowLength = direction == Direction.length ? actualLength : actualWidth;
    final rowLength = actualLength;
    var currentLength = 0;
    while (currentLength + plankLength < rowLength) {
      currentLength += plankLength;
    }
    var rowRemain = rowLength - currentLength;
    return rowRemain - minLength;
  }*/

  bool minLengthValidatorDisabled() {
    return roomLength == null ||
        roomWidth == null ||
        plankLength == null ||
        indent == null ||
        rowOffset == null;
  }

  /* bool rowOffsetValidatorDisabled() {
    return roomLength == null ||
        roomWidth == null ||
        plankLength == null ||
        indent == null ||
        minLength == null;
  }*/

  String sizeValidator(String value, minValue, maxValue, String measure, {bool disabled = false}) {
    var result = emptyValidator(value);
    if (disabled || result != null) {
      return result;
    }
    if (measure == AppLocalizations.of(context).mm || measure == AppLocalizations.of(context).pcs) {
      try {
        int.parse(value);
      } catch (e) {
        return AppLocalizations.of(context).incorrect_value;
      }
    }
    if (result != null) {
      return result;
    }
    if (double.parse(value) > maxValue) {
      return ("${AppLocalizations.of(context).maximum} $maxValue $measure");
    }
    if (double.parse(value) < minValue) {
      return ("${AppLocalizations.of(context).minimum} $minValue $measure");
    }
    return null;
  }

  String emptyValidator(String value) {
    try {
      if (value.isEmpty) {
        return AppLocalizations.of(context).required_field;
      }
      if (double.parse(value) < 0) {
        return AppLocalizations.of(context).incorrect_value;
      }
      return null;
    } catch (e) {
      return AppLocalizations.of(context).incorrect_value;
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
                      titleText(AppLocalizations.of(context).room, Icons.home_filled),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: textFormField(
                            i,
                            (value) => sizeValidator(
                                value, MIN_LENGTH, MAX_LENGTH, AppLocalizations.of(context).m),
                            (String value) => roomLength = double.parse(value),
                            AppLocalizations.of(context).lenth_m,
                          )),
                          SizedBox(width: 40),
                          Expanded(
                              child: textFormField(
                            ++i,
                            (value) => sizeValidator(
                                value, MIN_WIDTH, MAX_WIDTH, AppLocalizations.of(context).m),
                            (String value) => roomWidth = double.parse(value),
                            AppLocalizations.of(context).width_m,
                          ))
                        ],
                      ),
                      SizedBox(height: 16),
                      titleText(
                          AppLocalizations.of(context).laminate, Icons.horizontal_split_sharp),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: textFormField(
                            ++i,
                            (value) => sizeValidator(value, MIN_PLANK_LENGTH, MAX_PLANK_LENGTH,
                                AppLocalizations.of(context).mm),
                            (String value) => plankLength = int.parse(value),
                            AppLocalizations.of(context).length_mm,
                          ),
                        ),
                        SizedBox(width: 40),
                        Expanded(
                          child: textFormField(
                            ++i,
                            (value) => sizeValidator(value, MIN_PLANK_WIDTH, MAX_PLANK_WIDTH,
                                AppLocalizations.of(context).mm),
                            (String value) => plankWidth = int.parse(value),
                            AppLocalizations.of(context).width_mm,
                          ),
                        ),
                      ]),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: textFormField(
                            ++i,
                            (value) => sizeValidator(value, MIN_ITEMS_IN_PACK, MAX_ITEMS_IN_PACK,
                                AppLocalizations.of(context).pcs),
                            (String value) => planksInPack = int.parse(value),
                            AppLocalizations.of(context).pieces_per_package,
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
                      titleText(AppLocalizations.of(context).laying, Icons.branding_watermark),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                              ++i,
                              (value) => sizeValidator(
                                  value, 0, MAX_INDENT, AppLocalizations.of(context).mm),
                              (String value) => indent = int.parse(value),
                              AppLocalizations.of(context).expansion_gap_mm,
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
                                    (plankLength ?? 0 / 2).floor(), AppLocalizations.of(context).mm,
                                    disabled: plankLength == null),
                                (String value) => rowOffset = int.parse(value),
                                AppLocalizations.of(context).joint_offset_mm),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                              ++i,
                              (value) => sizeValidator(value, MIN_MIN_LENGTH, minLengthMax(),
                                  AppLocalizations.of(context).mm,
                                  disabled: minLengthValidatorDisabled()),
                              (String value) => minLength = int.parse(value),
                              AppLocalizations.of(context).minimal_piece_length,
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
                                AppLocalizations.of(context).calculate,
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
                                plankLength: plankLength,
                                plankWidth: plankWidth,
                                planksInPack: planksInPack,
                                price: price,
                                indent: indent,
                                minLength: minLength,
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
              AppLocalizations.of(context).language,
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
                        AppLocalizations.of(context).english,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )),
                  onPressed: () {
                    AppLocalizations.preferredLocale = Locale('en');
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
                        AppLocalizations.of(context).russian,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )),
                  onPressed: () {
                    AppLocalizations.preferredLocale = Locale('ru');
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
      if (AppLocalizations.preferredLocale == null && showSettingsScreen) {
        SchedulerBinding.instance.addPostFrameCallback((_) async {
          await showSettings();
        });
      }
      return Scaffold(
        appBar: AppBar(
            title: Text(AppLocalizations.of(context).title,
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
}
