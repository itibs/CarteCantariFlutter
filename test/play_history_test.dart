import 'package:ccc_flutter/play_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePlayDate', () {
    test('parses ISO dates as local calendar days', () {
      expect(parsePlayDate('2026-08-17'), DateTime(2026, 8, 17));
    });

    test('parses European dates', () {
      expect(parsePlayDate('17.08.2026'), DateTime(2026, 8, 17));
      expect(parsePlayDate('17/08/2026'), DateTime(2026, 8, 17));
    });

    test('returns null for empty or invalid values', () {
      expect(parsePlayDate(null), isNull);
      expect(parsePlayDate(''), isNull);
      expect(parsePlayDate('not-a-date'), isNull);
    });
  });

  group('weeklyPlayCounts', () {
    test('matches backend Monday-aligned Sentry-style bins', () {
      final asOf = DateTime(2026, 8, 17); // Monday
      final dates = ['2026-08-17', '2026-08-17', '2026-08-10', '2025-01-01'];
      final counts = weeklyPlayCounts(dates, weeks: 4, asOf: asOf);

      expect(counts, [0, 0, 1, 2]);
    });

    test('keeps empty weeks so sparse history stays a timeline', () {
      final asOf = DateTime(2026, 9, 5);
      final counts = weeklyPlayCounts(['2026-07-30'], weeks: 8, asOf: asOf);
      expect(counts.length, 8);
      expect(counts.where((count) => count > 0).length, 1);
      expect(counts.where((count) => count == 0).length, 7);
    });

    test('ignores dates outside the window', () {
      final asOf = DateTime(2026, 9, 5);
      final counts = weeklyPlayCounts(['2023-09-03'], weeks: 4, asOf: asOf);
      expect(counts, [0, 0, 0, 0]);
    });
  });

  group('labels', () {
    test('playCountLabel', () {
      expect(playCountLabel(0), 'Nu apare în istoric');
      expect(playCountLabel(1), 'Cântată o dată');
      expect(playCountLabel(9), 'Cântată de 9 ori');
    });

    test('formatLastSungAbsolute uses day month year without padding', () {
      expect(formatLastSungAbsolute(DateTime(2026, 1, 1)), '1 ian 2026');
      expect(formatLastSungAbsolute(DateTime(2026, 7, 30)), '30 iul 2026');
    });
  });
}
