part of 'theme_bloc.dart';

abstract class ThemeEvent {
  const ThemeEvent();
}

class ThemeChanged extends ThemeEvent {
  ThemeChanged();
}

class ThemeLoaded extends ThemeEvent {
  final AppTheme theme;

  ThemeLoaded({this.theme});
}
