import 'package:bloc/bloc.dart';
import 'package:ccc_flutter/blocs/theme/app_themes.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ccc_flutter/constants.dart';

part 'theme_event.dart';

part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState(appThemeData[AppTheme.Light]!)) {
    on<ThemeChanged>(_onThemeChanged);
    on<ThemeLoaded>(_onThemeLoaded);
  }

  void _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) {
    int themeIdx = 0;
    if (state.themeData == appThemeData[AppTheme.Dark]) {
      emit(ThemeState(appThemeData[AppTheme.Light]!));
      themeIdx = AppTheme.Light.index;
    } else {
      emit(ThemeState(appThemeData[AppTheme.Dark]!));
      themeIdx = AppTheme.Dark.index;
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(PREFS_APP_THEME_KEY, themeIdx);
    });
  }

  void _onThemeLoaded(ThemeLoaded event, Emitter<ThemeState> emit) {
    if (appThemeData.containsKey(event.theme)) {
      emit(ThemeState(appThemeData[event.theme]!));
    }
  }
}
