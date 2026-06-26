import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:flutter/services.dart';

import 'book_repository.dart';

const String BOOKS_ASSET = 'books.json';
const String SONGS_ASSET = 'songs.json';

class BookAssetRepository implements IBookRepository {
  Stream<BookPackage> getBookPackage({bool forceResync = false}) async* {
    // Start both reads in parallel.
    final booksFuture = fetchBooksFromAssets();
    final songsFuture = fetchSongsFromAssets();

    // Songs (the heavy payload) are loaded lazily: consumers only await them
    // when needed (e.g. lyric search). Attach a no-op handler so a read failure
    // can't surface as an unhandled async error before a consumer awaits it.
    // Consumers that do await `songsFuture` still observe the original error.
    unawaited(songsFuture.catchError((Object _) => <Song>{}));

    try {
      final books = await booksFuture;
      // Emit as soon as the lightweight books are ready so the UI can render the
      // song lists without waiting for the heavier songs file to finish reading.
      yield new BookPackage(books: books, songs: songsFuture);
    } catch (e) {}
  }

  Future<List<Book>> fetchBooksFromAssets() async {
    final strBooksJson = await rootBundle.loadString('assets/$BOOKS_ASSET');
    final books = (json.decode(strBooksJson) as List)
        .map((bookJson) => Book.fromJson(bookJson))
        .toList();
    developer.log("${DateTime.now()} Fetched all books from assets.");
    return books;
  }

  Future<Set<Song>> fetchSongsFromAssets() async {
    final strSongsJson = await rootBundle.loadString('assets/$SONGS_ASSET');
    return Song.getSongsSetFromSongsJson(strSongsJson);
  }
}
