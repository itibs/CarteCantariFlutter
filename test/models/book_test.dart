import 'dart:convert';

import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> bookJson() => {
      'id': 'CC',
      'title': 'Cartea Cântărilor',
      'song_summaries': [
        {'title': 'B song', 'number': '2'},
        {'title': 'A song', 'number': '1'},
      ],
    };

void main() {
  group('Book.fromJson', () {
    test('parses fields and propagates bookId to songs', () {
      final book = Book.fromJson(bookJson());

      expect(book.id, 'CC');
      expect(book.title, 'Cartea Cântărilor');
      expect(book.songSummaries.length, 2);
      expect(book.songSummaries.every((s) => s.bookId == 'CC'), isTrue);
    });
  });

  group('toJson / fromJson round-trip', () {
    test('round-trips through json string', () {
      final original = Book.fromJson(bookJson());
      final restored = Book.fromJson(json.decode(json.encode(original.toJson())));

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(
        restored.songSummaries.map((s) => s.id),
        original.songSummaries.map((s) => s.id),
      );
    });
  });

  group('sortSongs', () {
    test('sorts song summaries in place by number', () {
      final book = Book(
        title: 'T',
        id: 'CC',
        songSummaries: [
          SongSummary(bookId: 'CC', title: 'B', number: 2, searchableTitle: ''),
          SongSummary(bookId: 'CC', title: 'A', number: 1, searchableTitle: ''),
        ],
      );

      book.sortSongs();

      expect(book.songSummaries.map((s) => s.number), [1, 2]);
    });
  });
}
