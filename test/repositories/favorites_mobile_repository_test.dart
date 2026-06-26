import 'dart:io';

import 'package:ccc_flutter/repositories/favorites_repository/favorites_mobile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('favorites_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  FavoritesMobileRepository buildRepo() =>
      FavoritesMobileRepository(directory: Future.value(tempDir));

  test('returns an empty set when no file exists', () async {
    final favorites = await buildRepo().getFavorites();
    expect(favorites, isEmpty);
  });

  test('stores and retrieves favorites', () async {
    final repo = buildRepo();
    await repo.storeFavorites({'CC1', 'JJ2'});

    final restored = await buildRepo().getFavorites();
    expect(restored, {'CC1', 'JJ2'});
  });

  test('overwrites previously stored favorites', () async {
    final repo = buildRepo();
    await repo.storeFavorites({'CC1'});
    await repo.storeFavorites({'JJ9'});

    expect(await buildRepo().getFavorites(), {'JJ9'});
  });

  test('persists to the expected file name', () async {
    await buildRepo().storeFavorites({'CC1'});
    final file = File('${tempDir.path}/$FAVORITES_FILE');
    expect(await file.exists(), isTrue);
  });
}
