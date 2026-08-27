import 'dart:convert';

import 'package:ccc_flutter/helpers.dart';

import 'song_summary.dart';

class Song extends SongSummary {
  String text;
  String searchableText;
  List<String>? musicSheet;
  List<String>? musicSheetPDFs;
  String? youtubeId;

  Song(
      {required String bookId,
      required String title,
      int? number,
      String? author,
      String? composer,
      String? originalTitle,
      String? references,
      String? pitch,
      List<String>? tags,
      this.musicSheet,
      this.musicSheetPDFs,
      this.youtubeId,
      required this.text,
      required String searchableTitle,
      required this.searchableText})
      : super(
            bookId: bookId,
            title: title,
            number: number,
            author: author,
            composer: composer,
            originalTitle: originalTitle,
            searchableTitle: searchableTitle,
            references: references,
            pitch: pitch,
            tags: tags);

  factory Song.fromJson(Map<String, dynamic> json, {String? bookId}) {
    var text = json['text'];
    var musicSheet = json['music_sheet'];
    var musicSheetPDFs = json['music_sheet_pdfs'];

    SongSummary songSummary = SongSummary.fromJson(json, bookId: bookId);

    var rawTextToSearch = [
      text,
      songSummary.author,
      songSummary.composer,
      songSummary.originalTitle,
      songSummary.references
    ].join(" ");
    var searchableText =
        json['searchable_text'] ?? getSearchable(rawTextToSearch);

    return Song(
      bookId: songSummary.bookId,
      title: songSummary.title,
      number: songSummary.number,
      author: songSummary.author,
      composer: songSummary.composer,
      originalTitle: songSummary.originalTitle,
      references: songSummary.references,
      pitch: songSummary.pitch,
      tags: songSummary.tags,
      musicSheet: musicSheet?.cast<String>(),
      musicSheetPDFs: musicSheetPDFs?.cast<String>(),
      youtubeId: json['youtube_id'],
      text: text,
      searchableTitle: songSummary.searchableTitle,
      searchableText: searchableText,
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
      'pitch': pitch,
      'tags': tags,
      'music_sheet': musicSheet,
      'music_sheet_pdfs': musicSheetPDFs,
      'youtube_id': youtubeId,
      'text': text,
      'searchable_title': searchableTitle,
      'searchable_text': searchableText,
    };
    return songJson;
  }

  Uri? get youtubeLaunchUri {
    final value = youtubeId?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return Uri.https('www.youtube.com', '/watch', {'v': value});
  }

  static Set<Song> getSongsSetFromSongsJson(String strSongsJson) {
    final songs = (json.decode(strSongsJson) as List)
        .map((songJson) => Song.fromJson(songJson))
        .toList();
    return Set<Song>.from(songs);
  }

  static String getSongsJsonFromSongsSet(Set<Song> songs) {
    final songsJson = songs.map((song) => song.toJson()).toList();
    return json.encode(songsJson);
  }
}
