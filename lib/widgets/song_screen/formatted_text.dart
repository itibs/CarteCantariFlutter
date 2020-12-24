import 'package:flutter/material.dart';

TextSpan getFormattedTextSpan(
    String text, TextStyle style, Map<String, TextStyle> stylesMap) {
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
        text: token.substring(match.group(0).length),
        style: stylesList[int.parse(match.group(1))].value,
      );
    } else {
      return TextSpan(
        text: token,
      );
    }
  }).toList();

  return TextSpan(
    style: style,
    children: textSpans,
  );
}
