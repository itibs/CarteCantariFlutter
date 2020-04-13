import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/global/theme/app_themes.dart';
import 'package:ccc_flutter/widgets/horizontal_button.dart';
import 'package:ccc_flutter/widgets/side_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'book.dart';
import 'global/theme/bloc/theme_bloc.dart';
import 'widgets/song_screen.dart';
import 'dart:async';
import 'dart:developer' as developer;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeBloc(),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Carte Cantari',
            theme: state.themeData,
            home: MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _txtController = TextEditingController();
  var _books = <Book>[];
  var _crtBookId = ALL_SONGS_BOOK_ID;
  var _searchString = "";
  List<Song> _searchLyricsResults;

  List<Book> getBooks() {
    final allSongsBook = Book(
      name: "Toate cântările",
      id: ALL_SONGS_BOOK_ID,
    );
    allSongsBook.songs = allSongs(_books);
    return []..add(allSongsBook)..addAll(_books);
  }

  String getBookTitleById(String bookId) {
    if (bookId == ALL_SONGS_BOOK_ID) {
      return "Toate cântările";
    }
    return _books.firstWhere((book) => book.id == bookId).name;
  }

  Future<void> loadBooks() async {
    await for (var book in fetchBooks()) {
      developer.log("${DateTime.now()} received ${book.id}");
      if (_books.where((b) => b.id == book.id).length > 0) {
        setState(() {
          _books = _books
              .map((b) => (b.id == book.id) ? book : b)
              .toList();
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
          _books = _books
              .map((b) => (b.id == book.id) ? book : b)
              .toList();
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
    final List<Song> songs = books
        .firstWhere((b) => b.id == _crtBookId)
        .songs;
    final filteredSongs = songs.where(
            (Song song) =>
              _searchString == ""
                || song.searchableTitle.contains(_searchString)
                || song.searchableText.contains(_searchString)
    ).toList();
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
    final List<Song> songs = books
        .firstWhere((b) => b.id == _crtBookId)
        .songs;
    return songs.where(
            (Song song) =>
              _searchString == ""
                || song.searchableTitle.contains(_searchString)
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((prefs) {
          BlocProvider.of<ThemeBloc>(context).add(
              ThemeLoaded(theme: AppTheme.values[prefs.getInt(PREFS_APP_THEME_KEY) ?? 0])
          );
    });
    developer.log("${DateTime.now()} Init state");
    loadBooks();
  }

  Widget _buildSongList() {
    final filteredSongs = _searchLyricsResults ?? getFilteredSongs();
    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        itemCount: filteredSongs.length,
        itemBuilder: (context, i) {
          final index = i;
          return _buildRow(filteredSongs[index]);
    });
  }

  Widget _buildRow(Song song) {
    final numFont = const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      color: COLOR_DARK_BLUE_TRANSPARENT,
    );

    final songTitleFont = const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
    );

    Widget txtNum = Text(
      song.book.id + ' ' + (song.number != null ? song.number.toString() : '') + ' ',
      style: numFont,
    );

    Widget txtTitle = Text(
      song.title,
      style: songTitleFont,
    );

    return ListTile(
      title: Row(
        children: [txtNum, txtTitle],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongScreen(song: song),
          )
        );
      },
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log("${DateTime.now()} running build ${_books.length}");
    final books = getBooks();
    return Scaffold(
      drawer: SideMenu(syncBooks: syncBooks,),
      appBar: AppBar(
        title: DropdownButton<String>(
          value: _crtBookId,
          onChanged: _changeBook,
          items: books.map((Book book) {
             return DropdownMenuItem<String>(
               value: book.id,
               child: Text(
                 getBookTitleById(book.id),
                 style: TextStyle(
                     fontSize: 25.0,
                     fontWeight: book.id == _crtBookId ? FontWeight.bold : FontWeight.w300,
                 ),
             ),
            );
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
              iconSize: 40.0,
            ),
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          )
        ],
      ),
      body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
              child: Column(
                verticalDirection: VerticalDirection.up,
                children: <Widget>[
                  HorizontalButton(
                    callback: searchLyrics,
                    visible: _searchLyricsResults == null && _searchString.trim().length > 0,
                    text: "Caută în versuri",
                    color: COLOR_DARK_BLUE,
                    darkColor: COLOR_DARK_BLUE.withOpacity(0.3),
                  ),
                  HorizontalButton(
                    callback: () => _changeBook(ALL_SONGS_BOOK_ID),
                    visible: _crtBookId != ALL_SONGS_BOOK_ID && _searchString.trim().length > 0,
                    text: "Caută în toate cărțile",
                    color: Colors.deepOrange[600],
                    darkColor: Colors.deepOrange[600].withOpacity(0.2),
                  ),
                  TextField(
                    enableInteractiveSelection: false,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.blueGrey,),
                      suffixIcon: Visibility(
                        child: GestureDetector(
                          child: Icon(Icons.clear, color: Colors.blueGrey),
                          onTap: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) => _txtController.clear());
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
                ],
              ),
            ),
            Expanded(
              child: _buildSongList(),
            )
          ],
        ),
    );
  }
}
