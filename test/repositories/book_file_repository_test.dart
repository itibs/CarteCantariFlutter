import 'dart:io';

import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/repositories/book_repository/book_file_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('book_file_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  BookFileRepository buildRepo() =>
      BookFileRepository(directory: Future.value(tempDir));

  final books = [
    Book(
      title: 'Cartea CC',
      id: 'CC',
      songSummaries: [
        SongSummary(bookId: 'CC', title: 'Alpha', number: 1, searchableTitle: ''),
      ],
    ),
  ];

  final songs = <Song>{
    Song(
      bookId: 'CC',
      title: 'Alpha',
      number: 1,
      text: 'text body',
      searchableTitle: 'cc 1 alpha',
      searchableText: 'text body',
    ),
  };

  test('getBookPackage yields nothing when files are missing', () async {
    expect(await buildRepo().getBookPackage().toList(), isEmpty);
  });

  test('stores and reads back books', () async {
    final repo = buildRepo();
    await repo.storeBooksInFile(books);

    final restored = await buildRepo().fetchBooksFromFile();
    expect(restored.single.id, 'CC');
    expect(restored.single.songSummaries.single.title, 'Alpha');
  });

  test('stores and reads back songs', () async {
    final repo = buildRepo();
    await repo.storeSongsInFile(songs);

    final restored = await buildRepo().fetchSongsFromFile();
    expect(restored.single.id, 'CC1');
    expect(restored.single.text, 'text body');
  });

  test('getBookPackage yields stored data once both files exist', () async {
    final repo = buildRepo();
    await repo.storeBooksInFile(books);
    await repo.storeSongsInFile(songs);

    final package = await buildRepo().getBookPackage().first;
    expect(package.books.single.id, 'CC');
    expect((await package.songs).single.id, 'CC1');
  });
}
