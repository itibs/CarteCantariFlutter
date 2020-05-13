import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'dart:developer' as developer;

Future<void> setFavorite(String songId, bool value) async {
  final crtFavorites = await fetchFavoritesFromFile();
  if (value) {
    crtFavorites.add(songId);
  } else if (crtFavorites.contains(songId)) {
    crtFavorites.remove(songId);
  }

  await storeFavorites(crtFavorites);
}

Future<bool> checkIfIsFavorite(String songId) async {
  final crtFavorites = await fetchFavoritesFromFile();
  return crtFavorites.contains(songId);
}

Future<void> storeFavorites(Set<String> favorites,
    [Directory directory]) async {
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