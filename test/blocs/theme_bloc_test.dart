import 'package:bloc_test/bloc_test.dart';
import 'package:ccc_flutter/blocs/theme/app_themes.dart';
import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts in the light theme', () {
    final bloc = ThemeBloc();
    expect(bloc.state.themeData, appThemeData[AppTheme.Light]);
  });

  blocTest<ThemeBloc, ThemeState>(
    'ThemeChanged toggles from light to dark',
    build: () => ThemeBloc(),
    act: (bloc) => bloc.add(ThemeChanged()),
    expect: () => [ThemeState(appThemeData[AppTheme.Dark]!)],
  );

  blocTest<ThemeBloc, ThemeState>(
    'ThemeChanged twice toggles back to light',
    build: () => ThemeBloc(),
    act: (bloc) => bloc
      ..add(ThemeChanged())
      ..add(ThemeChanged()),
    expect: () => [
      ThemeState(appThemeData[AppTheme.Dark]!),
      ThemeState(appThemeData[AppTheme.Light]!),
    ],
  );

  blocTest<ThemeBloc, ThemeState>(
    'ThemeLoaded applies the requested theme',
    build: () => ThemeBloc(),
    act: (bloc) => bloc.add(ThemeLoaded(theme: AppTheme.Dark)),
    expect: () => [ThemeState(appThemeData[AppTheme.Dark]!)],
  );
}
