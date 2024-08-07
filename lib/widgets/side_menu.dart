import 'package:ccc_flutter/blocs/settings/show_key_signatures/show_key_signatures.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback syncBooks;
  final VoidCallback goToSongsHistory;
  final VoidCallback goToCategories;
  final VoidCallback goToMusicSheetSettings;

  SideMenu({Key? key, required this.syncBooks, required this.goToSongsHistory, required this.goToCategories, required this.goToMusicSheetSettings})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showKeySignatures = context.watch<ShowKeySignaturesCubit>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 122.0,
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
          ListTile(
            leading: Icon(Icons.history),
            title: Text(
              'Istoric cântări',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: goToSongsHistory,
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
            onTap: goToCategories,
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
          ListTile(
            //leading: Icon(Icons.sync),
            title: Text(
              'Opțiuni partituri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: goToMusicSheetSettings,
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
            onTap: syncBooks,
          ),
        ],
      ),
    );
  }
}
