import 'package:bloc/bloc.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShowKeySignaturesCubit extends Cubit<bool> {
  ShowKeySignaturesCubit() : super(false);

  void setValue(bool value) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(PREFS_SETTINGS_SHOW_KEY_SIGNATURES, value);
    });
    emit(value);
  }
}
