import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../services/music_sheet_service.dart';

class PdfMusicSheetBody extends StatefulWidget {
  final String pdfMusicSheet;
  final MusicSheetService musicSheetService;

  PdfMusicSheetBody(this.pdfMusicSheet) : musicSheetService = new MusicSheetService();

  @override
  PdfMusicSheetBodyState createState() => PdfMusicSheetBodyState();
}

class PdfMusicSheetBodyState extends State<PdfMusicSheetBody> {
  Uint8List? _memPdf;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    widget.musicSheetService
        .getMusicSheet([widget.pdfMusicSheet])
        .then((result) => setState(() {
              if (result.isNotEmpty) {
                _memPdf = result[0];
              } else {
                _hasError = true;
              }
            }))
        .onError((error, stackTrace) => setState(() {
              _hasError = true;
            }));
  }

  @override
  Widget build(BuildContext context) {
    if (_memPdf == null) {
      return Container();
    }

    return SafeArea(
        child: _hasError
            ? Center(
                child: Text(
                    "A apărut o eroare la încărcarea partiturilor.\nVerifică conexiunea la internet."))
            : SfPdfViewer.memory(
          _memPdf!,
          maxZoomLevel: 5,
          enableDoubleTapZooming: true,
          enableHyperlinkNavigation: false,
          enableTextSelection: false,
          interactionMode: PdfInteractionMode.pan,
          pageLayoutMode: PdfPageLayoutMode.continuous,
        ));
  }

  int? getCustomWidthFromName(String input) {
    RegExp exp = RegExp(r'^W(\d+)_');

    if (exp.hasMatch(input)) {
      var match = exp.firstMatch(input);
      if (match != null) {
        String numberString = match.group(1)!;
        return int.parse(numberString);
      }
    }
    return null;
  }
}
