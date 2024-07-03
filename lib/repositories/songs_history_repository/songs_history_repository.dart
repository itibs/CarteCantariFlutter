import 'package:ccc_flutter/models/song_history_entry.dart';

abstract class ISongsHistoryRepository {
  Future<List<SongsHistoryEntry>> getSongsHistory();
  Future<void> addSong(String songId);
}
