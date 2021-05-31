import 'dart:math';
import 'package:floor_calculator/pages/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

  @override
  void initState() {
    for (int i = 0; i < 8; i++) {
      controller.add(TextEditingController());
      focusNode.add(FocusNode());
      key.add(GlobalKey<FormFieldState>());
    }
    super.initState();
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

  String sizeValidator(String value, int minValue, int maxValue, String measure,
      {bool disabled = false}) {
    var result = emptyValidator(value);
    if (disabled || result != null) {
      return result;
    }
    if (measure == 'мм' || measure == 'шт') {
      try {
        int.parse(value);
      } catch (e) {
        return "Некорректное значение";
      }
    }
    if (result != null) {
      return result;
    }
    if (double.parse(value) > maxValue) {
      return ("Не более $maxValue $measure");
    }
    if (double.parse(value) < minValue) {
      return ("Не менее $minValue $measure");
    }
    return null;
  }

  String emptyValidator(String value) {
    try {
      if (value.isEmpty) {
        return "Обязательное поле";
      }
      if (double.parse(value) < 0) {
        return "Некорректное значение";
      }
      return null;
    } catch (e) {
      return "Некорректное значение";
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
                      titleText("Помещение", Icons.home_filled),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: textFormField(
                            i,
                            (value) => sizeValidator(value, MIN_LENGTH, MAX_LENGTH, 'м'),
                            (String value) => roomLength = double.parse(value),
                            "Длина (м)",
                          )),
                          SizedBox(width: 40),
                          Expanded(
                              child: textFormField(
                            ++i,
                            (value) => sizeValidator(value, MIN_WIDTH, MAX_WIDTH, 'м'),
                            (String value) => roomWidth = double.parse(value),
                            "Ширина (м)",
                          ))
                        ],
                      ),
                      SizedBox(height: 16),
                      titleText("Ламинат", Icons.horizontal_split_sharp),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: textFormField(
                            ++i,
                            (value) =>
                                sizeValidator(value, MIN_PLANK_LENGTH, MAX_PLANK_LENGTH, 'мм'),
                            (String value) => plankLength = int.parse(value),
                            "Длина (мм)",
                          ),
                        ),
                        SizedBox(width: 40),
                        Expanded(
                          child: textFormField(
                            ++i,
                            (value) => sizeValidator(value, MIN_PLANK_WIDTH, MAX_PLANK_WIDTH, 'мм'),
                            (String value) => plankWidth = int.parse(value),
                            "Ширина (мм)",
                          ),
                        ),
                      ]),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: textFormField(
                            ++i,
                            (value) =>
                                sizeValidator(value, MIN_ITEMS_IN_PACK, MAX_ITEMS_IN_PACK, 'шт'),
                            (String value) => planksInPack = int.parse(value),
                            "В упаковке (шт)",
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
                      titleText("Укладка", Icons.branding_watermark),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                              ++i,
                              (value) => sizeValidator(value, 0, MAX_INDENT, 'мм'),
                              (String value) => indent = int.parse(value),
                              "Отступ от стен (мм)",
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
                                (value) => sizeValidator(
                                    value, MIN_ROW_OFFSET, (plankLength ?? 0 / 2).floor(), 'мм',
                                    disabled: plankLength == null),
                                (String value) => rowOffset = int.parse(value),
                                "Cмещение рядов, (мм)"),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                              ++i,
                              (value) => sizeValidator(value, MIN_MIN_LENGTH, minLengthMax(), 'мм',
                                  disabled: minLengthValidatorDisabled()),
                              (String value) => minLength = int.parse(value),
                              "Минимальная длина доски (мм)",
                              isLast: true,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
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
                                "расчет",
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

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height - 80;
    return Scaffold(
      appBar: AppBar(
        title: Text("Калькулятор ламината", style: TextStyle(fontSize: 18, color: Colors.black)),
        leading: null,
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: parametersScreen(),
    );
  }
}
