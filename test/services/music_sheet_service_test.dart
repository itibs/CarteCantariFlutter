import 'dart:typed_data';

import 'package:ccc_flutter/repositories/music_sheet_repository/music_sheet_repository.dart';
import 'package:ccc_flutter/services/music_sheet_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMusicSheetRepository implements IMusicSheetRepository {
  @override
  Future<List<Uint8List>> getMusicSheet(List<String> fileNames,
      {bool forceResync = false}) async {
    return fileNames.map((_) => Uint8List(0)).toList();
  }
}

void main() {
  final service =
      MusicSheetService(musicSheetRepository: _FakeMusicSheetRepository());

  group('splitListIntoBatches', () {
    test('empty list yields no batches', () {
      expect(service.splitListIntoBatches<int>([], 3), isEmpty);
    });

    test('splits an exact multiple into equal batches', () {
      expect(
        service.splitListIntoBatches([1, 2, 3, 4], 2),
        [
          [1, 2],
          [3, 4],
        ],
      );
    });

    test('last batch holds the remainder', () {
      expect(
        service.splitListIntoBatches([1, 2, 3, 4, 5], 2),
        [
          [1, 2],
          [3, 4],
          [5],
        ],
      );
    });

    test('batch size larger than list returns a single batch', () {
      expect(
        service.splitListIntoBatches([1, 2], 10),
        [
          [1, 2],
        ],
      );
    });
  });

  group('non-mobile repository fallbacks', () {
    test('downloadAllFiles yields 0 for non-mobile repository', () async {
      expect(await service.downloadAllFiles(['a', 'b']).toList(), [0]);
    });

    test('getDownloadedFilesCount returns 0 for non-mobile repository', () async {
      expect(await service.getDownloadedFilesCount(['a']), 0);
    });

    test('getMusicSheet delegates to the repository', () async {
      final result = await service.getMusicSheet(['a', 'b']);
      expect(result.length, 2);
    });
  });
}
