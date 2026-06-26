import 'dart:convert';

import 'package:ccc_flutter/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> baseJson() => {
      'book_id': 'CC',
      'title': 'Cântare',
      'number': '4',
      'author': 'Autor',
      'composer': 'Compozitor',
      'original_title': 'Original',
      'references': 'Ref',
      'pitch': 'D',
      'tags': ['tag1'],
      'text': 'Strofa unu',
      'music_sheet': ['a.jpg', 'b.jpg'],
      'music_sheet_pdfs': ['a.pdf'],
    };

void main() {
  group('Song.fromJson', () {
    test('parses song-specific fields', () {
      final song = Song.fromJson(baseJson());

      expect(song.text, 'Strofa unu');
      expect(song.musicSheet, ['a.jpg', 'b.jpg']);
      expect(song.musicSheetPDFs, ['a.pdf']);
      expect(song.number, 4);
      expect(song.bookId, 'CC');
    });

    test('generates searchableText from text + metadata when absent', () {
      final song = Song.fromJson(baseJson());
      // Derived from joining text/author/composer/original/references.
      expect(song.searchableText, contains('strofa unu'));
      expect(song.searchableText, contains('autor'));
    });

    test('uses provided searchable_text when present', () {
      final json = baseJson()..['searchable_text'] = 'precomputed text';
      final song = Song.fromJson(json);
      expect(song.searchableText, 'precomputed text');
    });

    test('handles missing music sheets', () {
      final json = baseJson()
        ..remove('music_sheet')
        ..remove('music_sheet_pdfs');
      final song = Song.fromJson(json);
      expect(song.musicSheet, isNull);
      expect(song.musicSheetPDFs, isNull);
    });
  });

  group('toJson / fromJson round-trip', () {
    test('round-trips through json string', () {
      final original = Song.fromJson(baseJson());
      final encoded = json.encode(original.toJson());
      final restored = Song.fromJson(json.decode(encoded));

      expect(restored.id, original.id);
      expect(restored.text, original.text);
      expect(restored.musicSheet, original.musicSheet);
      expect(restored.musicSheetPDFs, original.musicSheetPDFs);
      expect(restored.searchableText, original.searchableText);
      expect(restored.title, original.title);
      expect(restored.number, original.number);
    });
  });

  group('set serialization helpers', () {
    test('round-trips a set of songs and dedups by id', () {
      final songs = {
        Song.fromJson(baseJson()),
        Song.fromJson(baseJson()..['number'] = '5'),
        // Duplicate id of the first -> should be dropped by the set.
        Song.fromJson(baseJson()),
      };
      expect(songs.length, 2);

      final encoded = Song.getSongsJsonFromSongsSet(songs);
      final restored = Song.getSongsSetFromSongsJson(encoded);

      expect(restored.length, 2);
      expect(
        restored.map((s) => s.id).toSet(),
        songs.map((s) => s.id).toSet(),
      );
    });
  });
}
