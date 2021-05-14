import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import '../models.dart';
import '../constants.dart';

class SchemePage extends StatelessWidget {
  final List<Line> lines;
  final double length;
  final double width;
  final int plankLength;
  final int plankWidth;
  SchemePage(this.lines, this.length, this.width, this.plankLength, this.plankWidth);

  List<Widget> drawFloor() {
    double koefLength = MAX_LENGTH / length;
    double koefWidth = MAX_WIDTH / width;
    List<Widget> result = [];
    List<pw.Widget> pdfResult = [];
    lines.forEach((line) {
      List<Widget> children = [
        Container(
          height: line.planks[0].width / 10,
          child: FittedBox(
            child: Text(
              '${line.planks[0].width} ',
            ),
          ),
        ),
      ];
      List<pw.Widget> pdfChildren = [
        pw.Container(
          height: line.planks[0].width / KOEF_COMPRESS * koefWidth * 0.8,
          child: pw.FittedBox(
            child: pw.Text(
              '${line.planks[0].width} ',
            ),
          ),
        ),
      ];
      line.planks.forEach(((plank) {
        children.add(Container(
          //   alignment: Alignment.centerLeft,
          height: plank.width / 5,
          width: plank.length / 5,
          decoration: BoxDecoration(border: Border.all(color: Colors.black)),
          child: Row(
            children: [
              Container(
                height: plank.width / 6,
                width: plank.length / 15,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ' ${plank.number}',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Container(
                height: plank.width / 6,
                width: plank.length * 2 / 15 - 2,
                child: FittedBox(
                  alignment: Alignment.center,
                  child: plank.length < plankLength
                      ? Text(
                          ' ${plank.length}',
                          //   style: TextStyle(fontSize: 12),
                        )
                      : Container(),
                ),
              ),
            ],
          ),
        ));
      }));
      line.planks.forEach(((plank) {
        pdfChildren.add(pw.Container(
          //   alignment: Alignment.centerLeft,
          height: plank.width / KOEF_COMPRESS * koefWidth,
          width: plank.length / KOEF_COMPRESS * koefLength,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Row(
            children: [
              pw.Container(
                height: plank.width / KOEF_COMPRESS * koefWidth * 0.8,
                width: plank.length / KOEF_COMPRESS * koefWidth * 0.33,
                child: pw.FittedBox(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    ' ${plank.number}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.Container(
                height: plank.width / KOEF_COMPRESS * koefWidth * 0.8,
                width: plank.length / KOEF_COMPRESS * koefWidth * 0.67 - 2,
                child: pw.FittedBox(
                  alignment: pw.Alignment.center,
                  child: plank.length < plankLength
                      ? pw.Text(
                          ' ${plank.length}',
                          //   style: TextStyle(fontSize: 12),
                        )
                      : pw.Container(),
                ),
              ),
            ],
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
            child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: drawFloor(),
                ))));
  }
}
