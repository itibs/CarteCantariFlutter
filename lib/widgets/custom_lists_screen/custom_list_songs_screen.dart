import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:ccc_flutter/models/custom_list.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/services/book_service.dart';
import 'package:ccc_flutter/widgets/common/song_list.dart';
import 'package:ccc_flutter/widgets/song_screen/song_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomListSongsScreen extends StatefulWidget {
  final CustomList list;
  final Set<Song> songs;
  final BookService bookService;
  final Function(SongSummary, bool) setFavorite;

  CustomListSongsScreen({
    Key? key,
    required this.list,
    required this.songs,
    required this.bookService,
    required this.setFavorite,
  }) : super(key: key);

  @override
  _CustomListSongsScreenState createState() => _CustomListSongsScreenState();
}

class _CustomListSongsScreenState extends State<CustomListSongsScreen> {
  List<SongSummary> _listSongs = [];

  @override
  void initState() {
    super.initState();
    _resolveSongs();
  }

  void _resolveSongs() {
    setState(() {
      _listSongs = widget.bookService
          .resolveListSongs(widget.list, widget.songs.toList());
    });
  }

  Future<void> _removeSong(SongSummary song) async {
    setState(() {
      _listSongs.remove(song);
    });
    await widget.bookService.removeSongFromList(widget.list.id, song);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.name),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.tonality),
            onPressed: () {
              BlocProvider.of<ThemeBloc>(context).add(ThemeChanged());
            },
            iconSize: 30.0,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              iconSize: 30.0,
            ),
          ),
        ],
      ),
      body: _listSongs.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  "Lista este goală.\nAdaugă cântări din ecranul unei cântări, cu butonul de adăugare în listă.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            )
          : Column(
              children: <Widget>[
                Expanded(
                  child: SongList(
                    songs: _listSongs,
                    onDismiss: _removeSong,
                    onTap: (SongSummary song) async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SongScreen(
                              song: widget.songs.lookup(song)!,
                              bookService: widget.bookService,
                              setFavorite: widget.setFavorite,
                            ),
                          )).then((_) => _resolveSongs());
                      return;
                    },
                  ),
                )
              ],
            ),
    );
  }
}
