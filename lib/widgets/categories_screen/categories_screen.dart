import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:ccc_flutter/helpers.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/widgets/categories_screen/category_songs_screen.dart';
import 'package:ccc_flutter/widgets/categories_screen/category_list.dart';
import 'package:ccc_flutter/widgets/common/search_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesScreen extends StatefulWidget {
  final Set<Song> songs;
  final Function setFavorite;
  final Map<String, List<Song>> categories;

  CategoriesScreen({Key key, @required this.songs, this.setFavorite})
      : categories = getCategories(songs.toList()),
        super(key: key);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();

  static Map<String, List<Song>> getCategories(List<Song> songs) {
    var categories = new Map<String, List<Song>>();
    for (var song in songs) {
      if (song.tags == null) {
        continue;
      }
      for (var tag in song.tags) {
        if (!categories.containsKey(tag)) {
          categories[tag] = new List();
        }
        categories[tag].add(song);
      }
    }
    return categories;
  }
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _txtController = TextEditingController();
  var _searchString = "";

  Map<String, List<Song>> _getFilteredCategories() {
    final filteredCategories = widget.categories.keys
        .where((String category) =>
            _searchString == "" || category.contains(_searchString))
        .toList();

    return Map.fromIterable(filteredCategories,
        key: (e) => e, value: (e) => widget.categories[e]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Categorii"),
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
            child: CategoryList(
              categories: _getFilteredCategories(),
              onTap: (String category, List<Song> songs) async {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategorySongsScreen(
                        category: category,
                        songs: songs.toSet(),
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
