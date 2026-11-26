import 'package:ccc_flutter/blocs/settings/show_key_signatures/show_key_signatures.dart';
import 'package:ccc_flutter/blocs/settings/show_play_history/show_play_history.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/helpers.dart';
import 'package:ccc_flutter/play_history_menu_unlock.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SideMenu extends StatefulWidget {
  final VoidCallback syncBooks;
  final VoidCallback goToSongsHistory;
  final VoidCallback goToCategories;
  final VoidCallback goToCustomLists;
  final VoidCallback goToMusicSheetSettings;

  SideMenu({Key? key, required this.syncBooks, required this.goToSongsHistory, required this.goToCategories, required this.goToCustomLists, required this.goToMusicSheetSettings})
      : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  final FToast _fToast = FToast();
  final PlayHistoryTitleTaps _titleTaps = PlayHistoryTitleTaps();
  var _playHistoryMenuUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadPlayHistoryUnlock();
  }

  Future<void> _loadPlayHistoryUnlock() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getBool(PREFS_PLAY_HISTORY_MENU_UNLOCKED) ?? false;
    if (!mounted || !unlocked) return;
    setState(() => _playHistoryMenuUnlocked = true);
  }

  Future<void> _onTitleTap() async {
    if (_playHistoryMenuUnlocked) return;

    final remaining = _titleTaps.register(DateTime.now());
    if (remaining == null) return;

    if (remaining == 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PREFS_PLAY_HISTORY_MENU_UNLOCKED, true);
      await prefs.setBool(PREFS_SETTINGS_SHOW_PLAY_HISTORY, false);
      if (!mounted) return;
      context.read<ShowPlayHistoryCubit>().setValue(false);
      setState(() => _playHistoryMenuUnlocked = true);
      _toast('Istoricul cântărilor este acum disponibil.');
      return;
    }

    _toast(remaining == 1 ? 'Mai este o atingere.' : 'Mai sunt $remaining atingeri.');
  }

  void _toast(String message) {
    _fToast.init(context);
    _fToast.removeQueuedCustomToasts();
    showToast(message, _fToast, ignorePointer: true);
  }

  @override
  Widget build(BuildContext context) {
    final showKeySignatures = context.watch<ShowKeySignaturesCubit>();
    final showPlayHistory = context.watch<ShowPlayHistoryCubit>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          GestureDetector(
            onTap: _onTitleTap,
            child: Container(
              height: 122.0,
              color: COLOR_DARKER_BLUE,
              child: DrawerHeader(
                child: Text(
                  'Carte Cântări Carol',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800),
                ),
                decoration: BoxDecoration(
                  color: COLOR_DARKER_BLUE,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text(
              'Istoric cântări',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: widget.goToSongsHistory,
          ),
          ListTile(
            leading: Icon(Icons.account_tree),
            title: Text(
              'Cântări pe categorii',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: widget.goToCategories,
          ),
          ListTile(
            leading: Icon(Icons.playlist_play),
            title: Text(
              'Listele mele',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: widget.goToCustomLists,
          ),
          CheckboxListTile(
              title: Text(
                'Afișează tonalități',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: showKeySignatures.state,
              onChanged: showKeySignatures.setValue),
          if (_playHistoryMenuUnlocked)
            CheckboxListTile(
                title: Text(
                  'Afișează istoricul cântărilor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Când a fost cântată ultima dată și cât de des',
                  style: TextStyle(fontSize: 12),
                ),
                value: showPlayHistory.state,
                onChanged: showPlayHistory.setValue),
          ListTile(
            //leading: Icon(Icons.sync),
            title: Text(
              'Opțiuni partituri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: widget.goToMusicSheetSettings,
          ),
          ListTile(
            leading: Icon(Icons.sync),
            title: Text(
              'Actualizare cântări',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: widget.syncBooks,
          ),
        ],
      ),
    );
  }
}
