import 'package:ccc_flutter/blocs/settings/show_key_signatures/show_key_signatures_cubit.dart';
import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/blocs/theme/app_themes.dart';
import 'package:ccc_flutter/helpers.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/services/book_service.dart';
import 'package:ccc_flutter/widgets/main_screen/horizontal_button.dart';
import 'package:ccc_flutter/widgets/side_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/book.dart';
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
  var _songs = Future(() => Set<Song>());
  var _crtBookId = ALL_SONGS_BOOK_ID;
  var _searchString = "";
  List<SongSummary> _searchLyricsResults;
  BookService _bookService;
  FToast _fToast;

  _MainScreenState() {
    _bookService = new BookService();
  }

  String getBookTitleById(String bookId) {
    return _books.firstWhere((book) => book.id == bookId).title;
  }

  Future<bool> loadBooks({bool forceResync = false}) async {
    var count = 0;
    await for (var bookPackage
        in _bookService.getBookPackage(forceResync: forceResync)) {
      count++;
      setState(() {
        _books = bookPackage.books;
        _songs = bookPackage.songs;
      });
    }

    return count > 0;
  }

  Future<bool> syncBooks() async {
    return await loadBooks(forceResync: true);
  }

  void searchLyrics() async {
    final songs = _books.firstWhere((b) => b.id == _crtBookId).songSummaries;
    final fullSongs = await _songs;
    final filteredSongs = songs.where((SongSummary song) {
      return _searchString == "" ||
          song.searchableTitle.contains(_searchString) ||
          fullSongs.lookup(song).searchableText.contains(_searchString);
    }).toList();
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

  List<SongSummary> getFilteredSongs() {
    if (_books.length == 0) {
      return [];
    }
    final List<SongSummary> songs =
        _books.firstWhere((b) => b.id == _crtBookId).songSummaries;
    final numberSongs = songs
        .where((SongSummary song) => song.number.toString() == _searchString)
        .toList();

    final otherSongs = songs
        .where((SongSummary song) =>
            song.number.toString() != _searchString &&
            (_searchString == "" ||
                song.searchableTitle.contains(_searchString)))
        .toList();

    return numberSongs + otherSongs;
  }

  @override
  void initState() {
    super.initState();

    _fToast = FToast();
    _fToast.init(context);

    SharedPreferences.getInstance().then((prefs) {
      BlocProvider.of<ThemeBloc>(context).add(ThemeLoaded(
          theme: AppTheme.values[prefs.getInt(PREFS_APP_THEME_KEY) ?? 0]));
      context
          .read<ShowKeySignaturesCubit>()
          .setValue(prefs.getBool(PREFS_SETTINGS_SHOW_KEY_SIGNATURES) ?? false);
    });
    developer.log("${DateTime.now()} Init state");
    loadBooks();
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

  Widget _buildRow(SongSummary song, bool isDark) {
    final numFont = TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w900,
      color: isDark ? COLOR_LIGHT_BLUE : COLOR_DARKER_BLUE,
    );

    final songTitleFont = const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
    );

    Widget txtNum = Text(
      song.bookAndNum + " ",
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
      onTap: () async {
        final fullSongs = await _songs;
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongScreen(
                song: fullSongs.lookup(song),
                setFavorite: (favSong, value) {
                  var favoritesBooks =
                      _books.where((book) => book.id == FAVORITES_ID).toList();
                  if (favoritesBooks.isNotEmpty) {
                    setState(() {
                      if (value) {
                        favoritesBooks.first.songSummaries.add(song);
                      } else {
                        favoritesBooks.first.songSummaries.remove(song);
                      }
                    });
                  }
                },
              ),
            ));
      },
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: SideMenu(
        syncBooks: () => syncBooks().then((success) => showToast(
            success
                ? "Cântările au fost actualizate"
                : "A apărut o eroare la actualizare.\nVerifică dacă ai conexiune la internet.",
            _fToast)),
      ),
      appBar: AppBar(
        title: DropdownButton<String>(
          value: _crtBookId,
          dropdownColor: Theme.of(context).primaryColor,
          iconEnabledColor: Theme.of(context).primaryTextTheme.headline6.color,
          onChanged: _changeBook,
          items: _books.map((Book book) {
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
                            _searchString = getSearchable(value);
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
                            _searchString = getSearchable(value);
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
