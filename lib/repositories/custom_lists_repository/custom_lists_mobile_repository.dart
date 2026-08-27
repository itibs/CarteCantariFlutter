import 'dart:convert';
import 'dart:io';
import 'package:ccc_flutter/models/custom_list.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

import 'custom_lists_repository.dart';

const String CUSTOM_LISTS_FILE = 'custom_lists.json';

class CustomListsMobileRepository implements ICustomListsRepository {
  Future<Directory> _directory;
  Future<File>? _file;

  CustomListsMobileRepository({Future<Directory>? directory})
      : _directory = directory ?? getApplicationDocumentsDirectory() {
    _file = Future(() async {
      final directory = await _directory;
      return File('${directory.path}/$CUSTOM_LISTS_FILE');
    });
  }

  Future<List<CustomList>> getLists() async {
    final file = await _file;
    if (!(await file!.exists())) {
      return <CustomList>[];
    }
    final strListsJson = await file.readAsString();

    developer.log("${DateTime.now()} Loaded custom lists from file");

    return (json.decode(strListsJson) as List<dynamic>)
        .map((l) => CustomList.fromJson(l))
        .toList();
  }

  Future<void> storeLists(List<CustomList> lists) async {
    final file = await _file;

    final strListsJson = json.encode(lists.map((l) => l.toJson()).toList());
    await file!.writeAsString(strListsJson);

    developer.log("${DateTime.now()} Stored custom lists in file");
  }
}
