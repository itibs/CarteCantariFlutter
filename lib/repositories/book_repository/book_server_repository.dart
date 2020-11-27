import 'dart:convert';

import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:http/http.dart' as http;

import 'book_repository.dart';

const String BOOKS_FILE = 'booksV2.json';

class BookServerRepository implements IBookRepository {
  Stream<BookPackage> getBookPackage({bool forceResync = false}) async* {
    try {
      final books = await fetchBooksFromServer();
      final songs = fetchSongsFromServer(books.map((book) => book.id).toList());

      yield new BookPackage(books: books, songs: songs);
    } catch (e) {}
  }

  Future<List<Book>> fetchBooksFromServer() async {
    final response =
        await http.get('http://185.177.59.158/CarteCantari/books/v2');

    if (response.statusCode == 200) {
      final books = (json.decode(response.body) as List)
          .map((bookJson) => Book.fromJson(bookJson)..sortSongs())
          .toList();

      return books;
    } else {
      throw Exception('Failed to load books');
    }
  }

  Future<Set<Song>> fetchSongsFromServer(List<String> bookIds) async {
    final songs = (await Future.wait(
            bookIds.map((bookId) => fetchBookSongsFromServer(bookId))))
        .expand((bookSongs) => bookSongs)
        .toList();
    return Set<Song>.from(songs);
  }

  Future<List<Song>> fetchBookSongsFromServer(String bookId) async {
    final response =
        await http.get('http://185.177.59.158/CarteCantari/books/' + bookId);
    if (response.statusCode == 200) {
      Map<String, dynamic> resp = json.decode(response.body);
      return (resp['songs'] as List)
          .map((songJson) => Song.fromJson(songJson, bookId: bookId))
          .toList();
    } else {
      throw Exception('Failed to load songs for book ' + bookId);
    }
  }
}
