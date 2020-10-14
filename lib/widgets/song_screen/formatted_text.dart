import 'package:flutter/material.dart';

class FormattedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Map<String, TextStyle> stylesMap;

  FormattedText({Key key, @required this.text, @required this.style, @required this.stylesMap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stylesList = stylesMap.entries
        .map((entry) => MapEntry(new RegExp(entry.key), entry.value))
        .toList();

    var parsedText = text;
    stylesList.asMap().forEach((index, entry) {
      parsedText = parsedText.splitMapJoin(entry.key,
          onMatch: (m) => "%%%%|$index|${m.group(0)}%%%%",
          onNonMatch: (n) => "$n");
    });

    RegExp tokenIdRegEx = new RegExp(r"^\|([0-9]*)\|");
    final textSpans = parsedText.split("%%%%").map((token) {
      if (token.length > 0 && token[0] == "|") {
        final match = tokenIdRegEx.firstMatch(token);
        return TextSpan(
          text: token.substring(match
              .group(0)
              .length),
          style: stylesList[int.parse(match.group(1))].value,
        );
      } else {
        return TextSpan(
          text: token,
        );
      }
    }).toList();

    return RichText(
      text: TextSpan(
        style: style,
        children: textSpans,
      ),
    );
  }
}