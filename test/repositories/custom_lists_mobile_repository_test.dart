import 'dart:io';

import 'package:ccc_flutter/models/custom_list.dart';
import 'package:ccc_flutter/repositories/custom_lists_repository/custom_lists_mobile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('custom_lists_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  CustomListsMobileRepository buildRepo() =>
      CustomListsMobileRepository(directory: Future.value(tempDir));

  test('returns an empty list when no file exists', () async {
    final lists = await buildRepo().getLists();
    expect(lists, isEmpty);
  });

  test('stores and retrieves lists', () async {
    final repo = buildRepo();
    await repo.storeLists([
      CustomList(id: '1', name: 'Seara', songIds: ['CC1'], pinned: true),
      CustomList(id: '2', name: 'Tineret'),
    ]);

    final restored = await buildRepo().getLists();
    expect(restored.length, 2);
    expect(restored[0].id, '1');
    expect(restored[0].name, 'Seara');
    expect(restored[0].songIds, ['CC1']);
    expect(restored[0].pinned, isTrue);
    expect(restored[1].id, '2');
    expect(restored[1].pinned, isFalse);
  });

  test('overwrites previously stored lists', () async {
    final repo = buildRepo();
    await repo.storeLists([CustomList(id: '1', name: 'A')]);
    await repo.storeLists([CustomList(id: '2', name: 'B')]);

    final restored = await buildRepo().getLists();
    expect(restored.map((l) => l.id), ['2']);
  });

  test('persists to the expected file name', () async {
    await buildRepo().storeLists([CustomList(id: '1', name: 'A')]);
    final file = File('${tempDir.path}/$CUSTOM_LISTS_FILE');
    expect(await file.exists(), isTrue);
  });
}
