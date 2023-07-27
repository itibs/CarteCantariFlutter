import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/widgets/common/song_list.dart';
import 'package:ccc_flutter/widgets/song_screen/song_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategorySongsScreen extends StatefulWidget {
  final String category;
  final Set<Song> songs;
  final Function setFavorite;

  CategorySongsScreen({
    Key key,
    @required this.category,
    @required this.songs,
    this.setFavorite,
  }) : super(key: key);

  @override
  _CategorySongsScreenState createState() => _CategorySongsScreenState();
}

class _CategorySongsScreenState extends State<CategorySongsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
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
                setState(() {
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                });
              },
              iconSize: 30.0,
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SongList(
              songs: widget.songs.toList()..sort(),
              onTap: (SongSummary song) async {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SongScreen(
                        song: widget.songs.lookup(song),
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
