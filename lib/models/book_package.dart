import 'book.dart';
import 'song.dart';

class BookPackage {
  final List<Book> books;
  final Future<Set<Song>> songs;

  BookPackage({this.books, this.songs});
}
