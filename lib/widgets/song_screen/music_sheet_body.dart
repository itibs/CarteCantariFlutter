import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/music_sheet_service.dart';
import 'cover_interactive_viewer.dart';

class MusicSheetBody extends StatefulWidget {
  final List<String> musicSheet;
  final MusicSheetService musicSheetService;

  MusicSheetBody(this.musicSheet) : musicSheetService = new MusicSheetService();

  @override
  MusicSheetBodyState createState() => MusicSheetBodyState();
}

class MusicSheetBodyState extends State<MusicSheetBody> {
  var _memImages = <Uint8List>[];
  var _hasError = false;

  @override
  void initState() {
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
    return SafeArea(
        child: _hasError
            ? Center(child: Text("A apărut o eroare la încărcarea partiturilor.\nVerifică conexiunea la internet."))
            : CoverInteractiveViewer(
                child: Column(
                children: _memImages
                    .map((imgBytes) => Image.memory(imgBytes))
                    .toList(),
              )));
  }
}
