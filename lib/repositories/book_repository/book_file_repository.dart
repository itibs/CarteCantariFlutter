import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:path_provider/path_provider.dart';

import 'book_repository.dart';

const String BOOKS_FILE = 'booksV2.json';
const String SONGS_FILE = 'songsV2.json';

class BookFileRepository implements IBookRepository {
  Future<Directory> _directory;

  BookFileRepository({Future<Directory>? directory})
      : _directory = directory ?? getApplicationDocumentsDirectory();

  Stream<BookPackage> getBookPackage({bool forceResync = false}) async* {
    // Start both reads in parallel.
    final booksFuture = fetchBooksFromFile();
    final songsFuture = fetchSongsFromFile();

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

  Future<void> storeBooksInFile(List<Book> books) async {
    final directory = await _directory;
    var file = File('${directory.path}/$BOOKS_FILE');
    var booksJson = books.map((book) => book.toJson()).toList();
    var strBooksJson = json.encode(booksJson);
    await file.writeAsString(strBooksJson);
    developer.log("${DateTime.now()} Stored books in file");
  }

  Future<List<Book>> fetchBooksFromFile() async {
    final directory = await _directory;
    var file = File('${directory.path}/$BOOKS_FILE');

    var strBooksJson = await file.readAsString();

    final books = (json.decode(strBooksJson) as List)
        .map((bookJson) => Book.fromJson(bookJson))
        .toList();
    developer.log("${DateTime.now()} Loaded books in file");
    return books;
  }

  Future<void> storeSongsInFile(Set<Song> songs) async {
    final directory = await _directory;
    final file = File('${directory.path}/$SONGS_FILE');
    final strSongsJson = Song.getSongsJsonFromSongsSet(songs);
    await file.writeAsString(strSongsJson);
    developer.log("${DateTime.now()} Stored songs in file");
  }

  Future<Set<Song>> fetchSongsFromFile() async {
    final directory = await _directory;
    final file = File('${directory.path}/$SONGS_FILE');
    final strSongsJson = await file.readAsString();
    return Song.getSongsSetFromSongsJson(strSongsJson);
  }
}
