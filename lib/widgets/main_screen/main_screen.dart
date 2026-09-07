import 'package:ccc_flutter/blocs/auth/auth_cubit.dart';
import 'package:ccc_flutter/blocs/settings/allow_cor_music_sheets/allow_cor_music_sheets.dart';
import 'package:ccc_flutter/blocs/settings/allow_jubilate_music_sheets/allow_jubilate_music_sheets.dart';
import 'package:ccc_flutter/blocs/settings/show_key_signatures/show_key_signatures_cubit.dart';
import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/blocs/theme/app_themes.dart';
import 'package:ccc_flutter/helpers.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/services/book_service.dart';
import 'package:ccc_flutter/services/songs_history_service.dart';
import 'package:ccc_flutter/services/sync_service.dart';
import 'package:ccc_flutter/widgets/auth/web_sign_in_dialog.dart';
import 'package:ccc_flutter/widgets/categories_screen/categories_screen.dart';
import 'package:ccc_flutter/widgets/custom_lists_screen/custom_lists_screen.dart';
import 'package:ccc_flutter/widgets/common/search_box.dart';
import 'package:ccc_flutter/widgets/common/song_list.dart';
import 'package:ccc_flutter/widgets/main_screen/horizontal_button.dart';
import 'package:ccc_flutter/widgets/music_sheet_settings_screen/music_sheet_settings_screen.dart';
import 'package:ccc_flutter/widgets/side_menu.dart';
import 'package:ccc_flutter/widgets/songs_history_screen/songs_history_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/book.dart';
import '../song_screen/song_screen.dart';
import 'dart:async';
import 'dart:developer' as developer;

class MainScreen extends StatefulWidget {
  MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _txtController = TextEditingController();
  var _books = <Book>[];
  var _songs = Future(() => Set<Song>());
  var _crtBookId = ALL_SONGS_BOOK_ID;
  var _searchString = "";
  List<SongSummary>? _searchLyricsResults;
  BookService _bookService;
  SongsHistoryService _songsHistoryService;
  FToast _fToast;

  _MainScreenState()
      : _bookService = new BookService(),
        _songsHistoryService = new SongsHistoryService(),
        _fToast = FToast();

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
          fullSongs.lookup(song)!.searchableText.contains(_searchString);
    }).toList();
    setState(() {
      _searchLyricsResults = filteredSongs;
    });
  }

  void _changeBook(String? value) {
    if (value == null) {
      return;
    }
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

    _fToast.init(context);

    SharedPreferences.getInstance().then((prefs) {
      BlocProvider.of<ThemeBloc>(context).add(ThemeLoaded(
          theme: AppTheme.values[prefs.getInt(PREFS_APP_THEME_KEY) ?? 0]));
      context
          .read<ShowKeySignaturesCubit>()
          .setValue(prefs.getBool(PREFS_SETTINGS_SHOW_KEY_SIGNATURES) ?? false);
      context.read<AllowJubilateMusicSheetsCubit>().setValue(prefs.getBool(PREFS_ALLOW_JUBILATE) ?? false);
      context.read<AllowCorMusicSheetsCubit>().setValue(prefs.getBool(PREFS_ALLOW_COR) ?? false);
    });
    developer.log("${DateTime.now()} Init state");
    _loadBooks();

    // Cloud sync: reflect remotely-applied favorites and custom lists in the
    // loaded books, then restore the persisted signed-in state (offline-safe)
    // and run an opportunistic background sync.
    SyncService.instance?.onSyncedDataApplied = () {
      _bookService.reloadFavorites();
      _bookService.reloadCustomLists();
      _loadBooks();
    };
    context
        .read<AuthCubit>()
        .load()
        .then((_) => SyncService.instance?.onAppStart());
  }

  Future<void> _handleLogin() async {
    final authCubit = context.read<AuthCubit>();
    GoogleSignInAccount? account;
    try {
      if (kIsWeb) {
        // The rendered Google button needs the SDK to be initialized.
        await authCubit.ensureInitialized();
        account = await showDialog<GoogleSignInAccount>(
          context: context,
          builder: (_) => WebSignInDialog(authCubit: authCubit),
        );
      } else {
        account = await authCubit.signInInteractive();
      }
    } catch (e) {
      showToast("Conectarea cu Google a eșuat. Încearcă mai târziu.", _fToast);
      return;
    }
    if (account == null) {
      // User canceled.
      return;
    }

    final ok =
        await SyncService.instance!.handleSignedIn(askImport: _askImport);
    if (!ok) {
      await authCubit.signOut();
      showToast(
          "A apărut o eroare la sincronizare.\nVerifică dacă ai conexiune la internet și încearcă din nou.",
          _fToast);
      return;
    }
    await authCubit.completeSignIn(account);
    showToast("Conectat ca ${account.email}", _fToast);
  }

  Future<bool> _askImport() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Prima conectare"),
        content: Text(
            "Vrei să muți în acest cont lista de favorite, listele personalizate, setările și accesul la partituri de pe acest dispozitiv?\n\n"
            "Dacă le muți, ele vor fi disponibile doar cât timp ești conectat: după deconectare, aplicația revine la setările inițiale.\n\n"
            "Dacă nu, contul pornește gol, iar datele rămân pe dispozitiv pentru folosirea fără cont."),
        actions: [
          TextButton(
            child: Text("Nu, cont gol"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text("Mută în cont"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Deconectare"),
            content: Text(
                "Te deconectezi de la contul Google?\nDatele contului vor rămâne salvate în cloud."),
            actions: [
              TextButton(
                child: Text("Anulează"),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text("Deconectare"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    final ok = await SyncService.instance!.handleSignOut();
    if (!ok) {
      showToast(
          "Deconectarea necesită internet pentru a salva modificările nesincronizate.",
          _fToast);
      return;
    }
    await context.read<AuthCubit>().signOut();
    showToast("Te-ai deconectat", _fToast);
  }

  /// Rebuilds the pinned custom-list virtual books from the service state.
  /// Called when returning from screens that may have changed the lists.
  Future<void> _refreshCustomListBooks() async {
    if (_books.isEmpty) {
      return;
    }
    final allSongs =
        _books.firstWhere((b) => b.id == ALL_SONGS_BOOK_ID).songSummaries;
    final listBooks = await _bookService.buildPinnedListBooks(allSongs);
    if (!mounted) {
      return;
    }
    setState(() {
      _books = _books
          .where((b) => !b.id.startsWith(CUSTOM_LIST_ID_PREFIX))
          .toList()
        ..addAll(listBooks);
      if (!_books.any((b) => b.id == _crtBookId)) {
        _crtBookId = ALL_SONGS_BOOK_ID;
      }
    });
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
        goToSongsHistory: () async {
          final fullSongs = await _songs;
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SongsHistoryScreen(
                  songs: fullSongs,
                  bookService: _bookService,
                  setFavorite: _setFavorite,
                ),
              )).then((_) => _refreshCustomListBooks());
          return;
        },
        goToCategories: () async {
          final fullSongs = await _songs;
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoriesScreen(
                  songs: fullSongs,
                  bookService: _bookService,
                  setFavorite: _setFavorite,
                ),
              )).then((_) => _refreshCustomListBooks());
          return;
        },
        goToCustomLists: () async {
          final fullSongs = await _songs;
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomListsScreen(
                  songs: fullSongs,
                  bookService: _bookService,
                  setFavorite: _setFavorite,
                ),
              )).then((_) => _refreshCustomListBooks());
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
        onLogin: () {
          Navigator.pop(context); // close the drawer
          _handleLogin();
        },
        onLogout: () {
          Navigator.pop(context); // close the drawer
          _handleLogout();
        },
      ),
      appBar: AppBar(
        title: DropdownButton<String>(
          value: _crtBookId,
          dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
          iconEnabledColor:
              Theme.of(context).primaryTextTheme.titleLarge!.color,
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
                        : book.id.startsWith(CUSTOM_LIST_ID_PREFIX)
                            ? Padding(
                                padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
                                child: Icon(Icons.playlist_play,
                                    color: Colors.white))
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
                        darkColor: COLOR_LIGHT_BLUE.withValues(alpha: 0.4),
                      ),
                      HorizontalButton(
                        callback: () => _changeBook(ALL_SONGS_BOOK_ID),
                        visible: _crtBookId != ALL_SONGS_BOOK_ID &&
                            _searchString.trim().length > 0,
                        text: "Caută în toate cărțile",
                        color: COLOR_DARKER_BLUE,
                        darkColor: COLOR_LIGHT_BLUE.withValues(alpha: 0.4),
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
                        darkColor: COLOR_LIGHT_BLUE.withValues(alpha: 0.4),
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
                        darkColor: COLOR_LIGHT_BLUE.withValues(alpha: 0.4),
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
                _songsHistoryService.addSong(song.id);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SongScreen(
                        song: fullSongs.lookup(song)!,
                        bookService: _bookService,
                        setFavorite: _setFavorite,
                      ),
                    )).then((_) => _refreshCustomListBooks());
                return;
              },
            ),
          )
        ],
      ),
    );
  }
}
