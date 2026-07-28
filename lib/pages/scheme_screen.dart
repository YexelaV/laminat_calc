import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../cubit/calculate_cubit.dart';
import '../di/get_it.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../constants.dart';
import '../utils/units.dart';

class SchemeScreen extends StatelessWidget {
  final Result result;
  final int number;
  const SchemeScreen(this.result, this.number, {super.key});

  MeasurementSystem get system => getIt.get<CalculateCubit>().state.system;

  String sizeLabel(num mm) =>
      system == MeasurementSystem.imperial ? formatFeetInches(mm) : '$mm';

  List<Widget> drawFloor() {
    List<Widget> res = [];
    for (final line in result.lines) {
      List<Widget> children = [
        SizedBox(
          height: line.planks[0].width / 20,
          width: 24,
          child: FittedBox(
            child: Text(
              '${sizeLabel(line.planks[0].width)} ',
            ),
          ),
        ),
      ];
      for (final plank in line.planks) {
        children.add(Container(
          height: plank.width / 10,
          width: plank.length / 10,
          decoration: BoxDecoration(border: Border.all(color: Colors.black)),
          child: Row(
            children: [
              SizedBox(
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
              SizedBox(
                height: plank.width / 12,
                width: plank.length / 15 - 2,
                child: FittedBox(
                  alignment: Alignment.center,
                  child: plank.length < result.laminateLength
                      ? Text(
                          ' ${sizeLabel(plank.length)}',
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ));
      }
      res.add(Row(mainAxisAlignment: MainAxisAlignment.start, children: children));
    }
    return res;
  }

  Future<void> shareResult() async {
    double koefLength = min(MAX_LENGTH_MM / result.roomLength, MAX_WIDTH_MM / result.roomWidth);
    double koefWidth = koefLength;
    List<pw.Widget> pdfResult = [];
    for (final line in result.lines) {
      List<pw.Widget> pdfChildren = [
        pw.Container(
          height: line.planks[0].width / KOEF_COMPRESS * koefWidth * 0.5,
          width: 24,
          child: pw.FittedBox(
            child: pw.Text(
              '${sizeLabel(line.planks[0].width)} ',
            ),
          ),
        ),
      ];
      for (final plank in line.planks) {
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
                  child: plank.length < result.laminateLength
                      ? pw.Text(
                          ' ${sizeLabel(plank.length)}',
                        )
                      : pw.Container(),
                ),
              ),
            ],
          ),
        ));
      }
      pdfResult.add(pw.Row(mainAxisSize: pw.MainAxisSize.min, children: pdfChildren));
    }
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape,
        build: (pw.Context context) {
          final scheme = pw.Column(mainAxisSize: pw.MainAxisSize.min, children: pdfResult);
          if (result.direction == Direction.width) {
            // Rows run along the room width: rotate so the room keeps its
            // orientation (length horizontal, width vertical).
            return pw.Transform.rotateBox(angle: -pi / 2, child: scheme);
          }
          return scheme;
        }));
    final dir = await getApplicationDocumentsDirectory();
    final path = dir.path;
    final now = DateTime.now();
    final file = File('$path/laminat.pdf$now');
    await file.writeAsBytes(await pdf.save());
    final xFile = XFile(file.path, mimeType: 'application/pdf');
    await SharePlus.instance
        .share(ShareParams(files: [xFile], text: "scheme №$number"));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: drawFloor(),
    );
    return Scaffold(
        appBar: AppBar(
          title: Text("${AppStrings.of(context).laying_scheme} №$number",
              style: TextStyle(fontSize: 18, color: Colors.black)),
          leading: Padding(
            padding: EdgeInsets.only(left: 12),
            child: IconButton(
              icon: Icon(Icons.arrow_back, size: 24, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
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
                            child: result.direction == Direction.width
                                ? RotatedBox(quarterTurns: 1, child: scheme)
                                : scheme)))),
          ],
        ));
  }
}
