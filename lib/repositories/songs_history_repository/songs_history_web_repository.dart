import 'dart:convert';

import 'package:ccc_flutter/models/song_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'songs_history_repository.dart';

const String SONGS_HISTORY_STORAGE_KEY = 'songs_history';

class SongsHistoryWebRepository implements ISongsHistoryRepository {
  @override
  Future<List<SongsHistoryEntry>> getSongsHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(SONGS_HISTORY_STORAGE_KEY);
    if (stored == null) {
      // Must be growable: addSong() calls .add() on the returned list.
      return <SongsHistoryEntry>[];
    }
    final encodedLines =
        (json.decode(stored) as List<dynamic>).cast<String>();
    return encodedLines
        .map((line) => SongsHistoryEntry.fromFileEncoding(line))
        .toList();
  }

  @override
  Future<void> addSong(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getSongsHistory();
    entries.add(SongsHistoryEntry(songId: songId));
    final encodedLines = entries.map((e) => e.toFileEncoding()).toList();
    await prefs.setString(SONGS_HISTORY_STORAGE_KEY, json.encode(encodedLines));
  }
}
