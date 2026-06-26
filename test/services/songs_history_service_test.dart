import 'package:ccc_flutter/models/song_history_entry.dart';
import 'package:ccc_flutter/services/songs_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

void main() {
  late MockSongsHistoryRepository repository;
  late SongsHistoryService service;

  setUp(() {
    repository = MockSongsHistoryRepository();
    service = SongsHistoryService(songsHistoryRepository: repository);
  });

  test('getSongsHistory delegates to the repository', () async {
    final entries = [SongsHistoryEntry(songId: 'CC1')];
    when(() => repository.getSongsHistory()).thenAnswer((_) async => entries);

    expect(await service.getSongsHistory(), entries);
    verify(() => repository.getSongsHistory()).called(1);
  });

  test('addSong forwards the song id to the repository', () async {
    when(() => repository.addSong(any())).thenAnswer((_) async {});

    await service.addSong('CC5');

    verify(() => repository.addSong('CC5')).called(1);
  });
}
