import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import '../models.dart';
import '../constants.dart';

class SchemePage extends StatelessWidget {
  final Result result;
  final int number;
  SchemePage(this.result, this.number);

  List<Widget> drawFloor() {
    List<Widget> res = [];
    result.lines.forEach((line) {
      List<Widget> children = [
        Container(
          height: line.planks[0].width / 20,
          width: 24,
          child: FittedBox(
            child: Text(
              '${line.planks[0].width} ',
            ),
          ),
        ),
      ];
      line.planks.forEach(((plank) {
        children.add(Container(
          height: plank.width / 10,
          width: plank.length / 10,
          decoration: BoxDecoration(border: Border.all(color: Colors.black)),
          child: Row(
            children: [
              Container(
                height: plank.width / 12,
                width: plank.length / 30,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ' ${plank.number}',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Container(
                height: plank.width / 12,
                width: plank.length / 15 - 2,
                child: FittedBox(
                  alignment: Alignment.center,
                  child: plank.length < result.plankLength
                      ? Text(
                          ' ${plank.length}',
                        )
                      : Container(),
                ),
              ),
            ],
          ),
        ));
      }));
      res.add(Row(mainAxisAlignment: MainAxisAlignment.start, children: children));
    });
    return res;
  }

  Future<void> shareResult() async {
    double koefLength = min(MAX_LENGTH / result.roomLength, MAX_WIDTH / result.roomWidth);
    double koefWidth = koefLength;
    List<pw.Widget> pdfResult = [];
    result.lines.forEach((line) {
      List<pw.Widget> pdfChildren = [
        pw.Container(
          height: line.planks[0].width / KOEF_COMPRESS * koefWidth * 0.5,
          width: 24,
          child: pw.FittedBox(
            child: pw.Text(
              '${line.planks[0].width} ',
            ),
          ),
        ),
      ];
      line.planks.forEach(((plank) {
        pdfChildren.add(pw.Container(
          height: plank.width / KOEF_COMPRESS * koefWidth,
          width: plank.length / KOEF_COMPRESS * koefLength,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Row(
            children: [
              pw.Container(
                height: plank.width / KOEF_COMPRESS * koefWidth * 0.8,
                width: plank.length / KOEF_COMPRESS * koefLength * 0.33,
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
                width: plank.length / KOEF_COMPRESS * koefLength * 0.67 - 2,
                child: pw.FittedBox(
                  alignment: pw.Alignment.center,
                  child: plank.length < result.plankLength
                      ? pw.Text(
                          ' ${plank.length}',
                        )
                      : pw.Container(),
                ),
              ),
            ],
          ),
        ));
      }));
      pdfResult.add(pw.Row(mainAxisSize: pw.MainAxisSize.min, children: pdfChildren));
    });
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape,
        build: (pw.Context context) {
          return pw.Column(mainAxisSize: pw.MainAxisSize.min, children: pdfResult);
        }));
    final dir = await getApplicationDocumentsDirectory();
    final path = dir.path;
    final now = DateTime.now();
    final file = File('$path/laminat.pdf$now');
    await file.writeAsBytes(await pdf.save());
    final bytes = await file.readAsBytes();
    await Share.file("scheme №$number", "scheme№$number.pdf", bytes, 'application/pdf');
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title:
              Text("Cхема укладки №$number", style: TextStyle(fontSize: 18, color: Colors.black)),
          leading: Padding(
            padding: EdgeInsets.only(left: 12),
            child: IconButton(
              icon: Icon(Icons.arrow_back, size: 24, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          //   elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: IconButton(
                  icon: Icon(Icons.share_rounded, size: 24, color: Colors.black),
                  onPressed: () async => await shareResult()),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
                color: Colors.white,
                child: InteractiveViewer(
                    constrained: false,
                    minScale: 0.1,
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(40, 40, 40, 40),
                        child: Container(
                            //    decoration: BoxDecoration(
                            //      color: Colors.black.withOpacity(0.05),
                            //    borderRadius: BorderRadius.circular(20)),
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: drawFloor(),
                        ))))),
          ],
        ));
  }
}
