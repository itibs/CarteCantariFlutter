import 'dart:convert';

import 'package:ccc_flutter/models/custom_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'custom_lists_repository.dart';

const String CUSTOM_LISTS_STORAGE_KEY = 'custom_lists';

class CustomListsWebRepository implements ICustomListsRepository {
  Future<List<CustomList>> getLists() async {
    final prefs = await SharedPreferences.getInstance();
    final strListsJson = prefs.getString(CUSTOM_LISTS_STORAGE_KEY);
    if (strListsJson == null) {
      return <CustomList>[];
    }
    return (json.decode(strListsJson) as List<dynamic>)
        .map((l) => CustomList.fromJson(l))
        .toList();
  }

  Future<void> storeLists(List<CustomList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final strListsJson = json.encode(lists.map((l) => l.toJson()).toList());
    await prefs.setString(CUSTOM_LISTS_STORAGE_KEY, strListsJson);
  }
}
