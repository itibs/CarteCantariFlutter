import 'package:ccc_flutter/blocs/settings/allow_cor_music_sheets/allow_cor_music_sheets.dart';
import 'package:ccc_flutter/blocs/settings/allow_jubilate_music_sheets/allow_jubilate_music_sheets.dart';

import 'blocs/settings/show_key_signatures/show_key_signatures.dart';
import 'services/pitch_sound_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'blocs/theme/theme_bloc.dart';
import 'widgets/main_screen/main_screen.dart';

/// Maximum content width on the web build so the app stays centered and
/// readable instead of stretching across the full width of large monitors.
/// This is a *logical* pixel cap, so browser zoom still enlarges the content:
/// zooming in shrinks the logical viewport, letting the column grow to fill it.
const double _kMaxWebContentWidth = 720;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ThemeBloc(),
          ),
          BlocProvider(
            create: (context) => ShowKeySignaturesCubit(),
          ),
          BlocProvider(
            create: (context) => AllowJubilateMusicSheetsCubit(),
          ),
          BlocProvider(
            create: (context) => AllowCorMusicSheetsCubit(),
          )
        ],
        child: Provider(
          create: (context) => PitchSoundService(),
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return MaterialApp(
                title: 'Carte Cantari',
                theme: state.themeData,
                debugShowCheckedModeBanner: false,
                builder: _webMaxWidthBuilder,
                home: MainScreen(),
              );
            },
          ),
        ));
  }

  /// On the web, constrain the app to a max width and center it so it doesn't
  /// stretch across the entire width of large monitors. The centered column is
  /// framed with side borders and a soft shadow against a contrasting gutter so
  /// the narrower layout reads as intentional rather than a cut-off header. On
  /// other platforms the child is returned untouched.
  static Widget _webMaxWidthBuilder(BuildContext context, Widget? child) {
    final content = child ?? const SizedBox.shrink();
    if (!kIsWeb) return content;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // A gutter color that contrasts with the page so the centered column stands
    // out as a distinct surface.
    final gutterColor = isDark
        ? Color.alphaBlend(Colors.black.withOpacity(0.35), theme.scaffoldBackgroundColor)
        : Color.alphaBlend(Colors.black.withOpacity(0.06), theme.scaffoldBackgroundColor);

    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.6 : 0.4);

    // A dark drop shadow is invisible against a dark gutter, so in dark mode we
    // use a subtle light glow that separates the (lighter) page from the
    // (darker) gutter; in light mode a normal soft drop shadow.
    final shadowColor = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.15);

    return LayoutBuilder(
      builder: (context, constraints) {
        // No gutter to show on narrow windows; return the content untouched so
        // small/mobile-sized browser windows behave normally.
        if (constraints.maxWidth <= _kMaxWebContentWidth) return content;

        return ColoredBox(
          color: gutterColor,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxWebContentWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border.symmetric(
                    vertical: BorderSide(color: borderColor),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 24,
                      spreadRadius: isDark ? 1 : 0,
                    ),
                  ],
                ),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}
