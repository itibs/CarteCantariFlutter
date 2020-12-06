import 'package:ccc_flutter/blocs/settings/show_key_signatures/show_key_signatures_cubit.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'formatted_text.dart';
import 'key_signature.dart';

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

    final showKeySignatures = context.watch<ShowKeySignaturesCubit>().state;

    return Column(
      children: [
        Padding(
            padding: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
            child: RichText(
                text: TextSpan(children: [
              showKeySignatures ? getPitchTextSpan(metaTextFont) : TextSpan(),
              getFormattedTextSpan(song.text, textFont, _lyricsFormatting),
              TextSpan(text: "\n\n\n"),
              getMetaFieldsTextSpan(metaTextFont),
            ])))
      ],
    );
  }

  TextSpan getMetaFieldsTextSpan(TextStyle style) {
    var metaFields = <TextSpan>[];
    final metaHeaderStyle = style.copyWith(fontWeight: FontWeight.bold);
    if (song.author != null) {
      metaFields.add(TextSpan(children: [
        TextSpan(text: "Text: ", style: metaHeaderStyle),
        TextSpan(text: song.author, style: style),
        TextSpan(text: "\n")
      ]));
    }
    if (song.composer != null) {
      metaFields.add(TextSpan(children: [
        TextSpan(text: "Muzică: ", style: metaHeaderStyle),
        TextSpan(text: song.composer, style: style),
        TextSpan(text: "\n")
      ]));
    }
    if (song.originalTitle != null) {
      metaFields.add(TextSpan(children: [
        TextSpan(text: "Titlu original: ", style: metaHeaderStyle),
        TextSpan(text: song.originalTitle, style: style),
        TextSpan(text: "\n")
      ]));
    }
    if (song.references != null) {
      metaFields.add(TextSpan(children: [
        TextSpan(text: "Referințe biblice: ", style: metaHeaderStyle),
        TextSpan(text: song.references, style: style),
        TextSpan(text: "\n")
      ]));
    }

    return TextSpan(children: metaFields);
  }

  TextSpan getPitchTextSpan(TextStyle style) {
    // final keySignatureStyle = TextStyle(
    //   fontSize: style.fontSize,
    //   color: style.color.withAlpha(255),
    //   fontWeight: FontWeight.bold,
    // );
    if (song.pitch != null) {
      return TextSpan(children: [
        TextSpan(text: "Tonalitate recomandată: ", style: style),
        WidgetSpan(
            //child: KeySignature(pitch: song.pitch, style: keySignatureStyle),
            child: KeySignature(pitch: song.pitch),
            alignment: PlaceholderAlignment.middle),
        TextSpan(text: "\n\n\n"),
      ]);
    }

    return TextSpan();
  }
}
