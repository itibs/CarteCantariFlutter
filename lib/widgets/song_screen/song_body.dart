import 'package:ccc_flutter/models/song.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'formatted_text.dart';

class SongBody extends StatelessWidget {
  final Song song;
  final double textSize;

  final Map<String, TextStyle> _lyricsFormatting = {
    r"[0-9]+\.": TextStyle(fontWeight: FontWeight.bold),
    r"(Refren|R\b[^ăâîșțĂÂÎȘȚ])":
        TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
    r"[^0-9%\n]*\(bis\)":
        TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
  };

  SongBody({this.song, this.textSize});

  @override
  Widget build(BuildContext context) {
    final textFont = TextStyle(
      fontSize: textSize,
      color: Theme.of(context).textTheme.headline6.color,
    );

    final metaTextFont = TextStyle(
      fontSize: textSize * 0.75,
      color: Theme.of(context).textTheme.headline6.color.withAlpha(190),
      fontStyle: FontStyle.italic,
    );

    return Column(
      children: [
        Padding(
            padding: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
            child: RichText(
                text: TextSpan(children: [
              getFormattedTextSpan(song.text, textFont, _lyricsFormatting),
              TextSpan(text: "\n\n\n"),
              getMetaFieldsTextSpan(metaTextFont),
            ])))
      ],
    );
  }

  TextSpan getMetaFieldsTextSpan(TextStyle style) {
    var metaFields = [];
    if (song.author != null) {
      metaFields.add("TEXT: ${song.author}");
    }
    if (song.composer != null) {
      metaFields.add("MUZICĂ: ${song.composer}");
    }
    if (song.originalTitle != null) {
      metaFields.add("Titlu original: ${song.originalTitle}");
    }
    if (song.references != null) {
      metaFields.add("Referințe biblice: ${song.references}");
    }

    return TextSpan(text: metaFields.join("\n"), style: style);
  }
}
