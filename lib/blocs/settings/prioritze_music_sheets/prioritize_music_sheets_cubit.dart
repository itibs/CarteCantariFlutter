import 'package:bloc/bloc.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrioritizeMusicSheetsCubit extends Cubit<bool> {
  PrioritizeMusicSheetsCubit() : super(false);

  void setValue(bool value) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(PREFS_PRIORITIZE_MUSIC_SHEETS, value);
    });
    emit(value);
  }
}
