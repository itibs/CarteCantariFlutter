import 'package:ccc_flutter/play_history_menu_unlock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 11, 26, 22);

  test('counts taps that stay within one second of each other', () {
    final taps = PlayHistoryTitleTaps();
    var now = start;

    for (var i = 0; i < 4; i++) {
      expect(taps.register(now), isNull);
      now = now.add(const Duration(seconds: 1));
    }

    expect(taps.register(now), 5);
    now = now.add(const Duration(seconds: 1));
    expect(taps.register(now), 4);
  });

  test('a gap longer than one second starts the sequence over', () {
    final taps = PlayHistoryTitleTaps();
    var now = start;

    for (var i = 0; i < 9; i++) {
      taps.register(now);
      now = now.add(const Duration(seconds: 1));
    }

    now = now.add(const Duration(seconds: 1));
    expect(taps.register(now), isNull);
    expect(taps.count, 1);
  });

  test('the tenth tap in time unlocks', () {
    final taps = PlayHistoryTitleTaps();
    var now = start;
    int? last;
    for (var i = 0; i < 10; i++) {
      last = taps.register(now);
      now = now.add(const Duration(seconds: 1));
    }
    expect(last, 0);
  });
}
