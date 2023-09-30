import 'dart:typed_data';

import 'package:ccc_flutter/repositories/music_sheet_repository/music_sheet_mobile_repository.dart';
import 'package:ccc_flutter/repositories/music_sheet_repository/music_sheet_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../repositories/music_sheet_repository/music_sheet_server_repository.dart';

class MusicSheetService {
  IMusicSheetRepository _musicSheetRepository;

  MusicSheetService(
      {IMusicSheetRepository? musicSheetRepository})
      : _musicSheetRepository = musicSheetRepository ??
            (kIsWeb ? new MusicSheetServerRepository() : new MusicSheetMobileRepository());

  Future<List<Uint8List>> getMusicSheet(List<String> fileNames, {bool forceResync = false}) async {
    return await _musicSheetRepository.getMusicSheet(fileNames);
  }

  Stream<int> downloadAllFiles(List<String> fileNames) async* {
    if (_musicSheetRepository is MusicSheetMobileRepository) {
      final batches = splitListIntoBatches(fileNames, 300);
      var count = await getDownloadedFilesCount(fileNames);
      for (var batch in batches) {
        count += await (_musicSheetRepository as MusicSheetMobileRepository).downloadAllFiles(batch);
        yield count;
      }
    } else {
      yield 0;
    }
  }

  Future<void> deleteAllFiles() async {
    if (_musicSheetRepository is MusicSheetMobileRepository) {
      await (_musicSheetRepository as MusicSheetMobileRepository).deleteAllFiles();
    }
  }

  Future<int> getDownloadedFilesCount(List<String> fileNames) async {
    if (_musicSheetRepository is MusicSheetMobileRepository) {
      return await (_musicSheetRepository as MusicSheetMobileRepository).getDownloadedFilesCount(fileNames);
    }
    return 0;
  }

  List<List<T>> splitListIntoBatches<T>(List<T> list, int batchSize) {
    List<List<T>> batches = [];
    for (var i = 0; i < list.length; i += batchSize) {
      batches.add(list.sublist(i, i + batchSize > list.length ? list.length : i + batchSize));
    }
    return batches;
  }
}
