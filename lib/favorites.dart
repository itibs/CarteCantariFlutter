import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'dart:developer' as developer;

import 'models/song_summary.dart';

Future<void> setFavorite(SongSummary song, bool value) async {
  final crtFavorites = await fetchFavoritesFromFile();
  if (value) {
    crtFavorites.add(song.id);
  } else {
    if (crtFavorites.contains(song.id)) {
      crtFavorites.remove(song.id);
    }
    if (crtFavorites.contains(song.idV1)) {
      crtFavorites.remove(song.idV1);
    }
  }

  await storeFavorites(crtFavorites);
}

Future<bool> checkIfIsFavorite(SongSummary song) async {
  final crtFavorites = await fetchFavoritesFromFile();
  return crtFavorites.contains(song.id) || crtFavorites.contains(song.idV1);
}

Future<void> storeFavorites(Set<String> favorites,
    [Directory? directory]) async {
  directory ??= await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/favorites.json');

  final strFavoritesJson = json.encode(favorites.toList());
  await file.writeAsString(strFavoritesJson);

  developer.log("${DateTime.now()} Stored favorites in file");
}

Future<Set<String>> fetchFavoritesFromFile() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/favorites.json');
  if (!(await file.exists())) {
    return Set<String>();
  }
  final strFavoritesJson = await file.readAsString();

  developer.log("${DateTime.now()} Loaded favorites from file");

  final favorites =
      (json.decode(strFavoritesJson) as List<dynamic>).cast<String>();
  return favorites.toSet();
}
