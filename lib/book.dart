import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'dart:developer' as developer;

const String ALL_SONGS_BOOK_ID = "ALL_SONGS";
const String FAVORITES_ID = "FAVORITES";

List<Song> allSongs(List<Book> books) {
  return books
      .map((b) => b.songs)
      .expand((i) => i)
      .toList();
}

List<Song> favoriteSongs(List<Book> books, Set<String> favorites) {
  return books
      .map((b) => b.songs)
      .expand((i) => i)
      .where((s) => favorites.contains(s.getId()))
      .toList();
}

class Book {
  final String id;
  String name;
  List<Song> songs = [];

  Book({this.name, this.id});

  factory Book.fromJson(Map<String, dynamic> json) {
    var book = Book(
      name: json['name'],
      id: json['id'],
    );

    if (json['songs'] != null) {
      book.songs = (json['songs'] as List)
          .map((s) => Song.fromJson(s, book))
          .toList();
    }

    return book;
  }

  factory Book.titlesFromJson(Map<String, dynamic> json) {
    var book = Book(
      name: json['name'],
      id: json['id'],
    );

    if (json['songs'] != null) {
      book.songs = (json['songs'] as List)
          .map((s) => Song.titlesFromJson(s, book))
          .toList();
    }

    return book;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "songs": songs.map((s) => s.toJson()).toList(),
    };
  }

  Map<String, dynamic> titlesToJson() {
    return {
      "id": id,
      "name": name,
      "songs": songs.map((s) => s.titlesToJson()).toList(),
    };
  }
}

class Song implements Comparable<Song> {
  Book book;
  String title;
  int number;
  String text;
  String searchableTitle;
  String searchableText;

  Song({this.book, this.title, this.number, this.text, this.searchableTitle, this.searchableText});

  static String getSearchable(String s) {
    s = s.toLowerCase();
    s =
        s.replaceAll(
            new RegExp(r"[ăâ]"),
            "a"
        ).replaceAll(
            new RegExp(r"[îÎ]"),
            "i"
        ).replaceAll(
            new RegExp(r"[țţ]"),
            "t"
        ).replaceAll(
            new RegExp(r"[șş]"),
            "s"
        ).replaceAll(
            new RegExp(r"[^a-z0-9 ]"),
            " "
        ).split(
            new RegExp(r" +")
        ).join(" ").trim();

    return s;
  }

  factory Song.fromJson(Map<String, dynamic> json, Book book) {
    var title = json['title'];
    var number = json['number'] != null ? int.parse(json['number']) : null;
    var text = json['text'];
    var searchableTitle = book.id + " " + (number != null ? number.toString() : "") + " " + title;
    searchableTitle = getSearchable(searchableTitle);
    final searchableText = getSearchable(text);

    return Song(
      book: book,
      title: title,
      number: number,
      text: text,
      searchableTitle: searchableTitle,
      searchableText: searchableText,
    );
  }

  factory Song.titlesFromJson(Map<String, dynamic> json, Book book) {
    var title = json['title'];
    var number = json['number'] != null ? int.parse(json['number']) : null;
    var text = "";
    var searchableTitle = book.id + " " + (number != null ? number.toString() : "") + " " + title;
    searchableTitle = getSearchable(searchableTitle);
    final searchableText = "";

    return Song(
      book: book,
      title: title,
      number: number,
      text: text,
      searchableTitle: searchableTitle,
      searchableText: searchableText,
    );
  }

  Map<String, dynamic> toJson() {
    final songJson = {
      'title': title,
      'number': number?.toString(),
      'text': text,
    };
    return songJson;
  }

  Map<String, dynamic> titlesToJson() {
    final songJson = {
      'title': title,
      'number': number?.toString(),
    };
    return songJson;
  }

  String getId() {
    return number.toString() + " " + title;
  }

  String get fullTitle {
    return book.id + " " + (number != null ? number.toString() + ". " : "") + title;
  }

  @override
  int compareTo(Song other) {
    if (this.number != other.number) {
      return this.number.compareTo(other.number);
    }
    return this.title.compareTo(other.title);
  }
}

Stream<Book> fetchBooks() async* {
  // verify if existing files
  final stopwatch = Stopwatch()..start();
  final directory = await getApplicationDocumentsDirectory();
  developer.log('getApplicationDocumentsDirectory() executed in ${stopwatch.elapsed}');
  final file = File('${directory.path}/books_song_titles.json');
  if (!(await file.exists())) {
    // return assets for fast retrieval
    for (var book in await fetchBooksFromAssets()) {
      yield book;
    }

    // get updated from server
    await for (var book in fetchBooksFromServer()) {
      yield book;
    }
  } else { // file exists
    stopwatch.reset();
    for (var book in await fetchBooksFromFile(directory)) {
      yield book;
    }

    developer.log('fetchBooksFromFile() executed in ${stopwatch.elapsed}');
  }
}

Future<void> storeBooks(List<Book> books, Directory directory) async {
  var file = File('${directory.path}/books_song_titles.json');
  var booksJson = books
      .map((book) => book.titlesToJson())
      .toList();
  var strBooksJson = json.encode(booksJson);
  await file.writeAsString(strBooksJson);
  file = File('${directory.path}/books.json');
  booksJson = books
      .map((book) => book.toJson())
      .toList();
  strBooksJson = json.encode(booksJson);
  await file.writeAsString(strBooksJson);
  developer.log("${DateTime.now()} Stored books in file");
}

Future<List<Book>> fetchBooksFromFile(Directory directory) async {
  var file = File('${directory.path}/books_song_titles.json');
  var strBooksJson = await file.readAsString();

  final books = (json.decode(strBooksJson) as List)
      .map((bookJson) => Book.titlesFromJson(bookJson))
      .toList();
  developer.log("${DateTime.now()} Loaded books in file");
  file = File('${directory.path}/books.json');
  file.readAsString()
    .then((strBooksJson) {
      final fullBooks = (json.decode(strBooksJson) as List);
      developer.log("Number of full books: ${fullBooks.length}");
      fullBooks.forEach((bookJson){
            final fullBook = Book.fromJson(bookJson);
            developer.log("Loading songs for book ${fullBook.id}");
            books.firstWhere((book) => book.id == fullBook.id)
              .songs = fullBook.songs;
            developer.log("Loaded songs for book ${fullBook.id}");
          });
    });
  return books;
}

Future<List<Book>> fetchBooksFromAssets() async {
  final strBooksJson = await rootBundle.loadString('assets/books.json');
  final books = (json.decode(strBooksJson) as List)
      .map((bookJson) => Book.fromJson(bookJson))
      .toList();

  developer.log("${DateTime.now()} Fetched all books from assets.");
  return books;
}

Stream<Book> fetchBooksFromServer() async* {
  final response = await http.get('http://185.177.59.158/CarteCantari/books');

  if (response.statusCode == 200) {
    final books = (json.decode(response.body) as List)
        .map((bookJson) => Book.fromJson(bookJson))
        .toList();

    for (var book in books) {
      try {
        final songs = await fetchSongsFromServer(book);
        songs.sort((s1, s2) => s1.compareTo(s2));
        book.songs = songs;
        yield book;
        developer.log("${DateTime.now()} Fetched ${book.id} from server.");
      } catch (e) {
        // TODO: do something when fetch failed?
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    storeBooks(books, directory);
  } else {
    throw Exception('Failed to load books');
  }
}

Future<List<Song>> fetchSongsFromServer(Book book) async {
  final response = await http.get('http://185.177.59.158/CarteCantari/books/' + book.id);
  if (response.statusCode == 200) {
    Map<String, dynamic> resp = json.decode(response.body);
    return (resp['songs'] as List).map((songJson) =>
        Song.fromJson(songJson, book)).toList();
  } else {
    throw Exception('Failed to load songs for book ' + book.name);
  }
}