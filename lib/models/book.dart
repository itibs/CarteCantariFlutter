import 'song_summary.dart';

const String ALL_SONGS_BOOK_ID = "ALL_SONGS";
const String FAVORITES_ID = "FAVORITES";

class Book {
  final String id;
  String title;
  List<SongSummary> songSummaries;

  Book({this.title, this.id, this.songSummaries});

  factory Book.fromJson(Map<String, dynamic> json) {
    var bookId = json['id'];
    var songSummaries = (json['song_summaries'] as List)
        .map((s) => SongSummary.fromJson(s, bookId: bookId))
        .toList();

    var book = Book(
      title: json['title'],
      id: json['id'],
      songSummaries: songSummaries,
    );

    return book;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "song_summaries": songSummaries.map((s) => s.toJson()).toList(),
    };
  }

  void sortSongs() {
    songSummaries.sort();
  }
}
