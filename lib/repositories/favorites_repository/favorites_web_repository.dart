import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'favorites_repository.dart';

const String FAVORITES_STORAGE_KEY = 'favorites';

class FavoritesWebRepository implements IFavoritesRepository {
  Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final strFavoritesJson = prefs.getString(FAVORITES_STORAGE_KEY);
    if (strFavoritesJson == null) {
      return <String>{};
    }
    final favorites =
        (json.decode(strFavoritesJson) as List<dynamic>).cast<String>();
    return favorites.toSet();
  }

  Future<void> storeFavorites(Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final strFavoritesJson = json.encode(favorites.toList());
    await prefs.setString(FAVORITES_STORAGE_KEY, strFavoritesJson);
  }
}
