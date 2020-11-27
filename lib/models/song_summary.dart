import 'package:ccc_flutter/helpers.dart';
import 'package:flutter/foundation.dart';

class SongSummary implements Comparable<SongSummary> {
  String bookId;
  String title;
  int number;
  String author;
  String composer;
  String originalTitle;
  String references;
  List<String> tags;
  String searchableTitle;

  SongSummary(
      {@required this.bookId,
      @required this.title,
      this.number,
      this.author,
      this.composer,
      this.originalTitle,
      this.references,
      this.tags,
      this.searchableTitle});

  factory SongSummary.fromJson(Map<String, dynamic> json, {String bookId}) {
    bookId = json['book_id'] ?? bookId;
    var title = json['title'];
    var number = json['number'] != null ? int.parse(json['number']) : null;
    var author = json['author'];
    var composer = json['composer'];
    var originalTitle = json['original_title'];
    var references = json['references'];
    var tags = json['tags'];

    var strNumber = number != null ? number.toString() : "";
    var strBookAndNum = bookId + " " + strNumber;
    var strippedBookAndNum = strBookAndNum.replaceAll(" ", "");
    var searchableTitle = json['searchable_title'] ??
        getSearchable(strippedBookAndNum + " " + strBookAndNum + " " + title);

    return SongSummary(
      bookId: bookId,
      title: title,
      number: number,
      author: author,
      composer: composer,
      originalTitle: originalTitle,
      references: references,
      tags: tags?.cast<String>(),
      searchableTitle: searchableTitle,
    );
  }

  Map<String, dynamic> toJson() {
    final songJson = {
      'book_id': bookId,
      'title': title,
      'number': number?.toString(),
      'author': author,
      'composer': composer,
      'original_title': originalTitle,
      'references': references,
      'tags': tags,
      'searchable_title': searchableTitle,
    };
    return songJson;
  }

  String get idV1 {
    return number.toString() + " " + title;
  }

  String get id {
    return bookId + (number?.toString() ?? title);
  }

  String get fullTitle {
    return bookId +
        " " +
        (number != null ? number.toString() + ". " : "") +
        title;
  }

  String get bookAndNum {
    return bookId + " " + (number != null ? number.toString() : "");
  }

  @override
  int compareTo(SongSummary other) {
    if (this.number != other.number) {
      return this.number.compareTo(other.number);
    }
    return this.title.compareTo(other.title);
  }

  @override
  bool operator ==(other) => other is SongSummary && id == other.id;

  @override
  int get hashCode => this.id.hashCode;
}
