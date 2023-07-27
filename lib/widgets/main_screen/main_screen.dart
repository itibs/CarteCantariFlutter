import 'package:ccc_flutter/blocs/settings/show_key_signatures/show_key_signatures_cubit.dart';
import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/blocs/theme/app_themes.dart';
import 'package:ccc_flutter/helpers.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/services/book_service.dart';
import 'package:ccc_flutter/widgets/categories_screen/categories_screen.dart';
import 'package:ccc_flutter/widgets/common/search_box.dart';
import 'package:ccc_flutter/widgets/common/song_list.dart';
import 'package:ccc_flutter/widgets/main_screen/horizontal_button.dart';
import 'package:ccc_flutter/widgets/music_sheet_settings_screen/music_sheet_settings_screen.dart';
import 'package:ccc_flutter/widgets/side_menu.dart';
import 'package:flutter/material.dart';
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

  String _getBookTitleById(String bookId) {
    return _books.firstWhere((book) => book.id == bookId).title;
  }

  Future<bool> _loadBooks({bool forceResync = false}) async {
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

  Future<bool> _syncBooks() async {
    return await _loadBooks(forceResync: true);
  }

  void _searchLyrics() async {
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
      _searchLyrics();
    }
  }

  List<SongSummary> _getFilteredSongs() {
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
    _loadBooks();
  }

  void _setFavorite(SongSummary favSong, bool value) {
    var favoritesBooks =
        _books.where((book) => book.id == FAVORITES_ID).toList();
    if (favoritesBooks.isNotEmpty) {
      setState(() {
        if (value) {
          favoritesBooks.first.songSummaries.add(favSong);
        } else {
          favoritesBooks.first.songSummaries.remove(favSong);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: SideMenu(
        syncBooks: () => _syncBooks().then((success) => showToast(
            success
                ? "Cântările au fost actualizate"
                : "A apărut o eroare la actualizare.\nVerifică dacă ai conexiune la internet.",
            _fToast)),
        goToCategories: () async {
          final fullSongs = await _songs;
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoriesScreen(
                  songs: fullSongs,
                  setFavorite: _setFavorite,
                ),
              ));
          return;
        },
        goToMusicSheetSettings: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MusicSheetSettingsScreen(
                  songs: _songs,
                ),
              ));
          return;
        },
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
                      _getBookTitleById(book.id),
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
            padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
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
                        callback: _searchLyrics,
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
                      SearchBox(
                          txtController: _txtController,
                          onTextChanged: (text) => setState(() {
                                _searchString = getSearchable(text);
                                _searchLyricsResults = null;
                              }),
                          onClear: () => setState(() {
                                _searchString = "";
                                _searchLyricsResults = null;
                              })),
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(
                      child: SearchBox(
                          txtController: _txtController,
                          onTextChanged: (text) => setState(() {
                                _searchString = getSearchable(text);
                                _searchLyricsResults = null;
                              }),
                          onClear: () => setState(() {
                                _searchString = "";
                                _searchLyricsResults = null;
                              })),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: HorizontalButton(
                        callback: _searchLyrics,
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
            child: SongList(
              songs: _searchLyricsResults ?? _getFilteredSongs(),
              onTap: (SongSummary song) async {
                final fullSongs = await _songs;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SongScreen(
                        song: fullSongs.lookup(song),
                        setFavorite: _setFavorite,
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
