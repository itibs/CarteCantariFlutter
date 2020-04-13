import 'package:ccc_flutter/constants.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback syncBooks;

  SideMenu({Key key, @required this.syncBooks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 122.0,
            child: DrawerHeader(
              child: Text(
                'Carte Cântări Carol',
                style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800),
              ),
              decoration: BoxDecoration(
                color: COLOR_DARK_BLUE,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.sync),
            title: Text('Actualizare cântări'),
            onTap: syncBooks,
          ),
        ],
      ),
    );
  }
}