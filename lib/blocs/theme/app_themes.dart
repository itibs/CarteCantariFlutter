import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/helpers.dart';
import 'package:flutter/material.dart';

enum AppTheme {
  Light,
  Dark,
}

final appThemeData = {
  AppTheme.Light: ThemeData(
    brightness: Brightness.light,
    primarySwatch: createMaterialColor(COLOR_DARKER_BLUE),
  ),
  AppTheme.Dark: ThemeData(
    brightness: Brightness.dark,
    primarySwatch: createMaterialColor(COLOR_BLUE),
    backgroundColor: createMaterialColor(Colors.white),
    appBarTheme: AppBarTheme(color: createMaterialColor(COLOR_DARKER_BLUE)),
    scaffoldBackgroundColor: createMaterialColor(Colors.black),
  ),
};
