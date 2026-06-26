import 'package:ccc_flutter/models/song_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongSummary.fromJson', () {
    test('parses a full payload', () {
      final summary = SongSummary.fromJson({
        'book_id': 'CC',
        'title': 'O, ce veste minunată',
        'number': '12',
        'author': 'Autor',
        'composer': 'Compozitor',
        'original_title': 'Original',
        'references': 'Ioan 3:16',
        'pitch': 'G',
        'tags': ['colind', 'craciun'],
      });

      expect(summary.bookId, 'CC');
      expect(summary.title, 'O, ce veste minunată');
      expect(summary.number, 12);
      expect(summary.author, 'Autor');
      expect(summary.composer, 'Compozitor');
      expect(summary.originalTitle, 'Original');
      expect(summary.references, 'Ioan 3:16');
      expect(summary.pitch, 'G');
      expect(summary.tags, ['colind', 'craciun']);
    });

    test('uses fallback bookId when JSON has none', () {
      final summary = SongSummary.fromJson(
        {'title': 'Title', 'number': '1'},
        bookId: 'CC',
      );
      expect(summary.bookId, 'CC');
    });

    test('JSON book_id takes priority over fallback', () {
      final summary = SongSummary.fromJson(
        {'book_id': 'JJ', 'title': 'Title'},
        bookId: 'CC',
      );
      expect(summary.bookId, 'JJ');
    });

    test('number is parsed from string and may be null', () {
      final withNumber =
          SongSummary.fromJson({'book_id': 'CC', 'title': 'T', 'number': '7'});
      final withoutNumber =
          SongSummary.fromJson({'book_id': 'CC', 'title': 'T'});

      expect(withNumber.number, 7);
      expect(withoutNumber.number, isNull);
    });

    test('generates searchableTitle when absent', () {
      final summary = SongSummary.fromJson(
        {'book_id': 'CC', 'title': 'Slavă Ție', 'number': '3'},
      );
      // bookId+num, then bookId num, then title -> normalized
      expect(summary.searchableTitle, 'cc3 cc 3 slava tie');
    });

    test('uses provided searchableTitle when present', () {
      final summary = SongSummary.fromJson({
        'book_id': 'CC',
        'title': 'Whatever',
        'searchable_title': 'precomputed',
      });
      expect(summary.searchableTitle, 'precomputed');
    });
  });

  group('computed getters', () {
    SongSummary make({int? number, String title = 'Title', String book = 'CC'}) {
      return SongSummary(
        bookId: book,
        title: title,
        number: number,
        searchableTitle: 'x',
      );
    }

    test('id uses number when present', () {
      expect(make(number: 5, title: 'T').id, 'CC5');
    });

    test('id falls back to title when number is null', () {
      expect(make(number: null, title: 'T').id, 'CCT');
    });

    test('idV1 is number and title', () {
      expect(make(number: 5, title: 'T').idV1, '5 T');
    });

    test('fullTitle includes number when present', () {
      expect(make(number: 5, title: 'T').fullTitle, 'CC 5. T');
    });

    test('fullTitle omits number when null', () {
      expect(make(number: null, title: 'T').fullTitle, 'CC T');
    });

    test('bookAndNum', () {
      expect(make(number: 5).bookAndNum, 'CC 5');
      expect(make(number: null).bookAndNum, 'CC ');
    });
  });

  group('ordering and equality', () {
    SongSummary make({int? number, String title = 'Title', String book = 'CC'}) {
      return SongSummary(
        bookId: book,
        title: title,
        number: number,
        searchableTitle: 'x',
      );
    }

    test('compareTo sorts by number when both present and differ', () {
      expect(make(number: 1).compareTo(make(number: 2)), lessThan(0));
      expect(make(number: 3).compareTo(make(number: 2)), greaterThan(0));
    });

    test('compareTo falls back to title when numbers equal or missing', () {
      expect(make(number: 1, title: 'A').compareTo(make(number: 1, title: 'B')),
          lessThan(0));
      expect(make(title: 'A').compareTo(make(title: 'B')), lessThan(0));
    });

    test('sorting a list orders by number', () {
      final list = [make(number: 3), make(number: 1), make(number: 2)];
      list.sort();
      expect(list.map((s) => s.number), [1, 2, 3]);
    });

    test('equality and hashCode are based on id', () {
      final a = make(number: 5, title: 'T');
      final b = make(number: 5, title: 'Different');
      final c = make(number: 6, title: 'T');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('works as a Set key', () {
      final set = {make(number: 5), make(number: 5), make(number: 6)};
      expect(set.length, 2);
    });
  });
}
