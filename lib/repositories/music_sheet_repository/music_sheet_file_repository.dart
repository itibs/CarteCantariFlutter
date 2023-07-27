import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:ccc_flutter/repositories/music_sheet_repository/music_sheet_repository.dart';
import 'package:path_provider/path_provider.dart';

const String musicSheetURL =
    'https://cartecantari-music-sheets.s3.eu-central-1.amazonaws.com';

class MusicSheetFileRepository implements IMusicSheetRepository {
  Future<Directory> _directory;

  MusicSheetFileRepository({Future<Directory> directory})
      : _directory = directory ?? getApplicationDocumentsDirectory();

  @override
  Future<List<Uint8List>> getMusicSheet(List<String> fileNames,
      {bool forceResync = false}) async {
    final tasks = fileNames.map((fileName) => fetchFile(fileName));
    final results = await Future.wait(tasks);
    return results;
  }

  Future<bool> fileExists(String fileName) async {
    final directory = await _directory;
    final file = File('${directory.path}/music_sheets/$fileName');
    return file.exists();
  }

  Future<Uint8List> fetchFile(String fileName) async {
    final directory = await _directory;
    final file = File('${directory.path}/music_sheets/$fileName');

    final fileData = await file.readAsBytes();
    developer.log("${DateTime.now()} Retrieved file $fileName from directory");
    return fileData;
  }

  void storeMusicSheet(String fileName, Uint8List fileData) async {
    final directory = await _directory;
    final file = File('${directory.path}/music_sheets/$fileName');
    await file.create(recursive: true);
    await file.writeAsBytes(fileData);
  }

  Future<void> deleteAllFiles() async {
    final directory = await _directory;
    final musicSheetDir = Directory('${directory.path}/music_sheets/');
    final tasks = musicSheetDir.list().asyncMap((entity) async {
      if (entity is File) {
        await entity.delete();
      }
    });
    await tasks.toList();
  }

  Future<int> getDownloadedFilesCount(List<String> fileNames) async {
    var count = 0;
    final directory = await _directory;
    for (var fileName in fileNames) {
      final file = File('${directory.path}/music_sheets/$fileName');
      if (await file.exists()) {
        count++;
      }
    }
    return count;
  }
}
