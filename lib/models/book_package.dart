import 'book.dart';
import 'song.dart';

class BookPackage {
  final List<Book> books;
  final Future<Set<Song>> songs;

  BookPackage({required this.books, required this.songs});
}
