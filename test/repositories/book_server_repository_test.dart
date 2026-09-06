import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/repositories/book_repository/book_server_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Song song(int number) => Song(
      bookId: 'CC',
      title: 'S',
      number: number,
      text: 't',
      searchableTitle: 's',
      searchableText: 't',
    );

void main() {
  group('maxLastModifiedFromJson', () {
    test('returns the max last_modified in the payload', () {
      expect(
        maxLastModifiedFromJson([
          {'title': 'A', 'last_modified': 4000},
          {'title': 'B'},
          {'title': 'C', 'last_modified': 9000},
        ]),
        9000,
      );
    });

    test('returns null when no song is stamped', () {
      expect(maxLastModifiedFromJson([{'title': 'A'}, {'title': 'B'}]), isNull);
      expect(maxLastModifiedFromJson([]), isNull);
    });
  });

  group('FetchedSongs.merge', () {
    test('concatenates songs and keeps the max last_modified', () {
      final merged = FetchedSongs.merge([
        FetchedSongs(songs: [song(1)], maxLastModified: 4000),
        FetchedSongs(songs: [song(2), song(3)], maxLastModified: 9000),
        FetchedSongs(songs: [song(4)]),
      ]);

      expect(merged.songs.map((s) => s.number), [1, 2, 3, 4]);
      expect(merged.maxLastModified, 9000);
    });

    test('returns empty when there are no results', () {
      final merged = FetchedSongs.merge([]);
      expect(merged.songs, isEmpty);
      expect(merged.maxLastModified, isNull);
    });
  });
}
