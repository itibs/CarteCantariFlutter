import 'dart:io';

import 'package:ccc_flutter/repositories/songs_history_repository/songs_history_mobile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('history_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  SongsHistoryMobileRepository buildRepo() =>
      SongsHistoryMobileRepository(directory: Future.value(tempDir));

  test('returns an empty list when no file exists', () async {
    expect(await buildRepo().getSongsHistory(), isEmpty);
  });

  test('appends songs and reads them back in order', () async {
    final repo = buildRepo();
    await repo.addSong('CC1');
    await repo.addSong('CC2');

    final history = await buildRepo().getSongsHistory();
    expect(history.map((e) => e.songId), ['CC1', 'CC2']);
  });

  test('stored entries carry a date added', () async {
    final repo = buildRepo();
    final before = DateTime.now().subtract(const Duration(seconds: 1));
    await repo.addSong('CC1');

    final entry = (await buildRepo().getSongsHistory()).single;
    expect(entry.dateAdded.isAfter(before), isTrue);
  });
}
