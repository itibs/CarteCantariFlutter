import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/repositories/book_repository/book_mobile_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_server_repository.dart';
import 'package:ccc_flutter/repositories/favorites_repository/favorites_mobile_repository.dart';
import 'package:ccc_flutter/repositories/favorites_repository/favorites_repository.dart';
import 'package:ccc_flutter/repositories/favorites_repository/favorites_web_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BookService {
  IBookRepository _bookRepository;
  IFavoritesRepository _favoritesRepository;

  Future<Set<String>>? _favoritesFuture;
  Set<String>? _favorites;

  BookService(
      {IBookRepository? bookRepository,
      IFavoritesRepository? favoritesRepository})
      : _bookRepository = bookRepository ??
            (kIsWeb ? new BookServerRepository() : new BookMobileRepository()),
        _favoritesRepository = favoritesRepository ??
            (kIsWeb
                ? new FavoritesWebRepository()
                : new FavoritesMobileRepository()) {
    _favoritesFuture = _favoritesRepository.getFavorites();
  }

  Stream<BookPackage> getBookPackage({bool forceResync = false}) async* {
    final favorites = _favorites ?? await _favoritesFuture;

    await for (var bookPackage
        in _bookRepository.getBookPackage(forceResync: forceResync)) {
      final realBooks = bookPackage.books;
      final allSongs =
          realBooks.map((b) => b.songSummaries).expand((l) => l).toList();
      final favSongs = allSongs
          .where((s) => favorites!.contains(s.id) || favorites.contains(s.idV1))
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
      yield new BookPackage(
          books: []
            ..add(allSongsBook)
            ..addAll(realBooks)
            ..add(favoritesBook),
          songs: bookPackage.songs);
    }
  }

  Future<bool> checkIsFavorite(SongSummary song) async {
    final crtFavorites = await _favoritesRepository.getFavorites();
    return crtFavorites.contains(song.id) || crtFavorites.contains(song.idV1);
  }

  Future<void> setFavorite(String songId, bool value) async {
    final favorites = _favorites ?? await _favoritesFuture;

    if (value) {
      favorites!.add(songId);
    } else if (favorites!.contains(songId)) {
      favorites.remove(songId);
    }

    await _favoritesRepository.storeFavorites(favorites);
  }
}
