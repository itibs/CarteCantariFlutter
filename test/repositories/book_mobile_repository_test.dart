import 'dart:io';

import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/repositories/book_repository/book_file_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_mobile_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_server_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBookServerRepository extends Mock implements BookServerRepository {}

Song makeSong(
  String bookId,
  int number, {
  String title = 'Song',
  String text = 'text',
}) {
  return Song(
    bookId: bookId,
    title: title,
    number: number,
    text: text,
    searchableTitle: '$bookId $number $title'.toLowerCase(),
    searchableText: text.toLowerCase(),
  );
}

FetchedSongs fetched(List<Song> songs, {int? maxLastModified}) =>
    FetchedSongs(songs: songs, maxLastModified: maxLastModified);

Book makeBook(String id, String title, List<Song> songs) {
  return Book(id: id, title: title, songSummaries: songs.toList());
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  late Directory tempDir;
  late BookFileRepository fileRepository;
  late MockBookServerRepository serverRepository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('book_mobile_repo_test');
    SharedPreferences.setMockInitialValues({});
    fileRepository = BookFileRepository(directory: Future.value(tempDir));
    serverRepository = MockBookServerRepository();
  });

  // Built lazily because the repository checks file existence on construction,
  // so it must be created after the local files are seeded.
  BookMobileRepository buildRepository() => BookMobileRepository(
        bookFileRepository: fileRepository,
        bookServerRepository: serverRepository,
        directory: Future.value(tempDir),
      );

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> seedLocal(List<Book> books, Set<Song> songs) async {
    await fileRepository.storeBooksInFile(books);
    await fileRepository.storeSongsInFile(songs);
  }

  Future<int?> storedCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PREFS_LAST_SYNC_TIMESTAMP);
  }

  group('syncModifiedFromServer', () {
    test('replaces modified songs by id and keeps untouched ones', () async {
      final song1 = makeSong('CC', 1, title: 'Unu', text: 'old text');
      final song2 = makeSong('CC', 2, title: 'Doi', text: 'stays');
      await seedLocal([
        makeBook('CC', 'Carte', [song1, song2])
      ], {
        song1,
        song2
      });

      final modifiedSong1 =
          makeSong('CC', 1, title: 'Unu Nou', text: 'new text');
      when(() => serverRepository.fetchBooksFromServer(
              modifiedSince: any(named: 'modifiedSince')))
          .thenAnswer((_) async => [
                makeBook('CC', 'Carte', [modifiedSong1])
              ]);
      when(() => serverRepository.fetchBookSongsFromServer('CC',
              modifiedSince: any(named: 'modifiedSince')))
          .thenAnswer((_) async => fetched([modifiedSong1], maxLastModified: 5000));

      final packages = await buildRepository().syncModifiedFromServer(1000).toList();

      expect(packages, hasLength(1));
      final songs = await packages.first.songs;
      expect(songs, hasLength(2));
      final updated = songs.firstWhere((s) => s.number == 1);
      expect(updated.text, 'new text');
      expect(updated.title, 'Unu Nou');
      final untouched = songs.firstWhere((s) => s.number == 2);
      expect(untouched.text, 'stays');

      final summaries = packages.first.books.single.songSummaries;
      expect(summaries.map((s) => s.title), containsAll(['Unu Nou', 'Doi']));

      // The merge is persisted so it survives a restart.
      final storedSongs = await fileRepository.fetchSongsFromFile();
      expect(storedSongs.firstWhere((s) => s.number == 1).text, 'new text');
      final storedBooks = await fileRepository.fetchBooksFromFile();
      expect(storedBooks.single.songSummaries.map((s) => s.title),
          containsAll(['Unu Nou', 'Doi']));
    });

    test('adds newly created songs', () async {
      final song1 = makeSong('CC', 1, title: 'Unu');
      await seedLocal([
        makeBook('CC', 'Carte', [song1])
      ], {
        song1
      });

      final newSong = makeSong('CC', 2, title: 'Doi');
      when(() => serverRepository.fetchBooksFromServer(
              modifiedSince: any(named: 'modifiedSince')))
          .thenAnswer((_) async => [
                makeBook('CC', 'Carte', [newSong])
              ]);
      when(() => serverRepository.fetchBookSongsFromServer('CC',
              modifiedSince: any(named: 'modifiedSince')))
          .thenAnswer((_) async => fetched([newSong], maxLastModified: 7000));

      final packages = await buildRepository().syncModifiedFromServer(1000).toList();

      final songs = await packages.single.songs;
      expect(songs.map((s) => s.number), containsAll([1, 2]));
      final summaries = packages.single.books.single.songSummaries;
      expect(summaries, hasLength(2));
      // Summaries stay sorted by number.
      expect(summaries.map((s) => s.number).toList(), [1, 2]);
    });

    test('fully fetches books that are new on the server', () async {
      final song1 = makeSong('CC', 1);
      await seedLocal([
        makeBook('CC', 'Carte', [song1])
      ], {
        song1
      });

      // The new book's songs were never stamped, so its summaries are empty
      // in the filtered response.
      final newBookSong = makeSong('BER', 1, title: 'Noua');
      when(() => serverRepository.fetchBooksFromServer(
              modifiedSince: any(named: 'modifiedSince')))
          .thenAnswer((_) async => [
                makeBook('CC', 'Carte', []),
                makeBook('BER', 'Betania', []),
              ]);
      when(() => serverRepository.fetchBookSongsFromServer('BER'))
          .thenAnswer((_) async => fetched([newBookSong]));

      final packages = await buildRepository().syncModifiedFromServer(1000).toList();

      // New book fetched without a modifiedSince filter.
      verify(() => serverRepository.fetchBookSongsFromServer('BER')).called(1);
      verifyNever(() => serverRepository.fetchBookSongsFromServer('CC',
          modifiedSince: any(named: 'modifiedSince')));

      final books = packages.single.books;
      expect(books.map((b) => b.id).toList(), ['CC', 'BER']);
      expect(books.last.songSummaries.single.title, 'Noua');
      final songs = await packages.single.songs;
      expect(songs.map((s) => s.bookId), containsAll(['CC', 'BER']));
    });

    test('drops books (and their songs) removed on the server', () async {
      final ccSong = makeSong('CC', 1);
      final oldSong = makeSong('OLD', 1);
      await seedLocal([
        makeBook('CC', 'Carte', [ccSong]),
        makeBook('OLD', 'Veche', [oldSong]),
      ], {
        ccSong,
        oldSong
      });

      when(() => serverRepository.fetchBooksFromServer(
              modifiedSince: any(named: 'modifiedSince')))
          .thenAnswer((_) async => [makeBook('CC', 'Carte', [])]);

      final packages = await buildRepository().syncModifiedFromServer(1000).toList();

      expect(packages.single.books.map((b) => b.id).toList(), ['CC']);
      final songs = await packages.single.songs;
      expect(songs.map((s) => s.bookId).toSet(), {'CC'});
    });

    test('advances the checkpoint to the max last_modified received',
        () async {
      final song1 = makeSong('CC', 1);
      await seedLocal([
        makeBook('CC', 'Carte', [song1])
      ], {
        song1
      });

      final modified1 = makeSong('CC', 1);
      final modified2 = makeSong('CC', 2);
      when(() => serverRepository.fetchBooksFromServer(
              modifiedSince: any(named: 'modifiedSince')))
          .thenAnswer((_) async => [
                makeBook('CC', 'Carte', [modified1, modified2])
              ]);
      when(() => serverRepository.fetchBookSongsFromServer('CC',
              modifiedSince: any(named: 'modifiedSince')))
          .thenAnswer(
              (_) async => fetched([modified1, modified2], maxLastModified: 9000));

      await buildRepository().syncModifiedFromServer(1000).toList();

      expect(await storedCheckpoint(), 9000);
    });

    test('yields nothing and changes nothing when there are no updates',
        () async {
      final song1 = makeSong('CC', 1, text: 'original');
      await seedLocal([
        makeBook('CC', 'Carte', [song1])
      ], {
        song1
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PREFS_LAST_SYNC_TIMESTAMP, 1000);

      when(() => serverRepository.fetchBooksFromServer(
              modifiedSince: any(named: 'modifiedSince')))
          .thenAnswer((_) async => [makeBook('CC', 'Carte', [])]);

      final packages = await buildRepository().syncModifiedFromServer(1000).toList();

      expect(packages, isEmpty);
      verifyNever(() => serverRepository.fetchBookSongsFromServer(any(),
          modifiedSince: any(named: 'modifiedSince')));
      expect(await storedCheckpoint(), 1000);
      final storedSongs = await fileRepository.fetchSongsFromFile();
      expect(storedSongs.single.text, 'original');
    });

    test('yields nothing when the server is unreachable', () async {
      final song1 = makeSong('CC', 1);
      await seedLocal([
        makeBook('CC', 'Carte', [song1])
      ], {
        song1
      });

      when(() => serverRepository.fetchBooksFromServer(
              modifiedSince: any(named: 'modifiedSince')))
          .thenThrow(Exception('offline'));

      final packages = await buildRepository().syncModifiedFromServer(1000).toList();

      expect(packages, isEmpty);
    });
  });

  group('getBookPackage', () {
    test('does a full sync and stores a checkpoint when none exists',
        () async {
      final localSong = makeSong('CC', 1, text: 'local');
      await seedLocal([
        makeBook('CC', 'Carte', [localSong])
      ], {
        localSong
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PREFS_UPDATE_VERSION, LATEST_UPDATE_VERSION);

      final serverSong = makeSong('CC', 1, text: 'server');
      when(() => serverRepository.fetchBooksFromServer()).thenAnswer(
        (_) async => [
          makeBook('CC', 'Carte', [serverSong])
        ],
      );
      when(() => serverRepository.fetchSongsFromServer(any())).thenAnswer(
        (_) async => fetched([serverSong], maxLastModified: 3000),
      );

      final packages = await buildRepository().getBookPackage().toList();

      // Local package first, then the full server package.
      expect(packages, hasLength(2));
      verify(() => serverRepository.fetchSongsFromServer(any())).called(1);
      verifyNever(() => serverRepository.getBookPackage());
      expect(await storedCheckpoint(), 3000);
      final storedSongs = await fileRepository.fetchSongsFromFile();
      expect(storedSongs.single.text, 'server');
    });

    test('syncs incrementally when a checkpoint exists', () async {
      final localSong = makeSong('CC', 1, text: 'local');
      await seedLocal([
        makeBook('CC', 'Carte', [localSong])
      ], {
        localSong
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PREFS_UPDATE_VERSION, LATEST_UPDATE_VERSION);
      await prefs.setInt(PREFS_LAST_SYNC_TIMESTAMP, 2000);

      final modified = makeSong('CC', 1, text: 'updated');
      when(() => serverRepository.fetchBooksFromServer(modifiedSince: 2000))
          .thenAnswer((_) async => [
                makeBook('CC', 'Carte', [modified])
              ]);
      when(() =>
              serverRepository.fetchBookSongsFromServer('CC', modifiedSince: 2000))
          .thenAnswer((_) async => fetched([modified], maxLastModified: 5000));

      final packages = await buildRepository().getBookPackage().toList();

      // Local package first, then the merged incremental package.
      expect(packages, hasLength(2));
      verifyNever(() => serverRepository.getBookPackage());
      final songs = await packages.last.songs;
      expect(songs.single.text, 'updated');
      expect(await storedCheckpoint(), 5000);
    });
  });
}
