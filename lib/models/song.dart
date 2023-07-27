import 'dart:convert';

import 'package:ccc_flutter/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'song_summary.dart';

class Song extends SongSummary {
  String text;
  String searchableText;
  List<String> musicSheet;

  Song(
      {@required String bookId,
      @required String title,
      int number,
      String author,
      String composer,
      String originalTitle,
      String references,
      String pitch,
      List<String> tags,
      this.musicSheet,
      @required this.text,
      String searchableTitle,
      this.searchableText})
      : super(
            bookId: bookId,
            title: title,
            number: number,
            author: author,
            composer: composer,
            originalTitle: originalTitle,
            references: references,
            pitch: pitch,
            tags: tags);

  factory Song.fromJson(Map<String, dynamic> json, {String bookId}) {
    var text = json['text'];
    var musicSheet = json['music_sheet'];

    SongSummary songSummary = SongSummary.fromJson(json, bookId: bookId);

    var rawTextToSearch = [text, songSummary.author, songSummary.composer, songSummary.originalTitle, songSummary.references].join(" ");
    var searchableText = json['searchable_text'] ?? getSearchable(rawTextToSearch);

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
      'text': text,
      'searchable_title': searchableTitle,
      'searchable_text': searchableText,
    };
    return songJson;
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
