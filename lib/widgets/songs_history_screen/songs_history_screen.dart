import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:ccc_flutter/helpers.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_history_entry.dart';
import 'package:ccc_flutter/services/songs_history_service.dart';
import 'package:ccc_flutter/widgets/common/search_box.dart';
import 'package:ccc_flutter/widgets/songs_history_screen/songs_history_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/song_summary.dart';
import '../song_screen/song_screen.dart';

class SongsHistoryScreen extends StatefulWidget {
  final Set<Song> songs;
  final Function(SongSummary, bool) setFavorite;

  SongsHistoryScreen({Key? key, required this.songs, required this.setFavorite})
      : super(key: key);

  @override
  _SongsHistoryScreenState createState() => _SongsHistoryScreenState();
}

class _SongsHistoryScreenState extends State<SongsHistoryScreen> {
  final _txtController = TextEditingController();
  var _songsHistory = <SongsHistoryEntry>[];
  var _songsById = Map<String, Song>();
  var _searchString = "";

  List<SongsHistoryEntry> _getFilteredSongHistory() {
    final filteredSongHistory = _songsHistory
        .where((SongsHistoryEntry entry) =>
            _searchString == "" ||
            (_songsById.containsKey(entry.songId) &&
                _songsById[entry.songId]!
                    .searchableTitle
                    .contains(_searchString)) ||
            getSearchable(entry.getHumanReadableDateAdded()).contains(_searchString))
        .toList()
      ..sort((entry1, entry2) => entry2.dateAdded.compareTo(entry1.dateAdded));

    return filteredSongHistory;
  }

  @override
  void initState() {
    super.initState();

    for (var song in widget.songs) {
      _songsById[song.id] = song;
    }

    SongsHistoryService().getSongsHistory().then((songsHistory) {
      setState(() {
        _songsHistory = songsHistory;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Istoric cântări",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
            child: Column(
              verticalDirection: VerticalDirection.up,
              children: <Widget>[
                SearchBox(
                    txtController: _txtController,
                    onTextChanged: (text) => setState(() {
                          _searchString = getSearchable(text);
                        }),
                    onClear: () => setState(() {
                          _searchString = "";
                        })),
              ],
            ),
          ),
          Expanded(
            child: SongsHistoryList(
              songsHistory: _getFilteredSongHistory(),
              songById: _songsById,
              onTap: (Song song) async {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SongScreen(
                        song: song,
                        setFavorite: widget.setFavorite,
                      ),
                    ));
                return;
              },
            ),
          )
        ],
      ),
    );
  }
}
