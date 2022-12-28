import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(color.value, swatch);
}

String getSearchable(String s) {
  s = s.toLowerCase();
  s = s
      .replaceAll(new RegExp(r"[ăâ]"), "a")
      .replaceAll(new RegExp(r"[îÎ]"), "i")
      .replaceAll(new RegExp(r"[țţ]"), "t")
      .replaceAll(new RegExp(r"[șş]"), "s")
      .replaceAll(new RegExp(r"[^a-z0-9 ]"), " ")
      .split(new RegExp(r" +"))
      .join(" ")
      .trim();

  return s;
}

void showToast(String toastMessage, FToast fToast) {
  Widget toast = Container(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25.0),
      color: Colors.grey[850],
    ),
    child: Text(
      toastMessage,
      style: TextStyle(color: Colors.white, fontSize: 16),
      textAlign: TextAlign.center,
    ),
  );

  fToast.showToast(
    child: toast,
    gravity: ToastGravity.BOTTOM,
    toastDuration: Duration(seconds: 2),
  );
}

RichText createRichText(
  String text,
  TextStyle style,
  Map<String, TextStyle> stylesMap,
) {
  final stylesList = stylesMap.entries
      .map((entry) => MapEntry(new RegExp(entry.key), entry.value))
      .toList();

  stylesList.asMap().forEach((index, entry) {
    text = text.splitMapJoin(entry.key,
        onMatch: (m) => "%%%%|$index|${m.group(0)}%%%%",
        onNonMatch: (n) => "$n");
  });

  RegExp tokenIdRegEx = new RegExp(r"^\|([0-9]*)\|(.*)");
  final textSpans = text.split("%%%%").map((token) {
    if (token.length > 0 && token[0] == "|") {
      final match = tokenIdRegEx.firstMatch(token);
      return TextSpan(
        text: match.group(2),
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
