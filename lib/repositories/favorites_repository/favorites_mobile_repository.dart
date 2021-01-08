import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

import 'favorites_repository.dart';

const String FAVORITES_FILE = 'favorites.json';

class FavoritesMobileRepository implements IFavoritesRepository {
  Future<Directory> _directory;
  Future<File> _file;

  FavoritesMobileRepository({Future<Directory> directory})
      : _directory = directory ?? getApplicationDocumentsDirectory() {
    _file = Future(() async {
      final directory = await _directory;
      return File('${directory.path}/$FAVORITES_FILE');
    });
  }

  Future<Set<String>> getFavorites() {
    return fetchFavoritesFromFile();
  }

  Future<void> storeFavorites(Set<String> favorites) async {
    final file = await _file;

    final strFavoritesJson = json.encode(favorites.toList());
    await file.writeAsString(strFavoritesJson);

    developer.log("${DateTime.now()} Stored favorites in file");
  }

  Future<Set<String>> fetchFavoritesFromFile() async {
    final file = await _file;
    if (!(await file.exists())) {
      return Set<String>();
    }
    final strFavoritesJson = await file.readAsString();

    developer.log("${DateTime.now()} Loaded favorites from file");

    final favorites =
        (json.decode(strFavoritesJson) as List<dynamic>).cast<String>();
    return favorites.toSet();
  }
}
