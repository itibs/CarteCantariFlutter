import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/models/custom_list.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/repositories/book_repository/book_mobile_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_server_repository.dart';
import 'package:ccc_flutter/repositories/custom_lists_repository/custom_lists_mobile_repository.dart';
import 'package:ccc_flutter/repositories/custom_lists_repository/custom_lists_repository.dart';
import 'package:ccc_flutter/repositories/custom_lists_repository/custom_lists_web_repository.dart';
import 'package:ccc_flutter/repositories/favorites_repository/favorites_mobile_repository.dart';
import 'package:ccc_flutter/repositories/favorites_repository/favorites_repository.dart';
import 'package:ccc_flutter/repositories/favorites_repository/favorites_web_repository.dart';
import 'package:ccc_flutter/services/sync_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BookService {
  IBookRepository _bookRepository;
  IFavoritesRepository _favoritesRepository;
  ICustomListsRepository _customListsRepository;

  Future<Set<String>>? _favoritesFuture;
  Set<String>? _favorites;

  Future<List<CustomList>>? _customListsFuture;
  List<CustomList>? _customLists;

  BookService(
      {IBookRepository? bookRepository,
      IFavoritesRepository? favoritesRepository,
      ICustomListsRepository? customListsRepository})
      : _bookRepository = bookRepository ??
            (kIsWeb ? BookServerRepository() : BookMobileRepository()),
        _favoritesRepository = favoritesRepository ??
            (kIsWeb
                ? FavoritesWebRepository()
                : FavoritesMobileRepository()),
        _customListsRepository = customListsRepository ??
            (kIsWeb
                ? CustomListsWebRepository()
                : CustomListsMobileRepository()) {
    _favoritesFuture = _favoritesRepository.getFavorites();
    _customListsFuture = _customListsRepository.getLists();
  }

  Future<void> _ensureFavoritesLoaded() async {
    _favorites ??= await _favoritesFuture;
  }

  Future<void> _ensureCustomListsLoaded() async {
    _customLists ??= await _customListsFuture;
  }

  /// Drops the in-memory favorites cache so the next book load re-reads them
  /// from storage. Used after cloud sync rewrites the stored favorites.
  void reloadFavorites() {
    _favorites = null;
    _favoritesFuture = _favoritesRepository.getFavorites();
  }

  /// Drops the in-memory custom lists cache so the next book load re-reads
  /// them from storage. Used after cloud sync rewrites the stored lists.
  void reloadCustomLists() {
    _customLists = null;
    _customListsFuture = _customListsRepository.getLists();
  }

  Stream<BookPackage> getBookPackage({bool forceResync = false}) async* {
    await _ensureFavoritesLoaded();
    await _ensureCustomListsLoaded();
    final favorites = _favorites!;

    await for (var bookPackage
        in _bookRepository.getBookPackage(forceResync: forceResync)) {
      final realBooks = bookPackage.books;
      final allSongs =
          realBooks.map((b) => b.songSummaries).expand((l) => l).toList();
      final favSongs = allSongs
          .where((s) => favorites.contains(s.id) || favorites.contains(s.idV1))
          .toList();
      final allSongsBook = Book(
        title: "Toate cântările",
        id: ALL_SONGS_BOOK_ID,
        songSummaries: allSongs,
      );
      final favoritesBook = Book(
        title: "Lista mea",
        id: FAVORITES_ID,
        songSummaries: favSongs,
      );
      yield BookPackage(
          books: []
            ..add(allSongsBook)
            ..addAll(realBooks)
            ..add(favoritesBook)
            ..addAll(_buildPinnedListBooks(allSongs)),
          songs: bookPackage.songs);
    }
  }

  Future<bool> checkIsFavorite(SongSummary song) async {
    await _ensureFavoritesLoaded();
    return _favorites!.contains(song.id) || _favorites!.contains(song.idV1);
  }

  Future<void> setFavorite(SongSummary song, bool value) async {
    await _ensureFavoritesLoaded();
    final favorites = _favorites!;

    if (value) {
      favorites.add(song.id);
    } else {
      favorites.remove(song.id);
      favorites.remove(song.idV1);
    }

    await _favoritesRepository.storeFavorites(favorites);
    SyncService.instance?.notifyLocalChange();
  }

  Future<List<CustomList>> getCustomLists() async {
    await _ensureCustomListsLoaded();
    return _customLists!;
  }

  Future<CustomList> createList(String name) async {
    await _ensureCustomListsLoaded();
    final list = CustomList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    _customLists!.add(list);
    await _persistCustomLists();
    return list;
  }

  Future<void> renameList(String listId, String name) async {
    await _ensureCustomListsLoaded();
    final list = _customLists!.where((l) => l.id == listId).toList();
    if (list.isEmpty) {
      return;
    }
    list.first.name = name;
    await _persistCustomLists();
  }

  Future<void> deleteList(String listId) async {
    await _ensureCustomListsLoaded();
    _customLists!.removeWhere((l) => l.id == listId);
    await _persistCustomLists();
  }

  Future<void> setListPinned(String listId, bool pinned) async {
    await _ensureCustomListsLoaded();
    final list = _customLists!.where((l) => l.id == listId).toList();
    if (list.isEmpty) {
      return;
    }
    list.first.pinned = pinned;
    await _persistCustomLists();
  }

  Future<void> addSongToList(String listId, SongSummary song) async {
    await _ensureCustomListsLoaded();
    final list = _customLists!.where((l) => l.id == listId).toList();
    if (list.isEmpty || list.first.songIds.contains(song.id)) {
      return;
    }
    list.first.songIds.add(song.id);
    await _persistCustomLists();
  }

  Future<void> removeSongFromList(String listId, SongSummary song) async {
    await _ensureCustomListsLoaded();
    final list = _customLists!.where((l) => l.id == listId).toList();
    if (list.isEmpty) {
      return;
    }
    list.first.songIds.remove(song.id);
    await _persistCustomLists();
  }

  Future<void> _persistCustomLists() async {
    await _customListsRepository.storeLists(_customLists!);
    SyncService.instance?.notifyLocalChange();
  }

  Future<Set<String>> getListIdsContaining(SongSummary song) async {
    await _ensureCustomListsLoaded();
    return _customLists!
        .where((l) => l.songIds.contains(song.id))
        .map((l) => l.id)
        .toSet();
  }

  /// Resolves a custom list's song ids to summaries, preserving list order.
  List<SongSummary> resolveListSongs(
      CustomList list, List<SongSummary> allSongs) {
    final songsById = {for (var s in allSongs) s.id: s};
    return list.songIds
        .map((id) => songsById[id])
        .whereType<SongSummary>()
        .toList();
  }

  /// Virtual books for the pinned custom lists (home dropdown).
  /// Requires custom lists to be loaded (they are, after [getBookPackage]).
  Future<List<Book>> buildPinnedListBooks(List<SongSummary> allSongs) async {
    await _ensureCustomListsLoaded();
    return _buildPinnedListBooks(allSongs);
  }

  List<Book> _buildPinnedListBooks(List<SongSummary> allSongs) {
    final lists = _customLists ?? [];
    return lists
        .where((l) => l.pinned)
        .map((l) => Book(
              title: l.name,
              id: CUSTOM_LIST_ID_PREFIX + l.id,
              songSummaries: resolveListSongs(l, allSongs),
            ))
        .toList();
  }
}
