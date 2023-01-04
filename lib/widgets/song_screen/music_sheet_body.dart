import 'package:ccc_flutter/blocs/settings/show_key_signatures/show_key_signatures_cubit.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'formatted_text.dart';
import 'key_signature.dart';

class MusicSheetBody extends StatelessWidget {
  final Song song;
  final double textSize;

  final Map<String, TextStyle> _lyricsFormatting = {
    r"[0-9]+\.": TextStyle(fontWeight: FontWeight.bold),
    r"(Refren|R\b[^ăâîșțĂÂÎȘȚ])":
        TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
    r"[^0-9%\n]*\(bis\)":
        TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
  };

  MusicSheetBody({this.song, this.textSize});

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
              getFormattedTextSpan(song.text, textFont, _lyricsFormatting),
            ])))
      ],
    );
  }
}
