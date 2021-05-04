import 'package:flutter/material.dart';
import 'calculate.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Калькулятор ламината'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
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

class _MyHomePageState extends State<MyHomePage> {
  final roomLengthController = TextEditingController();
  final roomWidthController = TextEditingController();
  final plankLengthController = TextEditingController();
  final plankWidthController = TextEditingController();
  final planksInPackController = TextEditingController();
  final priceController = TextEditingController();
  final indentController = TextEditingController();
  final rowOffsetController = TextEditingController();
  final minLengthController = TextEditingController();

  final roomLengthFocusNode = FocusNode();
  final roomWidthFocusNode = FocusNode();
  final plankLengthFocusNode = FocusNode();
  final plankWidthFocusNode = FocusNode();
  final planksInPackFocusNode = FocusNode();
  final priceFocusNode = FocusNode();
  final indentFocusNode = FocusNode();
  final rowOffsetFocusNode = FocusNode();
  final minLengthFocusNode = FocusNode();

  final roomLengthKey = GlobalKey<FormFieldState>();
  final roomWidthKey = GlobalKey<FormFieldState>();
  final plankLengthKey = GlobalKey<FormFieldState>();
  final plankWidthKey = GlobalKey<FormFieldState>();
  final planksInPackKey = GlobalKey<FormFieldState>();
  final priceKey = GlobalKey<FormFieldState>();
  final indentKey = GlobalKey<FormFieldState>();
  final rowOffsetKey = GlobalKey<FormFieldState>();
  final minLengthKey = GlobalKey<FormFieldState>();

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

  Widget textFormField(GlobalKey<FormFieldState> key, FocusNode focusNode, FocusNode nextFocusNode,
      TextEditingController controller, Function validator, Function callback, String labelText,
      {bool isLast = false}) {
    return TextFormField(
      key: key,
      focusNode: focusNode,
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
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      validator: (value) => validator(value),
      onChanged: (value) {
        if (key.currentState.validate()) {
          callback(value);
        }
      },
      onFieldSubmitted: (value) {
        if (key.currentState.validate()) {
          callback(value);
        }
        if (!isLast) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
    );
  }

  String emptyValidator(String value) {
    if (value.isEmpty) {
      return "Обязательное поле";
    }
    if (double.parse(value.toDouble()) < 0) {
      return "Некорректное значение";
    }
    return null;
  }

  Widget parametersScreen() {
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
                            roomLengthKey,
                            roomLengthFocusNode,
                            roomWidthFocusNode,
                            roomLengthController,
                            emptyValidator,
                            (String value) => roomLength = double.parse(value.toDouble()),
                            "Длина (м)",
                          )),
                          SizedBox(width: 40),
                          Expanded(
                              child: textFormField(
                            roomWidthKey,
                            roomWidthFocusNode,
                            plankLengthFocusNode,
                            roomWidthController,
                            emptyValidator,
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
                              plankLengthKey,
                              plankLengthFocusNode,
                              plankWidthFocusNode,
                              plankLengthController,
                              emptyValidator,
                              (String value) => plankLength = int.parse(value),
                              "Длина (мм)"),
                        ),
                        SizedBox(width: 40),
                        Expanded(
                          child: textFormField(
                              plankWidthKey,
                              plankWidthFocusNode,
                              planksInPackFocusNode,
                              plankWidthController,
                              emptyValidator,
                              (String value) => plankWidth = int.parse(value),
                              "Ширина (мм)"),
                        ),
                      ]),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: textFormField(
                              planksInPackKey,
                              planksInPackFocusNode,
                              priceFocusNode,
                              planksInPackController,
                              emptyValidator,
                              (String value) => planksInPack = int.parse(value),
                              "В упаковке (шт)"),
                        ),
                        SizedBox(width: 40),
                        Expanded(
                          child: textFormField(
                              priceKey,
                              priceFocusNode,
                              indentFocusNode,
                              priceController,
                              emptyValidator,
                              (String value) => price = double.parse(value.toDouble()),
                              "Цена (руб/уп)"),
                        ),
                      ]),
                      SizedBox(height: 16),
                      titleText("Укладка", Icons.branding_watermark),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                                indentKey,
                                indentFocusNode,
                                rowOffsetFocusNode,
                                indentController,
                                emptyValidator,
                                (String value) => indent = int.parse(value),
                                "Отступ от стен (мм)"),
                          ),
                          //    SizedBox(width: MediaQuery.of(context).size.width / 2 - 40),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                                rowOffsetKey,
                                rowOffsetFocusNode,
                                minLengthFocusNode,
                                rowOffsetController,
                                emptyValidator,
                                (String value) => rowOffset = int.parse(value),
                                "Cмещение рядов (мм)"),
                          ),
                          //      SizedBox(width: MediaQuery.of(context).size.width / 2 - 40),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textFormField(
                                minLengthKey,
                                minLengthFocusNode,
                                null,
                                minLengthController,
                                emptyValidator,
                                (String value) => minLength = int.parse(value),
                                "Минимальная длина доски (мм)"),
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
                              builder: (context) => Draw(res),
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
  Draw(this.lines);

  List<Widget> drawFloor() {
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
              '${plank.number}  ${plank.length}x${plank.width}',
              //   style: TextStyle(fontSize: 12),
            ),
          ),
        ));
        pdfChildren.add(pw.Container(
          alignment: pw.Alignment.center,
          height: plank.width / 10,
          width: plank.length / 10,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.FittedBox(
            child: pw.Text(
              '${plank.number}  ${plank.length}x${plank.width}',
              //   style: TextStyle(fontSize: 12),
            ),
          ),
        ));
      }));
      result.add(Row(mainAxisAlignment: MainAxisAlignment.start, children: children));
      pdfResult.add(pw.Row(children: pdfChildren));
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
                    return pw.Column(children: pdfResult);
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
