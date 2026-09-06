import 'dart:convert';

import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'book_repository.dart';

const String BOOKS_FILE = 'booksV2.json';

const String _PROD_API_ID = 'kfq5qib3ec';
const String _DEV_API_ID = '7n1lfiqzdf';

// Use the production API only for release builds; dev/staging builds hit the dev API.
const String _API_ID = kReleaseMode ? _PROD_API_ID : _DEV_API_ID;
const String _API_BASE_URL =
    'https://$_API_ID.execute-api.eu-central-1.amazonaws.com/Prod';

/// Songs fetched from the server, plus the max `last_modified` in that payload
/// (used only to advance the local sync checkpoint).
class FetchedSongs {
  final List<Song> songs;
  final int? maxLastModified;

  const FetchedSongs({required this.songs, this.maxLastModified});

  static FetchedSongs merge(Iterable<FetchedSongs> results) {
    final songs = <Song>[];
    int? maxLastModified;
    for (final result in results) {
      songs.addAll(result.songs);
      final value = result.maxLastModified;
      if (value != null &&
          (maxLastModified == null || value > maxLastModified)) {
        maxLastModified = value;
      }
    }
    return FetchedSongs(songs: songs, maxLastModified: maxLastModified);
  }
}

int? maxLastModifiedFromJson(Iterable jsonList) {
  int? max;
  for (final item in jsonList) {
    if (item is! Map) {
      continue;
    }
    final value = (item['last_modified'] as num?)?.toInt();
    if (value != null && (max == null || value > max)) {
      max = value;
    }
  }
  return max;
}

class BookServerRepository implements IBookRepository {
  Stream<BookPackage> getBookPackage({bool forceResync = false}) async* {
    try {
      final books = await fetchBooksFromServer();
      final fetched = fetchSongsFromServer(books.map((book) => book.id).toList());

      yield new BookPackage(
        books: books,
        songs: fetched.then((result) => Set<Song>.from(result.songs)),
      );
    } catch (e) {}
  }

  Future<List<Book>> fetchBooksFromServer({int? modifiedSince}) async {
    var url = '$_API_BASE_URL/books';
    if (modifiedSince != null) {
      url += '?modifiedSince=$modifiedSince';
    }
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final books = (json.decode(response.body) as List)
          .map((bookJson) => Book.fromJson(bookJson)..sortSongs())
          .toList();

      return books;
    } else {
      throw Exception('Failed to load books');
    }
  }

  Future<FetchedSongs> fetchSongsFromServer(List<String> bookIds) async {
    final results = await Future.wait(
        bookIds.map((bookId) => fetchBookSongsFromServer(bookId)));
    return FetchedSongs.merge(results);
  }

  Future<FetchedSongs> fetchBookSongsFromServer(String bookId,
      {int? modifiedSince}) async {
    var url = '$_API_BASE_URL/books/' + bookId + "/songs";
    if (modifiedSince != null) {
      url += '?modifiedSince=$modifiedSince';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Map<String, dynamic> resp = json.decode(response.body);
      final songsJson = resp['songs'] as List;
      return FetchedSongs(
        songs: songsJson
            .map((songJson) => Song.fromJson(songJson, bookId: bookId))
            .toList(),
        maxLastModified: maxLastModifiedFromJson(songsJson),
      );
    } else {
      throw Exception('Failed to load songs for book ' + bookId);
    }
  }
}
