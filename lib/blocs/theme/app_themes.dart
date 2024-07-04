import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/helpers.dart';
import 'package:flutter/material.dart';

enum AppTheme {
  Light,
  Dark,
}

final appThemeData = {
  AppTheme.Light: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: COLOR_DARKER_BLUE,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
        color: createMaterialColor(COLOR_DARKER_BLUE),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white)),
    useMaterial3: true,
  ),
  AppTheme.Dark: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: COLOR_DARKER_BLUE,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
        color: createMaterialColor(COLOR_DARKER_BLUE),
        iconTheme: IconThemeData(color: Colors.white)),
    checkboxTheme:
        CheckboxThemeData(fillColor: MaterialStateColor.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.white;
      } else {
        return createMaterialColor(COLOR_DARKER_BLUE.withAlpha(0));
      }
    })),
    scaffoldBackgroundColor: createMaterialColor(Colors.black),
    useMaterial3: true,
  ),
};
