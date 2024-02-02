import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../services/music_sheet_service.dart';
import 'cover_interactive_viewer.dart';

class PhotosMusicSheetBody extends StatefulWidget {
  final List<String> musicSheet;
  final MusicSheetService musicSheetService;

  PhotosMusicSheetBody(this.musicSheet) : musicSheetService = new MusicSheetService();

  @override
  PhotosMusicSheetBodyState createState() => PhotosMusicSheetBodyState();
}

class PhotosMusicSheetBodyState extends State<PhotosMusicSheetBody> {
  var _memImages = <Uint8List>[];
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    widget.musicSheetService
        .getMusicSheet(widget.musicSheet)
        .then((result) => setState(() {
              _memImages = result;
            }))
        .onError((error, stackTrace) => setState(() {
              _hasError = true;
            }));
  }

  @override
  Widget build(BuildContext context) {
    final firstMusicSheet = widget.musicSheet.length > 0 ? widget.musicSheet[0] : "";
    return SafeArea(
        child: _hasError
            ? Center(
                child: Text(
                    "A apărut o eroare la încărcarea partiturilor.\nVerifică conexiunea la internet."))
            : CoverInteractiveViewer(
                child: Column(
                  children: _memImages
                      .map((imgBytes) => Image.memory(imgBytes))
                      .toList(),
                ),
                musicSheetWidth: getCustomWidthFromName(firstMusicSheet),
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
