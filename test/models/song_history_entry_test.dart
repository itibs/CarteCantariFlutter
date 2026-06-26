import 'package:ccc_flutter/models/song_history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('file encoding round-trip', () {
    test('toFileEncoding then fromFileEncoding preserves data', () {
      final dt = DateTime(2024, 3, 15, 10, 30);
      final entry = SongsHistoryEntry(songId: 'CC5', dateAdded: dt);

      final encoded = entry.toFileEncoding();
      final restored = SongsHistoryEntry.fromFileEncoding(encoded);

      expect(restored.songId, 'CC5');
      expect(restored.dateAdded, dt);
    });

    test('encoding is "<millis>|<songId>"', () {
      final dt = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final entry = SongsHistoryEntry(songId: 'JJ12', dateAdded: dt);
      expect(entry.toFileEncoding(), '1700000000000|JJ12');
    });
  });

  group('date predicates', () {
    test('isToday is true for now and false otherwise', () {
      expect(isToday(DateTime.now()), isTrue);
      expect(isToday(DateTime.now().subtract(const Duration(days: 2))), isFalse);
    });

    test('isYesterday is true exactly one day before today', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(isYesterday(yesterday), isTrue);
      expect(isYesterday(DateTime.now()), isFalse);
    });
  });

  group('getDayOfWeek', () {
    test('maps known weekdays', () {
      expect(getDayOfWeek(DateTime.monday), 'Luni');
      expect(getDayOfWeek(DateTime.sunday), 'Duminică');
    });

    test('returns empty for invalid input', () {
      expect(getDayOfWeek(0), '');
      expect(getDayOfWeek(8), '');
    });
  });

  group('getMonth', () {
    test('maps known months', () {
      expect(getMonth(1), 'ian');
      expect(getMonth(12), 'dec');
    });

    test('returns empty for invalid input', () {
      expect(getMonth(0), '');
      expect(getMonth(13), '');
    });
  });

  group('getHumanReadableDateAdded', () {
    test('shows "Astăzi" for today', () {
      final now = DateTime.now();
      final entry = SongsHistoryEntry(
        songId: 'x',
        dateAdded: DateTime(now.year, now.month, now.day, 9, 5),
      );
      expect(entry.getHumanReadableDateAdded(), 'Astăzi, 09:05');
    });

    test('shows "Ieri" for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final entry = SongsHistoryEntry(
        songId: 'x',
        dateAdded: DateTime(yesterday.year, yesterday.month, yesterday.day, 14, 7),
      );
      expect(entry.getHumanReadableDateAdded(), 'Ieri, 14:07');
    });

    test('shows full formatted date otherwise', () {
      // 2024-03-15 is a Friday.
      final entry = SongsHistoryEntry(
        songId: 'x',
        dateAdded: DateTime(2024, 3, 15, 8, 3),
      );
      expect(entry.getHumanReadableDateAdded(), 'Vineri, 15 mar 2024, 08:03');
    });
  });
}
