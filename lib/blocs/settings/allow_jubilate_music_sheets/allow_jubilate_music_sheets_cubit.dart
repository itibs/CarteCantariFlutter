import 'package:bloc/bloc.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllowJubilateMusicSheetsCubit extends Cubit<bool> {
  AllowJubilateMusicSheetsCubit() : super(false);

  void setValue(bool value) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(PREFS_ALLOW_JUBILATE, value);
    });
    emit(value);
  }
}
