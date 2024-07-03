import 'package:ccc_flutter/models/song_history_entry.dart';
import 'package:ccc_flutter/repositories/songs_history_repository/songs_history_mobile_repository.dart';
import 'package:ccc_flutter/repositories/songs_history_repository/songs_history_repository.dart';

class SongsHistoryService {
  ISongsHistoryRepository _songsHistoryRepository;

  SongsHistoryService(
      {ISongsHistoryRepository? songsHistoryRepository})
      : _songsHistoryRepository = new SongsHistoryMobileRepository();

  Future<List<SongsHistoryEntry>> getSongsHistory() async {
    return await _songsHistoryRepository.getSongsHistory();
  }

  Future<void> addSong(String songId) async {
    return await _songsHistoryRepository.addSong(songId);
  }
}
