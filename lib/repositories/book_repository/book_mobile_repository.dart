import 'dart:io';

import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/repositories/book_repository/book_asset_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_file_repository.dart';
import 'package:ccc_flutter/repositories/book_repository/book_server_repository.dart';
import 'package:path_provider/path_provider.dart';

import 'book_repository.dart';

const String BOOKS_FILE = 'booksV2.json';

class BookMobileRepository implements IBookRepository {
  BookAssetRepository _bookAssetRepository;
  BookFileRepository _bookFileRepository;
  BookServerRepository _bookServerRepository;
  Future<Directory> _directory;
  Future<bool> _fileExists;

  BookMobileRepository(
      {BookAssetRepository bookAssetRepository,
      BookFileRepository bookFileRepository,
      BookServerRepository bookServerRepository,
      Future<Directory> directory})
      : _bookAssetRepository = bookAssetRepository ?? new BookAssetRepository(),
        _bookFileRepository = bookFileRepository ?? new BookFileRepository(),
        _bookServerRepository =
            bookServerRepository ?? new BookServerRepository(),
        _directory = directory ?? getApplicationDocumentsDirectory() {
    _fileExists = _directory.then((dir) {
      final file = File('${dir.path}/$BOOKS_FILE');
      return file.exists();
    });
  }

  Stream<BookPackage> getBookPackage({bool forceResync = false}) async* {
    if (forceResync) {
      yield* getBookPackageFromServer();
      return;
    }

    try {
      yield* _bookFileRepository.getBookPackage();
    } catch (e) {}

    if (await _fileExists) {
      return;
    }

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
