import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../cubit/calculate_cubit.dart';
import '../di/get_it.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../scheme_geometry.dart';
import '../scheme_pdf.dart';
import '../utils/cut_list.dart';
import '../utils/units.dart';
import '../widgets/cut_list_sheet.dart';
import '../widgets/scheme_painter.dart';

class SchemeScreen extends StatefulWidget {
  final Result result;
  final int number;
  const SchemeScreen(this.result, this.number, {super.key});

  @override
  State<SchemeScreen> createState() => _SchemeScreenState();
}

class _SchemeScreenState extends State<SchemeScreen> {
  Result get result => widget.result;
  int get number => widget.number;

  MeasurementSystem get system => getIt.get<CalculateCubit>().state.system;

  // How far the user can zoom in past the scale the scheme opens at.
  static const double _maxZoom = 12;

  // The shortest a row may be drawn, in logical pixels. A real room does not
  // fit on a phone at a legible size, so the scheme is not squeezed onto the
  // screen: it is drawn big enough to read and panned. Only a room small
  // enough to fit at this scale opens whole.
  static const double _minRowPx = 18;

  // Anything under this is not a label but a smudge, and the ladder in
  // buildScheme drops it. Millimetres of room: the smallest text the screen can
  // show is a pixel, and the user can magnify by _maxZoom before that binds.
  static const double _minTextMm = 3;

  // Turning the phone puts the long side of a wide drawing along the long side
  // of the display, which is the difference between reading the whole scheme and
  // dragging it past the edge. Whether that helps depends on how the fitter is
  // working, not on anything the app can measure, so the turn is offered rather
  // than taken. Off means the device decides, as it does everywhere else.
  bool _landscape = false;

  void _toggleLandscape() {
    setState(() => _landscape = !_landscape);
    SystemChrome.setPreferredOrientations(_landscape
        ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : DeviceOrientation.values);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> shareResult(String caption, List<String> cutList) async {
    final pdf = schemePdf(result, system, await PdfFonts.load(rootBundle), cutList: cutList);
    final dir = await getApplicationDocumentsDirectory();
    // Colons and spaces out of DateTime.toString() break the name on the
    // receiving side, and the extension has to be last for viewers to open it.
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File('${dir.path}/laminat-$number-$stamp.pdf');
    await file.writeAsBytes(await pdf.save());
    final xFile = XFile(file.path, mimeType: 'application/pdf');
    await SharePlus.instance.share(ShareParams(files: [xFile], text: caption));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final caption = '${s.laying_scheme} ${s.variant(number)}';
    final scheme = buildScheme(result, system: system, minTextMm: _minTextMm);
    return Scaffold(
        appBar: AppBar(
          title: Text(caption, style: TextStyle(fontSize: 18, color: Colors.black)),
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
            IconButton(
              icon: Icon(_landscape ? Icons.screen_lock_rotation : Icons.screen_rotation,
                  size: 24, color: Colors.black),
              onPressed: _toggleLandscape,
            ),
            IconButton(
              icon: Icon(Icons.list_alt, size: 24, color: Colors.black),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                builder: (_) => CutListSheet(result, number, system),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: IconButton(
                  icon: Icon(Icons.share_rounded, size: 24, color: Colors.black),
                  onPressed: () async =>
                      await shareResult(caption, cutList(result, number, system, s))),
            ),
          ],
        ),
        body: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(builder: (context, constraints) {
            final fit = math.min(
              constraints.maxWidth / scheme.bounds.width,
              constraints.maxHeight / scheme.bounds.height,
            );
            final widestRow = result.lines
                .map((line) => line.planks.first.width)
                .reduce(math.max)
                .toDouble();
            final scale = math.max(fit, _minRowPx / widestRow);
            final drawn = Size(scheme.bounds.width * scale, scheme.bounds.height * scale);
            return InteractiveViewer(
              // Unconstrained, so the scheme may be larger than the screen and
              // be dragged around rather than shrunk to fit.
              constrained: false,
              maxScale: _maxZoom,
              // Zooming out stops where the whole scheme is on screen; a room
              // that already fits cannot be zoomed out at all.
              minScale: math.min(1, fit / scale),
              child: SizedBox(
                width: math.max(drawn.width, constraints.maxWidth),
                height: math.max(drawn.height, constraints.maxHeight),
                child: Center(
                  child: CustomPaint(
                    size: drawn,
                    painter: SchemePainter(scheme, scale, DefaultTextStyle.of(context).style),
                  ),
                ),
              ),
            );
          }),
        ));
  }
}
