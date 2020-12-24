import 'package:ccc_flutter/models/book_package.dart';

abstract class IBookRepository {
  Stream<BookPackage> getBookPackage({bool forceResync});
}
