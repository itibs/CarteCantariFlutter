const String ALL_SONGS_BOOK_ID="ALL_SONGS";

List<Song> allSongs(List<Book> books) {
  return books
      .map((b) => b.songs)
      .expand((i) => i)
      .toList();
}

class Book {
  final String name;
  final String id;
  List<Song> songs = [];

  Book({this.name, this.id});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      name: json['name'],
      id: json['id'],
    );
  }
}

class Song implements Comparable<Song> {
  Book book;
  String title;
  int number;
  String text;
  String searchableTitle;

  Song({this.book, this.title, this.number, this.text, this.searchableTitle});

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

    return Song(
      book: book,
      title: title,
      number: number,
      text: text,
      searchableTitle: searchableTitle
    );
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