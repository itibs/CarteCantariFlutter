import 'package:ccc_flutter/blocs/auth/auth_cubit.dart';
import 'package:ccc_flutter/blocs/settings/show_key_signatures/show_key_signatures.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback syncBooks;
  final VoidCallback goToSongsHistory;
  final VoidCallback goToCategories;
  final VoidCallback goToCustomLists;
  final VoidCallback goToMusicSheetSettings;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  SideMenu(
      {Key? key,
      required this.syncBooks,
      required this.goToSongsHistory,
      required this.goToCategories,
      required this.goToCustomLists,
      required this.goToMusicSheetSettings,
      required this.onLogin,
      required this.onLogout})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showKeySignatures = context.watch<ShowKeySignaturesCubit>();
    final authState = context.watch<AuthCubit>().state;
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
          ListTile(
            leading: Icon(Icons.playlist_play),
            title: Text(
              'Listele mele',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: goToCustomLists,
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
              onChanged: (value) {
                showKeySignatures.setValue(value);
                SyncService.instance?.notifyLocalChange();
              }),
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
          Divider(),
          if (!authState.signedIn)
            ListTile(
              leading: Icon(Icons.login),
              title: Text(
                'Conectare cu Google',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Sincronizează favoritele, listele, setările și accesul la partituri între dispozitive.',
                style: TextStyle(fontSize: 12),
              ),
              onTap: onLogin,
            )
          else ...[
            ListTile(
              leading: _buildAvatar(authState),
              title: Text(
                authState.displayName ?? authState.email ?? '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: authState.displayName != null
                  ? Text(
                      authState.email ?? '',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text(
                'Deconectare',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: onLogout,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(AuthState authState) {
    final photoUrl = authState.photoUrl;
    if (photoUrl != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(photoUrl),
        // Ignore load failures (e.g. offline); the circle just stays empty.
        onBackgroundImageError: (_, __) {},
      );
    }
    final initialSource = authState.displayName ?? authState.email ?? "?";
    return CircleAvatar(
        child: Text(initialSource.substring(0, 1).toUpperCase()));
  }
}
