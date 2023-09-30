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
    try {
      final books = fetchBooksFromFile();
      final songs = fetchSongsFromFile();
      yield new BookPackage(books: await books, songs: songs);
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
