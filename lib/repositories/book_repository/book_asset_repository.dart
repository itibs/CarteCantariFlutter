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
    try {
      final books = fetchBooksFromAssets();
      final songs = fetchSongsFromAssets();
      yield new BookPackage(books: await books, songs: songs);
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
