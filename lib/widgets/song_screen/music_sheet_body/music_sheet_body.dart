import 'package:ccc_flutter/widgets/song_screen/music_sheet_body/pdf_music_sheet_body.dart';
import 'package:ccc_flutter/widgets/song_screen/music_sheet_body/photos_music_sheet_body.dart';
import 'package:flutter/material.dart';

class MusicSheetBody {
  static Widget createMusicSheetBody(List<String> musicSheet) {
    if (musicSheet.length > 0 && musicSheet[0].endsWith(".pdf")) {
      return PdfMusicSheetBody(musicSheet[0]);
    }
    return PhotosMusicSheetBody(musicSheet);
  }
}