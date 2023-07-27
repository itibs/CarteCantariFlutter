import 'dart:io';
import 'dart:typed_data';

import 'package:ccc_flutter/repositories/music_sheet_repository/music_sheet_file_repository.dart';
import 'package:ccc_flutter/repositories/music_sheet_repository/music_sheet_repository.dart';
import 'package:ccc_flutter/repositories/music_sheet_repository/music_sheet_server_repository.dart';
import 'package:path_provider/path_provider.dart';

class MusicSheetMobileRepository implements IMusicSheetRepository {
  MusicSheetServerRepository _musicSheetServerRepository;
  MusicSheetFileRepository _musicSheetFileRepository;
  Future<Directory> _directory;

  MusicSheetMobileRepository(
      {MusicSheetServerRepository musicSheetServerRepository,
      MusicSheetFileRepository musicSheetFileRepository,
      Future<Directory> directory})
      : _musicSheetServerRepository =
            musicSheetServerRepository ?? new MusicSheetServerRepository(),
        _musicSheetFileRepository =
            musicSheetFileRepository ?? new MusicSheetFileRepository(),
        _directory = directory ?? getApplicationDocumentsDirectory();

  @override
  Future<List<Uint8List>> getMusicSheet(List<String> fileNames,
      {bool forceResync = false}) async {
    if (forceResync) {
      return await _musicSheetServerRepository.getMusicSheet(fileNames);
    }

    try {
      return await _musicSheetFileRepository.getMusicSheet(fileNames);
    } catch (e) {
      final musicSheets =
          await _musicSheetServerRepository.getMusicSheet(fileNames);

      for (int i = 0; i < fileNames.length; i++) {
        _musicSheetFileRepository.storeMusicSheet(fileNames[i], musicSheets[i]);
      }

      return musicSheets;
    }
  }

  Future<int> downloadAllFiles(List<String> fileNames) async {
    var missingFileNames = List.empty(growable: true);
    for (var fileName in fileNames) {
      final fileExists = await _musicSheetFileRepository.fileExists(fileName);
      if (!fileExists) {
        missingFileNames.add(fileName);
      }
    }
    final tasks = missingFileNames.map((fileName) => _musicSheetServerRepository
        .fetchFileFromServer(fileName)
        .then((fileData) =>
            _musicSheetFileRepository.storeMusicSheet(fileName, fileData)));
    await Future.wait(tasks);
    return missingFileNames.length;
  }

  Future<void> deleteAllFiles() async {
    await _musicSheetFileRepository.deleteAllFiles();
  }

  Future<int> getDownloadedFilesCount(List<String> fileNames) async {
    return _musicSheetFileRepository.getDownloadedFilesCount(fileNames);
  }
}
