import 'dart:convert';

import 'package:ccc_flutter/models/custom_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes to json and back', () {
    final list = CustomList(
      id: '123',
      name: 'Cântări de seară',
      songIds: ['CC1', 'JJ2'],
      pinned: true,
    );

    final restored = CustomList.fromJson(json.decode(json.encode(list.toJson())));

    expect(restored.id, '123');
    expect(restored.name, 'Cântări de seară');
    expect(restored.songIds, ['CC1', 'JJ2']);
    expect(restored.pinned, isTrue);
  });

  test('defaults to empty songs and unpinned', () {
    final list = CustomList(id: '1', name: 'Lista');
    expect(list.songIds, isEmpty);
    expect(list.pinned, isFalse);
  });

  test('fromJson tolerates missing optional fields', () {
    final list = CustomList.fromJson({'id': '1', 'name': 'Lista'});
    expect(list.songIds, isEmpty);
    expect(list.pinned, isFalse);
  });
}
