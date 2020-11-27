import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/repositories/book_repository/book_asset_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_file_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_server_repository.dart';

import 'book_repository.dart';

const String BOOKS_FILE = 'booksV2.json';

class BookMobileRepository implements IBookRepository {
  BookAssetRepository _bookAssetRepository;
  BookFileRepository _bookFileRepository;
  BookServerRepository _bookServerRepository;

  BookMobileRepository(
      {BookAssetRepository bookAssetRepository,
      BookFileRepository bookFileRepository,
      BookServerRepository bookServerRepository})
      : _bookAssetRepository = bookAssetRepository ?? new BookAssetRepository(),
        _bookFileRepository = bookFileRepository ?? new BookFileRepository(),
        _bookServerRepository =
            bookServerRepository ?? new BookServerRepository();

  Stream<BookPackage> getBookPackage({bool forceResync = false}) async* {
    if (forceResync) {
      yield* getBookPackageFromServer();
      return;
    }

    try {
      yield* _bookFileRepository.getBookPackage();
      return;
    } catch (e) {}

    try {
      yield* _bookAssetRepository.getBookPackage();
    } catch (e) {}

    yield* getBookPackageFromServer();
  }

  Stream<BookPackage> getBookPackageFromServer() async* {
    await for (var bookPackage in _bookServerRepository.getBookPackage()) {
      yield bookPackage;
      _bookFileRepository.storeBooksInFile(bookPackage.books);
      _bookFileRepository.storeSongsInFile(await bookPackage.songs);
    }
  }
}
