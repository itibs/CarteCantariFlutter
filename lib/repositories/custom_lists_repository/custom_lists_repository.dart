import 'package:ccc_flutter/models/custom_list.dart';

abstract class ICustomListsRepository {
  Future<List<CustomList>> getLists();
  Future<void> storeLists(List<CustomList> lists);
}
