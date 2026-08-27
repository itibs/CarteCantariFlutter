import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/repositories/book_repository/book_repository.dart';
import 'package:ccc_flutter/repositories/custom_lists_repository/custom_lists_repository.dart';
import 'package:ccc_flutter/repositories/favorites_repository/favorites_repository.dart';
import 'package:ccc_flutter/repositories/songs_history_repository/songs_history_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockBookRepository extends Mock implements IBookRepository {}

class MockFavoritesRepository extends Mock implements IFavoritesRepository {}

class MockCustomListsRepository extends Mock
    implements ICustomListsRepository {}

class MockSongsHistoryRepository extends Mock
    implements ISongsHistoryRepository {}

class FakeBookPackage extends Fake implements BookPackage {}
