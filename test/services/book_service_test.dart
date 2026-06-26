import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/book_package.dart';
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
  });

  setUp(() {
    bookRepository = MockBookRepository();
    favoritesRepository = MockFavoritesRepository();
  });

  BookService buildService(Set<String> favorites) {
    when(() => favoritesRepository.getFavorites())
        .thenAnswer((_) async => favorites);
    when(() => favoritesRepository.storeFavorites(any()))
        .thenAnswer((_) async {});
    when(() => bookRepository.getBookPackage(
            forceResync: any(named: 'forceResync')))
        .thenAnswer((_) => Stream.value(packageWith([bookCC, bookJJ])));

    return BookService(
      bookRepository: bookRepository,
      favoritesRepository: favoritesRepository,
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
}
