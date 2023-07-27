import 'package:ccc_flutter/blocs/settings/allow_cor_music_sheets/allow_cor_music_sheets.dart';
import 'package:ccc_flutter/blocs/settings/allow_jubilate_music_sheets/allow_jubilate_music_sheets.dart';

import 'blocs/settings/show_key_signatures/show_key_signatures.dart';
import 'services/pitch_sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'blocs/theme/theme_bloc.dart';
import 'widgets/main_screen/main_screen.dart';

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
                home: MainScreen(),
              );
            },
          ),
        ));
  }
}
