import 'package:bloc/bloc.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShowPlayHistoryCubit extends Cubit<bool> {
  ShowPlayHistoryCubit() : super(false);

  void setValue(bool? value) {
    if (value == null) {
      return;
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(PREFS_SETTINGS_SHOW_PLAY_HISTORY, value);
    });
    emit(value);
  }
}
