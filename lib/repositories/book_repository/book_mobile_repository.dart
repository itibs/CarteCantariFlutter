import 'dart:io';

import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/repositories/book_repository/book_asset_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_file_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_server_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'book_repository.dart';

const String BOOKS_FILE = 'booksV2.json';

class BookMobileRepository implements IBookRepository {
  BookAssetRepository _bookAssetRepository;
  BookFileRepository _bookFileRepository;
  BookServerRepository _bookServerRepository;
  Future<Directory> _directory;
  Future<bool>? _fileExists;

  BookMobileRepository(
      {BookAssetRepository? bookAssetRepository,
      BookFileRepository? bookFileRepository,
      BookServerRepository? bookServerRepository,
      Future<Directory>? directory})
      : _bookAssetRepository = bookAssetRepository ?? new BookAssetRepository(),
        _bookFileRepository = bookFileRepository ?? new BookFileRepository(),
        _bookServerRepository =
            bookServerRepository ?? new BookServerRepository(),
        _directory = directory ?? getApplicationDocumentsDirectory() {
    _fileExists = _directory.then((dir) {
      final file = File('${dir.path}/$BOOKS_FILE');
      return file.exists();
    });
  }

  Stream<BookPackage> getBookPackage({bool forceResync = false}) async* {
    if (forceResync) {
      yield* getBookPackageFromServer();
      return;
    }

    try {
      yield* _bookFileRepository.getBookPackage();
    } catch (e) {}

    if (await _fileExists!) {
      var prefs = await SharedPreferences.getInstance();
      var crtVersion = prefs.getInt(PREFS_UPDATE_VERSION) ?? 0;
      var lastSync = prefs.getInt(PREFS_LAST_SYNC_TIMESTAMP);
      if (crtVersion < LATEST_UPDATE_VERSION || lastSync == null) {
        // App-forced resync, or no sync checkpoint yet (first run after this
        // feature shipped): do a full download to establish the checkpoint.
        yield* getBookPackageFromServer();
      } else {
        yield* syncModifiedFromServer(lastSync);
      }
      prefs.setInt(PREFS_UPDATE_VERSION, LATEST_UPDATE_VERSION);
      return;
    }

    try {
      yield* _bookAssetRepository.getBookPackage();
    } catch (e) {}

    yield* getBookPackageFromServer();
  }

  Stream<BookPackage> getBookPackageFromServer() async* {
    try {
      final books = await _bookServerRepository.fetchBooksFromServer();
      final fetchedFuture = _bookServerRepository
          .fetchSongsFromServer(books.map((book) => book.id).toList());
      final songsFuture =
          fetchedFuture.then((result) => Set<Song>.from(result.songs));
      yield BookPackage(books: books, songs: songsFuture);

      final fetched = await fetchedFuture;
      final songs = Set<Song>.from(fetched.songs);
      await _bookFileRepository.storeBooksInFile(books);
      await _bookFileRepository.storeSongsInFile(songs);
      await _saveSyncCheckpoint(fetched.maxLastModified ?? 0);
    } catch (e) {}
  }

  /// Fetches only songs modified since [lastSync] (epoch milliseconds), merges
  /// them into the locally cached books/songs, persists the result and yields
  /// the merged package. Yields nothing when there are no changes or when the
  /// server can't be reached.
  Stream<BookPackage> syncModifiedFromServer(int lastSync) async* {
    List<Book> serverBooks;
    try {
      serverBooks =
          await _bookServerRepository.fetchBooksFromServer(modifiedSince: lastSync);
    } catch (e) {
      // Offline or server error: keep using the local cache.
      return;
    }

    List<Book> localBooks;
    Set<Song> localSongs;
    try {
      localBooks = await _bookFileRepository.fetchBooksFromFile();
      localSongs = await _bookFileRepository.fetchSongsFromFile();
    } catch (e) {
      // Local cache unreadable: fall back to a full sync.
      yield* getBookPackageFromServer();
      return;
    }

    final localBookIds = localBooks.map((b) => b.id).toSet();

    late FetchedSongs fetched;
    try {
      final fetches = <Future<FetchedSongs>>[];
      for (final book in serverBooks) {
        if (!localBookIds.contains(book.id)) {
          // New book: fetch all of its songs, since songs that were never
          // stamped with last_modified are absent from filtered results.
          fetches.add(_bookServerRepository.fetchBookSongsFromServer(book.id));
        } else if (book.songSummaries.isNotEmpty) {
          fetches.add(_bookServerRepository.fetchBookSongsFromServer(book.id,
              modifiedSince: lastSync));
        }
      }
      fetched = FetchedSongs.merge(await Future.wait(fetches));
    } catch (e) {
      return;
    }

    final modifiedSongs = fetched.songs;
    if (modifiedSongs.isEmpty && !_booksChanged(localBooks, serverBooks)) {
      return;
    }

    final mergedBooks = _mergeBooks(localBooks, serverBooks, modifiedSongs);
    final mergedSongs = _mergeSongs(localSongs, modifiedSongs, mergedBooks);

    yield BookPackage(books: mergedBooks, songs: Future.value(mergedSongs));

    await _bookFileRepository.storeBooksInFile(mergedBooks);
    await _bookFileRepository.storeSongsInFile(mergedSongs);

    final maxModified = fetched.maxLastModified;
    if (maxModified != null && maxModified > lastSync) {
      await _saveSyncCheckpoint(maxModified);
    }
  }

  /// Server books are authoritative for the book list, metadata and order;
  /// song summaries are the local ones with the modified songs upserted by id.
  List<Book> _mergeBooks(
      List<Book> localBooks, List<Book> serverBooks, List<Song> modifiedSongs) {
    final localBooksById = {for (var book in localBooks) book.id: book};

    final modifiedByBook = <String, List<Song>>{};
    for (final song in modifiedSongs) {
      modifiedByBook.putIfAbsent(song.bookId, () => []).add(song);
    }

    return serverBooks.map((serverBook) {
      final summariesById = <String, SongSummary>{};
      final localBook = localBooksById[serverBook.id];
      if (localBook != null) {
        for (final summary in localBook.songSummaries) {
          summariesById[summary.id] = summary;
        }
      }
      for (final song in modifiedByBook[serverBook.id] ?? const <Song>[]) {
        summariesById[song.id] = _toSummary(song);
      }
      final book = Book(
        id: serverBook.id,
        title: serverBook.title,
        songSummaries: summariesById.values.toList(),
      );
      book.sortSongs();
      return book;
    }).toList();
  }

  Set<Song> _mergeSongs(
      Set<Song> localSongs, List<Song> modifiedSongs, List<Book> mergedBooks) {
    final mergedSongs = Set<Song>.from(localSongs);
    // Song equality is by id, and Set.add keeps the existing element, so
    // remove the outdated versions before adding the fresh ones.
    mergedSongs.removeAll(modifiedSongs);
    mergedSongs.addAll(modifiedSongs);
    // Drop songs of books that no longer exist on the server.
    final bookIds = mergedBooks.map((book) => book.id).toSet();
    mergedSongs.removeWhere((song) => !bookIds.contains(song.bookId));
    return mergedSongs;
  }

  bool _booksChanged(List<Book> localBooks, List<Book> serverBooks) {
    if (localBooks.length != serverBooks.length) {
      return true;
    }
    for (var i = 0; i < localBooks.length; i++) {
      if (localBooks[i].id != serverBooks[i].id ||
          localBooks[i].title != serverBooks[i].title) {
        return true;
      }
    }
    return false;
  }

  SongSummary _toSummary(Song song) => SongSummary(
        bookId: song.bookId,
        title: song.title,
        number: song.number,
        author: song.author,
        composer: song.composer,
        originalTitle: song.originalTitle,
        references: song.references,
        pitch: song.pitch,
        tags: song.tags,
        searchableTitle: song.searchableTitle,
      );

  Future<void> _saveSyncCheckpoint(int checkpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREFS_LAST_SYNC_TIMESTAMP, checkpoint);
  }
}
