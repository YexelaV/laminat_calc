import 'package:flutter/material.dart';
import 'calculate.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';

const MIN_LENGTH = 1;
const MAX_LENGTH = 25; //m
const MIN_WIDTH = 1;
const MAX_WIDTH = 16; //m
const MIN_PLANK_LENGTH = 300; //mm
const MAX_PLANK_LENGTH = 2000; //mm
const MIN_PLANK_WIDTH = 90; //mm;
const MAX_PLANK_WIDTH = 500; //mm;
const KOEF_COMPRESS = 35;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartPage(title: 'Калькулятор ламината'),
    );
  }
}

class StartPage extends StatefulWidget {
  StartPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _StartPageState createState() => _StartPageState();
}

enum Direction { length, width }

class Plank {
  int number;
  int length;
  int width;
  Plank(this.number, this.length, this.width);
}

class Line {
  int number;
  List<Plank> planks;
  Line(this.number, this.planks);
}

extension StringExt on String {
  String toDouble() {
    return this.replaceAll(',', '.');
  }
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
    for (int i = 0; i < 10; i++) {
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

  String sizeValidator(String value, int minValue, int maxValue) {
    var result = emptyValidator(value);
    if (result != null) {
      return result;
    }
    if (double.parse(value.toDouble()) > maxValue) {
      return ("Не более $maxValue м");
    }
    if (double.parse(value.toDouble()) < minValue) {
      return ("Не менее $minValue м");
    }
    return null;
  }

  String emptyValidator(String value) {
    try {
      if (value.isEmpty) {
        return "Обязательное поле";
      }
      if (double.parse(value.toDouble()) < 0) {
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
            constraints: BoxConstraints(minHeight: height),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/floor.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 48),
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
                        "Калькулятор ламината",
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(height: 16),
                      titleText("Помещение", Icons.home_filled),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: textFormField(
                            i,
                            (value) => sizeValidator(value, MIN_LENGTH, MAX_LENGTH),
                            (String value) => roomLength = double.parse(value.toDouble()),
                            "Длина (м)",
                          )),
                          SizedBox(width: 40),
                          Expanded(
                              child: textFormField(
                            ++i,
                            (value) => sizeValidator(value, MIN_WIDTH, MAX_WIDTH),
                            (String value) => roomWidth = double.parse(value.toDouble()),
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
                            (value) => sizeValidator(value, MIN_PLANK_LENGTH, MAX_PLANK_LENGTH),
                            (String value) => plankLength = int.parse(value),
                            "Длина (мм)",
                          ),
                        ),
                        SizedBox(width: 40),
                        Expanded(
                          child: textFormField(
                            ++i,
                            (value) => sizeValidator(value, MIN_PLANK_WIDTH, MAX_PLANK_WIDTH),
                            (String value) => plankWidth = int.parse(value),
                            "Ширина (мм)",
                          ),
                        ),
                      ]),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: textFormField(
                            ++i,
                            emptyValidator,
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
                            child: textFormField(++i, emptyValidator,
                                (String value) => indent = int.parse(value), "Отступ от стен (мм)"),
                          ),
                          //    SizedBox(width: MediaQuery.of(context).size.width / 2 - 40),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                                ++i,
                                emptyValidator,
                                (String value) => rowOffset = int.parse(value),
                                "Cмещение рядов, не менее (мм)"),
                          ),
                          //      SizedBox(width: MediaQuery.of(context).size.width / 2 - 40),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                              ++i,
                              emptyValidator,
                              (String value) => minLength = int.parse(value),
                              "Минимальная длина доски (мм)",
                              isLast: true,
                            ),
                          ),
                          //      SizedBox(width: MediaQuery.of(context).size.width / 2 - 40),
                        ],
                      ),
                      SizedBox(height: 20),
                      TextButton(
                          child: Container(
                              alignment: Alignment.center,
                              width: 80,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.blue,
                              ),
                              child: Text(
                                "расчет",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              )),
                          onPressed: () {
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
                            var res = calculation.calculate();

                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => Draw(res, roomLength, roomWidth),
                            ));
                          })
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        //   ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: parametersScreen(),
    );
  }
}

class Draw extends StatelessWidget {
  final List<Line> lines;
  final double length;
  final double width;
  Draw(this.lines, this.length, this.width);

  List<Widget> drawFloor() {
    double koefLength = MAX_LENGTH / length;
    double koefWidth = MAX_WIDTH / width;
    List<Widget> result = [];
    List<pw.Widget> pdfResult = [];
    lines.forEach((line) {
      List<Widget> children = [];
      List<pw.Widget> pdfChildren = [];
      line.planks.forEach(((plank) {
        children.add(Container(
          alignment: Alignment.center,
          height: plank.width / 5,
          width: plank.length / 5,
          decoration: BoxDecoration(border: Border.all(color: Colors.black)),
          child: FittedBox(
            child: Text(
              ' ${plank.number}  ${plank.length}x${plank.width} ',
              //   style: TextStyle(fontSize: 12),
            ),
          ),
        ));
        pdfChildren.add(pw.Container(
          alignment: pw.Alignment.center,
          height: plank.width / KOEF_COMPRESS * koefWidth,
          width: plank.length / KOEF_COMPRESS * koefLength,
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          child: pw.FittedBox(
            child: pw.Text(
              ' ${plank.number}  ${plank.length}x${plank.width} ',
              //   style: TextStyle(fontSize: 12),
            ),
          ),
        ));
      }));
      result.add(Row(mainAxisAlignment: MainAxisAlignment.start, children: children));
      pdfResult.add(pw.Row(mainAxisSize: pw.MainAxisSize.min, children: pdfChildren));
    });
    result.add(Row(
      children: [
        TextButton(
            child: Container(
                alignment: Alignment.center,
                width: 80,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.blue,
                ),
                child: Text(
                  "экспорт",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                )),
            onPressed: () async {
              final pdf = pw.Document();
              pdf.addPage(pw.Page(
                  pageFormat: PdfPageFormat.a4,
                  orientation: pw.PageOrientation.landscape,
                  build: (pw.Context context) {
                    return pw.Column(mainAxisSize: pw.MainAxisSize.min, children: pdfResult);
                  }));
              //     FileStorage fileStorage;
              //
              //
              final dir = await getApplicationDocumentsDirectory();
              final path = dir.path;
              final file = File('$path/laminat.pdf');
              await file.writeAsBytes(await pdf.save());
              final bytes = await file.readAsBytes();
              await Share.file("laminat", "laminat.pdf", bytes, 'application/pdf');
            })
      ],
    ));
    return result;
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: null,
        body: InteractiveViewer(
            constrained: false,
            minScale: 0.1,
            //      scrollDirection: Axis.horizontal,
            child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: drawFloor(),
                ))));
  }
}
