import 'package:flutter/material.dart';

import 'cover_interactive_viewer.dart';

class MusicSheetBody extends StatefulWidget {
  final List<String> musicSheet;

  MusicSheetBody(this.musicSheet);

  @override
  MusicSheetBodyState createState() => MusicSheetBodyState();
}

class MusicSheetBodyState extends State<MusicSheetBody> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: CoverInteractiveViewer(
        child: Column(
          children: widget.musicSheet.map((fileName) => Image.network("https://cartecantari-music-sheets.s3.eu-central-1.amazonaws.com/$fileName")).toList(),
        )));
  }
}
