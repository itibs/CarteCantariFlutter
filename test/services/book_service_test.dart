import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/models/custom_list.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/services/book_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

SongSummary summary(String book, int number, String title) => SongSummary(
      bookId: book,
      title: title,
      number: number,
      searchableTitle: '',
    );

BookPackage packageWith(List<Book> books) => BookPackage(
      books: books,
      songs: Future.value(<Song>{}),
    );

void main() {
  late MockBookRepository bookRepository;
  late MockFavoritesRepository favoritesRepository;
  late MockCustomListsRepository customListsRepository;

  final bookCC = Book(
    title: 'Cartea CC',
    id: 'CC',
    songSummaries: [summary('CC', 1, 'Alpha'), summary('CC', 2, 'Beta')],
  );
  final bookJJ = Book(
    title: 'Cartea JJ',
    id: 'JJ',
    songSummaries: [summary('JJ', 1, 'Gamma')],
  );

  setUpAll(() {
    registerFallbackValue(<String>{});
    registerFallbackValue(<CustomList>[]);
  });

  setUp(() {
    bookRepository = MockBookRepository();
    favoritesRepository = MockFavoritesRepository();
    customListsRepository = MockCustomListsRepository();
  });

  BookService buildService(Set<String> favorites,
      {List<CustomList>? customLists}) {
    when(() => favoritesRepository.getFavorites())
        .thenAnswer((_) async => favorites);
    when(() => favoritesRepository.storeFavorites(any()))
        .thenAnswer((_) async {});
    when(() => customListsRepository.getLists())
        .thenAnswer((_) async => customLists ?? <CustomList>[]);
    when(() => customListsRepository.storeLists(any()))
        .thenAnswer((_) async {});
    when(() => bookRepository.getBookPackage(
            forceResync: any(named: 'forceResync')))
        .thenAnswer((_) => Stream.value(packageWith([bookCC, bookJJ])));

    return BookService(
      bookRepository: bookRepository,
      favoritesRepository: favoritesRepository,
      customListsRepository: customListsRepository,
    );
  }

  group('getBookPackage', () {
    test('prepends "Toate cântările" and appends "Lista mea"', () async {
      final service = buildService({});
      final package = await service.getBookPackage().first;

      expect(package.books.first.id, ALL_SONGS_BOOK_ID);
      expect(package.books.last.id, FAVORITES_ID);
      // all songs + favorites wrap the two real books.
      expect(package.books.length, 4);
      expect(package.books[1].id, 'CC');
      expect(package.books[2].id, 'JJ');
    });

    test('all-songs book contains every song from real books', () async {
      final service = buildService({});
      final package = await service.getBookPackage().first;

      final allSongs = package.books.first;
      expect(allSongs.songSummaries.length, 3);
    });

    test('favorites book filters by id', () async {
      final service = buildService({'CC1'});
      final package = await service.getBookPackage().first;

      final favorites = package.books.last;
      expect(favorites.songSummaries.map((s) => s.id), ['CC1']);
    });

    test('favorites book also matches legacy idV1', () async {
      // idV1 of CC/2/Beta is "2 Beta".
      final service = buildService({'2 Beta'});
      final package = await service.getBookPackage().first;

      final favorites = package.books.last;
      expect(favorites.songSummaries.map((s) => s.id), ['CC2']);
    });
  });

  group('checkIsFavorite', () {
    test('true when id is stored', () async {
      final service = buildService({'CC1'});
      expect(await service.checkIsFavorite(summary('CC', 1, 'Alpha')), isTrue);
    });

    test('true when legacy idV1 is stored', () async {
      final service = buildService({'1 Alpha'});
      expect(await service.checkIsFavorite(summary('CC', 1, 'Alpha')), isTrue);
    });

    test('false when not stored', () async {
      final service = buildService({});
      expect(await service.checkIsFavorite(summary('CC', 1, 'Alpha')), isFalse);
    });
  });

  group('setFavorite', () {
    test('adding persists the modern id', () async {
      final service = buildService({});
      await service.setFavorite(summary('CC', 1, 'Alpha'), true);

      final captured = verify(() => favoritesRepository.storeFavorites(captureAny()))
          .captured
          .single as Set<String>;
      expect(captured, contains('CC1'));
    });

    test('removing strips both modern and legacy ids', () async {
      final service = buildService({'CC1', '1 Alpha'});
      await service.setFavorite(summary('CC', 1, 'Alpha'), false);

      final captured = verify(() => favoritesRepository.storeFavorites(captureAny()))
          .captured
          .single as Set<String>;
      expect(captured, isNot(contains('CC1')));
      expect(captured, isNot(contains('1 Alpha')));
    });
  });

  group('custom lists CRUD', () {
    test('createList generates an id and persists', () async {
      final service = buildService({});
      final list = await service.createList('Seara');

      expect(list.name, 'Seara');
      expect(list.id, isNotEmpty);
      expect(list.pinned, isFalse);

      final stored = verify(() => customListsRepository.storeLists(captureAny()))
          .captured
          .single as List<CustomList>;
      expect(stored.map((l) => l.name), ['Seara']);
      expect(await service.getCustomLists(), hasLength(1));
    });

    test('renameList changes the name and persists', () async {
      final service = buildService({},
          customLists: [CustomList(id: '1', name: 'Veche')]);
      await service.renameList('1', 'Nouă');

      final lists = await service.getCustomLists();
      expect(lists.single.name, 'Nouă');
      verify(() => customListsRepository.storeLists(any())).called(1);
    });

    test('deleteList removes the list and persists', () async {
      final service = buildService({}, customLists: [
        CustomList(id: '1', name: 'A'),
        CustomList(id: '2', name: 'B'),
      ]);
      await service.deleteList('1');

      final lists = await service.getCustomLists();
      expect(lists.map((l) => l.id), ['2']);
    });

    test('setListPinned toggles the flag and persists', () async {
      final service = buildService({},
          customLists: [CustomList(id: '1', name: 'A')]);
      await service.setListPinned('1', true);

      final lists = await service.getCustomLists();
      expect(lists.single.pinned, isTrue);
    });
  });

  group('custom list membership', () {
    test('addSongToList appends the song id once', () async {
      final service = buildService({},
          customLists: [CustomList(id: '1', name: 'A')]);
      final song = summary('CC', 1, 'Alpha');

      await service.addSongToList('1', song);
      await service.addSongToList('1', song);

      final lists = await service.getCustomLists();
      expect(lists.single.songIds, ['CC1']);
    });

    test('removeSongFromList removes the song id', () async {
      final service = buildService({}, customLists: [
        CustomList(id: '1', name: 'A', songIds: ['CC1', 'JJ1'])
      ]);
      await service.removeSongFromList('1', summary('CC', 1, 'Alpha'));

      final lists = await service.getCustomLists();
      expect(lists.single.songIds, ['JJ1']);
    });

    test('getListIdsContaining returns the lists holding the song', () async {
      final service = buildService({}, customLists: [
        CustomList(id: '1', name: 'A', songIds: ['CC1']),
        CustomList(id: '2', name: 'B', songIds: ['JJ1']),
        CustomList(id: '3', name: 'C', songIds: ['CC1', 'JJ1']),
      ]);

      final ids = await service.getListIdsContaining(summary('CC', 1, 'Alpha'));
      expect(ids, {'1', '3'});
    });
  });

  group('pinned lists in book package', () {
    test('appends only pinned lists after favorites', () async {
      final service = buildService({}, customLists: [
        CustomList(id: '1', name: 'Pinned', songIds: ['CC1'], pinned: true),
        CustomList(id: '2', name: 'Unpinned', songIds: ['JJ1']),
      ]);
      final package = await service.getBookPackage().first;

      // all songs + 2 real books + favorites + 1 pinned list.
      expect(package.books.length, 5);
      expect(package.books[3].id, FAVORITES_ID);
      expect(package.books.last.id, CUSTOM_LIST_ID_PREFIX + '1');
      expect(package.books.last.title, 'Pinned');
      expect(package.books.last.songSummaries.map((s) => s.id), ['CC1']);
    });

    test('preserves list insertion order and skips unknown ids', () async {
      final service = buildService({}, customLists: [
        CustomList(
            id: '1',
            name: 'Pinned',
            songIds: ['JJ1', 'MISSING', 'CC1'],
            pinned: true),
      ]);
      final package = await service.getBookPackage().first;

      final listBook = package.books.last;
      expect(listBook.songSummaries.map((s) => s.id), ['JJ1', 'CC1']);
    });
  });
}
