import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/global/theme/app_themes.dart';
import 'package:ccc_flutter/widgets/main_screen/horizontal_button.dart';
import 'package:ccc_flutter/widgets/side_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../book.dart';
import '../../favorites.dart';
import '../../global/theme/bloc/theme_bloc.dart';
import '../song_screen/song_screen.dart';
import 'dart:async';
import 'dart:developer' as developer;

class MainScreen extends StatefulWidget {
  MainScreen({Key key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _txtController = TextEditingController();
  var _books = <Book>[];
  var _crtBookId = ALL_SONGS_BOOK_ID;
  var _searchString = "";
  var _favorites = Set<String>();
  List<Song> _searchLyricsResults;

  List<Book> getBooks() {
    final _allSongs = allSongs(_books);
    final _favSongs =
        _allSongs.where((s) => _favorites.contains(s.getId())).toList();
    final allSongsBook = Book(
      name: "Toate cântările",
      id: ALL_SONGS_BOOK_ID,
    )..songs = _allSongs;
    final favoritesBook = Book(
      name: "Lista mea",
      id: FAVORITES_ID,
    )..songs = _favSongs;
    return []
      ..add(allSongsBook)
      ..addAll(_books)
      ..add(favoritesBook);
  }

  String getBookTitleById(String bookId) {
    if (bookId == ALL_SONGS_BOOK_ID) {
      return "Toate cântările";
    } else if (bookId == FAVORITES_ID) {
      return "Lista mea";
    }
    return _books.firstWhere((book) => book.id == bookId).name;
  }

  Future<void> loadFavorites() async {
    final favorites = await fetchFavoritesFromFile();
    setState(() {
      _favorites = favorites;
    });
  }

  Future<void> loadBooks() async {
    await for (var book in fetchBooks()) {
      developer.log("${DateTime.now()} received ${book.id}");
      if (_books.where((b) => b.id == book.id).length > 0) {
        setState(() {
          _books = _books.map((b) => (b.id == book.id) ? book : b).toList();
        });
      } else {
        setState(() {
          _books = [..._books, book];
        });
      }
    }
  }

  Future<void> syncBooks() async {
    await for (var book in fetchBooksFromServer()) {
      developer.log("${DateTime.now()} received ${book.id}");
      if (_books.where((b) => b.id == book.id).length > 0) {
        setState(() {
          _books = _books.map((b) => (b.id == book.id) ? book : b).toList();
        });
      } else {
        setState(() {
          _books = [..._books, book];
        });
      }
    }
  }

  void searchLyrics() {
    final books = getBooks();
    final List<Song> songs = books.firstWhere((b) => b.id == _crtBookId).songs;
    final filteredSongs = songs
        .where((Song song) =>
            _searchString == "" ||
            song.searchableTitle.contains(_searchString) ||
            song.searchableText.contains(_searchString))
        .toList();
    setState(() {
      _searchLyricsResults = filteredSongs;
    });
  }

  void _changeBook(String value) {
    setState(() {
      _crtBookId = value;
    });
    if (_searchLyricsResults != null) {
      searchLyrics();
    }
  }

  List<Song> getFilteredSongs() {
    final books = getBooks();
    if (books.length == 0) {
      return [];
    }
    final List<Song> songs = books.firstWhere((b) => b.id == _crtBookId).songs;
    final numberSongs = songs
        .where((Song song) => song.number.toString() == _searchString)
        .toList();

    final otherSongs = songs
        .where((Song song) =>
            song.number.toString() != _searchString &&
            (_searchString == "" ||
                song.searchableTitle.contains(_searchString)))
        .toList();

    return numberSongs + otherSongs;
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      BlocProvider.of<ThemeBloc>(context).add(ThemeLoaded(
          theme: AppTheme.values[prefs.getInt(PREFS_APP_THEME_KEY) ?? 0]));
    });
    developer.log("${DateTime.now()} Init state");
    loadBooks();
    loadFavorites();
  }

  Widget _buildSongList(bool isDark) {
    final filteredSongs = _searchLyricsResults ?? getFilteredSongs();
    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        itemCount: filteredSongs.length,
        itemBuilder: (context, i) {
          final index = i;
          return _buildRow(filteredSongs[index], isDark);
        });
  }

  Widget _buildRow(Song song, bool isDark) {
    final numFont = TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w900,
      color: isDark ? COLOR_LIGHT_BLUE : COLOR_DARK_BLUE,
    );

    final songTitleFont = const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
    );

    Widget txtNum = Text(
      song.book.id +
          ' ' +
          (song.number != null ? song.number.toString() : '') +
          ' ',
      style: numFont,
    );

    Widget txtTitle = Flexible(
        child: Text(
      song.title,
      style: songTitleFont,
      overflow: TextOverflow.fade,
      softWrap: false,
    ));

    return ListTile(
      title: Row(
        children: [txtNum, txtTitle],
      ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongScreen(
                song: song,
                setFavorite: (songId, value) {
                  setState(() {
                    if (value) {
                      _favorites.add(songId);
                    } else {
                      _favorites.remove(songId);
                    }
                  });
                },
              ),
            ));
      },
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = getBooks();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: SideMenu(
        syncBooks: syncBooks,
      ),
      appBar: AppBar(
        title: DropdownButton<String>(
          value: _crtBookId,
          dropdownColor: Theme.of(context).primaryColor,
          iconEnabledColor: Theme.of(context).primaryTextTheme.headline6.color,
          onChanged: _changeBook,
          items: books.map((Book book) {
            return DropdownMenuItem<String>(
                value: book.id,
                child: Row(
                  children: <Widget>[
                    book.id == FAVORITES_ID
                        ? Padding(
                            padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
                            child: Icon(Icons.star,
                                color: isDark
                                    ? COLOR_DARK_FAVORITE
                                    : COLOR_FAVORITE))
                        : Container(),
                    Text(
                      getBookTitleById(book.id),
                      style: TextStyle(
                        fontSize: 22.0,
                        color: Colors.white,
                        fontWeight: book.id == _crtBookId
                            ? FontWeight.bold
                            : FontWeight.w300,
                      ),
                    ),
                  ],
                ));
          }).toList(),
          underline: Container(),
        ),
        actions: <Widget>[
          Padding(
            child: IconButton(
              icon: Icon(Icons.tonality),
              onPressed: () {
                BlocProvider.of<ThemeBloc>(context).add(ThemeChanged());
              },
              iconSize: 30.0,
            ),
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
              child: LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth < 450) {
                  return Column(
                    verticalDirection: VerticalDirection.up,
                    children: <Widget>[
                      HorizontalButton(
                        callback: searchLyrics,
                        visible: _searchLyricsResults == null &&
                            _searchString.trim().length > 0,
                        text: "Caută în versuri",
                        color: COLOR_DARKER_BLUE,
                        darkColor: COLOR_LIGHT_BLUE.withOpacity(0.4),
                      ),
                      HorizontalButton(
                        callback: () => _changeBook(ALL_SONGS_BOOK_ID),
                        visible: _crtBookId != ALL_SONGS_BOOK_ID &&
                            _searchString.trim().length > 0,
                        text: "Caută în toate cărțile",
                        color: COLOR_DARKER_BLUE,
                        darkColor: COLOR_LIGHT_BLUE.withOpacity(0.4),
                      ),
                      TextField(
                        enableInteractiveSelection: false,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDark ? COLOR_LIGHT_BLUE : COLOR_DARK_BLUE,
                          ),
                          suffixIcon: Visibility(
                            child: GestureDetector(
                              child: Icon(
                                Icons.clear,
                                color:
                                    isDark ? COLOR_LIGHT_BLUE : COLOR_DARK_BLUE,
                              ),
                              onTap: () {
                                WidgetsBinding.instance.addPostFrameCallback(
                                    (_) => _txtController.clear());
                                setState(() {
                                  _searchString = "";
                                  _searchLyricsResults = null;
                                });
                              },
                            ),
                            visible: _searchString != "",
                          ),
                          hintText: 'Caută...',
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: isDark
                                    ? COLOR_DARKER_BLUE.withOpacity(0.9)
                                    : Colors.black12),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: isDark
                                    ? COLOR_DARKER_BLUE.withOpacity(0.9)
                                    : Colors.black12),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          contentPadding: new EdgeInsets.all(0),
                        ),
                        style: new TextStyle(
                          fontSize: 20.0,
                        ),
                        onChanged: (String value) {
                          setState(() {
                            _searchString = Song.getSearchable(value);
                            _searchLyricsResults = null;
                          });
                        },
                        controller: _txtController,
                      ),
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        enableInteractiveSelection: false,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.blueGrey,
                          ),
                          suffixIcon: Visibility(
                            child: GestureDetector(
                              child: Icon(Icons.clear, color: Colors.blueGrey),
                              onTap: () {
                                WidgetsBinding.instance.addPostFrameCallback(
                                    (_) => _txtController.clear());
                                setState(() {
                                  _searchString = "";
                                  _searchLyricsResults = null;
                                });
                              },
                            ),
                            visible: _searchString != "",
                          ),
                          hintText: 'Caută...',
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black12),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black12),
                          ),
                          contentPadding: new EdgeInsets.all(0),
                        ),
                        style: new TextStyle(
                          fontSize: 20.0,
                        ),
                        onChanged: (String value) {
                          setState(() {
                            _searchString = Song.getSearchable(value);
                            _searchLyricsResults = null;
                          });
                        },
                        controller: _txtController,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: HorizontalButton(
                        callback: searchLyrics,
                        visible: _searchLyricsResults == null &&
                            _searchString.trim().length > 0,
                        text: "Versuri",
                        color: COLOR_DARKER_BLUE,
                        darkColor: COLOR_LIGHT_BLUE.withOpacity(0.4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: HorizontalButton(
                        callback: () => _changeBook(ALL_SONGS_BOOK_ID),
                        visible: _crtBookId != ALL_SONGS_BOOK_ID &&
                            _searchString.trim().length > 0,
                        text: "Toate cărțile",
                        color: COLOR_DARKER_BLUE,
                        darkColor: COLOR_LIGHT_BLUE.withOpacity(0.4),
                      ),
                    ),
                  ],
                );
              })),
          Expanded(
            child: _buildSongList(isDark),
          )
        ],
      ),
    );
  }
}
