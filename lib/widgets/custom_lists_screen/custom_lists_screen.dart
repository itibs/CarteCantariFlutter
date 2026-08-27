import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:ccc_flutter/models/custom_list.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/services/book_service.dart';
import 'package:ccc_flutter/widgets/song_screen/save_to_list_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'custom_list_songs_screen.dart';

class CustomListsScreen extends StatefulWidget {
  final Set<Song> songs;
  final BookService bookService;
  final Function(SongSummary, bool) setFavorite;

  CustomListsScreen({
    Key? key,
    required this.songs,
    required this.bookService,
    required this.setFavorite,
  }) : super(key: key);

  @override
  _CustomListsScreenState createState() => _CustomListsScreenState();
}

class _CustomListsScreenState extends State<CustomListsScreen> {
  List<CustomList>? _lists;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final lists = await widget.bookService.getCustomLists();
    if (mounted) {
      setState(() {
        _lists = lists;
      });
    }
  }

  Future<void> _createList() async {
    final name = await promptForListName(context, title: "Listă nouă");
    if (name == null || name.trim().isEmpty) {
      return;
    }
    await widget.bookService.createList(name.trim());
    await _loadLists();
  }

  Future<void> _renameList(CustomList list) async {
    final name = await promptForListName(context,
        title: "Redenumește lista", initialValue: list.name);
    if (name == null || name.trim().isEmpty) {
      return;
    }
    await widget.bookService.renameList(list.id, name.trim());
    await _loadLists();
  }

  Future<void> _deleteList(CustomList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Șterge lista"),
        content: Text('Sigur vrei să ștergi lista "${list.name}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Anulează"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Șterge"),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.bookService.deleteList(list.id);
    await _loadLists();
  }

  Future<void> _togglePinned(CustomList list) async {
    await widget.bookService.setListPinned(list.id, !list.pinned);
    await _loadLists();
  }

  String _songCountLabel(CustomList list) {
    final count = list.songIds.length;
    return count == 1 ? "1 cântare" : "$count cântări";
  }

  Widget _buildListTile(CustomList list) {
    return ListTile(
      leading: Icon(Icons.playlist_play, size: 32),
      title: Text(
        list.name,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_songCountLabel(list)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: Icon(
              list.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: list.pinned ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: list.pinned
                ? "Nu mai afișa pe ecranul principal"
                : "Afișează pe ecranul principal",
            onPressed: () => _togglePinned(list),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "rename") {
                _renameList(list);
              } else if (value == "delete") {
                _deleteList(list);
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: "rename",
                child: Row(children: <Widget>[
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 10),
                  Text("Redenumește"),
                ]),
              ),
              PopupMenuItem(
                value: "delete",
                child: Row(children: <Widget>[
                  Icon(Icons.delete, size: 20),
                  SizedBox(width: 10),
                  Text("Șterge"),
                ]),
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomListSongsScreen(
                list: list,
                songs: widget.songs,
                bookService: widget.bookService,
                setFavorite: widget.setFavorite,
              ),
            )).then((_) => _loadLists());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lists = _lists;

    return Scaffold(
      appBar: AppBar(
        title: Text("Listele mele"),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: IconButton(
              icon: Icon(Icons.tonality),
              onPressed: () {
                BlocProvider.of<ThemeBloc>(context).add(ThemeChanged());
              },
              iconSize: 30.0,
            ),
          ),
        ],
      ),
      body: lists == null
          ? Center(child: CircularProgressIndicator())
          : lists.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.queue_music,
                            size: 60, color: Theme.of(context).hintColor),
                        SizedBox(height: 15),
                        Text(
                          "Nu ai încă nicio listă.\nApasă + ca să creezi una.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  children: lists.map(_buildListTile).toList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createList,
        shape: CircleBorder(),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        tooltip: "Listă nouă",
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
