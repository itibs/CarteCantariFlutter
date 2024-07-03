import 'dart:io';
import 'package:ccc_flutter/models/song_history_entry.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

import 'songs_history_repository.dart';

const String SONGS_HISTORY_FILE = 'songs_history.json';

class SongsHistoryMobileRepository implements ISongsHistoryRepository {
  Future<Directory> _directory;
  Future<File>? _file;

  SongsHistoryMobileRepository({Future<Directory>? directory})
      : _directory = directory ?? getApplicationDocumentsDirectory() {
    _file = Future(() async {
      final directory = await _directory;
      return File('${directory.path}/$SONGS_HISTORY_FILE');
    });
  }

  @override
  Future<List<SongsHistoryEntry>> getSongsHistory() {
    return fetchSongsHistoryFromFile();
  }

  @override
  Future<void> addSong(String songId) async {
    await appendSongInHistory(SongsHistoryEntry(songId: songId));
  }

  Future<void> appendSongInHistory(SongsHistoryEntry songsHistoryEntry) async {
    final file = await _file;

    try {
      final fileSink = file!.openWrite(mode: FileMode.append);
      fileSink.writeln(songsHistoryEntry.toFileEncoding());
      await fileSink.close();
    } catch (e) {
      developer.log("${DateTime.now()} Error occured while saving history entry: $e");
    }

    developer.log("${DateTime.now()} Stored history in file");
  }

  Future<List<SongsHistoryEntry>> fetchSongsHistoryFromFile() async {
    final file = await _file;
    if (!(await file!.exists())) {
      return List<SongsHistoryEntry>.empty();
    }
    final songsHistoryEntries = (await file.readAsLines()).map((line) => SongsHistoryEntry.fromFileEncoding(line));

    developer.log("${DateTime.now()} Loaded history from file");

    return songsHistoryEntries.toList();
  }
}
