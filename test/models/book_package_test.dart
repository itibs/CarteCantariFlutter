import 'package:ccc_flutter/models/book.dart';
import 'package:ccc_flutter/models/book_package.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookPackage', () {
    test('exposes the books and songs it was built with', () async {
      final books = [
        Book(title: 'T', id: 'CC', songSummaries: const []),
      ];
      final songs = <Song>{
        Song(
          bookId: 'CC',
          title: 'T',
          number: 1,
          text: 'text',
          searchableTitle: 'cc 1 t',
          searchableText: 'text',
        ),
      };

      final package = BookPackage(books: books, songs: Future.value(songs));

      expect(package.books, same(books));
      expect(await package.songs, songs);
    });
  });
}
