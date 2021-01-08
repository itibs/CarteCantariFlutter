import 'dart:convert';
import 'package:universal_html/html.dart';

import 'favorites_repository.dart';

const String FAVORITES_STORAGE_KEY = 'favorites';

class FavoritesWebRepository implements IFavoritesRepository {
  final Storage _localStorage = window.localStorage;

  Future<Set<String>> getFavorites() {
    if (!_localStorage.containsKey(FAVORITES_STORAGE_KEY)) {
      return Future(() => Set<String>());
    }
    final strFavoritesJson = _localStorage[FAVORITES_STORAGE_KEY];
    final favorites =
        (json.decode(strFavoritesJson) as List<dynamic>).cast<String>();
    return Future(() => favorites.toSet());
  }

  Future<void> storeFavorites(Set<String> favorites) async {
    final strFavoritesJson = json.encode(favorites.toList());
    _localStorage[FAVORITES_STORAGE_KEY] = strFavoritesJson;
  }
}
