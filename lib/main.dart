import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/widgets/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'book.dart';
import 'helpers.dart';
import 'widgets/song_screen.dart';
import 'dart:async';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carte Cantari',
      theme: ThemeData(
        primarySwatch: createMaterialColor(COLOR_BLUE)
      ),
      darkTheme: ThemeData.dark(),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _txtController = TextEditingController();
  var _books = <Book>[];
  var _crtBookId = ALL_SONGS_BOOK_ID;
  var _searchString = "";

  List<Book> getBooks() {
    final allSongsBook = Book(
      name: "Toate cântările",
      id: ALL_SONGS_BOOK_ID,
    );
    allSongsBook.songs = allSongs(_books);
    return []..add(allSongsBook)..addAll(_books);
  }

  Future<List<Book>> fetchBooks() async {
    final response = await http.get('http://185.177.59.158/CarteCantari/books');
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List).map((bookJson) =>
          Book.fromJson(bookJson)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }

  Future<List<Song>> fetchSongs(Book book) async {
    final response = await http.get('http://185.177.59.158/CarteCantari/books/' + book.id);
    if (response.statusCode == 200) {
      Map<String, dynamic> resp = json.decode(response.body);
      return (resp['songs'] as List).map((songJson) =>
          Song.fromJson(songJson, book)).toList();
    } else {
      throw Exception('Failed to load songs for book ' + book.name);
    }
  }

  String getBookTitleById(String bookId) {
    if (bookId == ALL_SONGS_BOOK_ID) {
      return "Toate cântările";
    }
    return _books.firstWhere((book) => book.id == bookId).name;
  }

  Future<void> loadBooks() async {
    final books = await fetchBooks();

    for (var book in books) {
      try {
        final songs = await fetchSongs(book);
        songs.sort((s1, s2) => s1.compareTo(s2));
        books
            .firstWhere((b) => b.id == book.id)
            .songs = songs;
        setState(() {
          _books = books;
        });
      } catch (e) {
        // TODO: show error when fetch failed
      }
    }
  }

  @override
  void initState() {
    super.initState();

    loadBooks();
  }

  Widget _buildSongList() {
    final books = getBooks();
    if (books.length == 0) {
      return Container();
    }
    final List<Song> songs = books
        .firstWhere((b) => b.id == _crtBookId)
        .songs;
    final filteredSongs = songs.where((Song song) => _searchString == "" || song.searchableTitle.contains(_searchString)).toList();
    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        itemCount: filteredSongs.length,
        itemBuilder: (context, i) {
          final index = i;
          return _buildRow(filteredSongs[index]);
    });
  }

  Widget _buildRow(Song song) {
    final numFont = const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      color: COLOR_DARK_BLUE_TRANSPARENT,
    );

    final songTitleFont = const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
    );

    Widget txtNum = Text(
      song.book.id + ' ' + (song.number != null ? song.number.toString() : '') + ' ',
      style: numFont,
    );

    Widget txtTitle = Text(song.title,
      style: songTitleFont,
    );

    return ListTile(
      title: Row(
        children: [txtNum, txtTitle],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongScreen(song: song),
          )
        );
      },
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = getBooks();
    return Scaffold(
      drawer: SideMenu(),
      appBar: AppBar(
        title: DropdownButton<String>(
          value: _crtBookId,
          onChanged: (String value) {
            setState(() {
              _crtBookId = value;
            });
          },
          items: books.map((Book book) {
             return DropdownMenuItem<String>(
               value: book.id,
               child: Text(
                 getBookTitleById(book.id),
                 style: TextStyle(
                     fontSize: 25.0,
                     fontWeight: book.id == _crtBookId ? FontWeight.bold : FontWeight.w300,
                 ),
             ),
            );
          }).toList(),
          underline: Container(),
        )
      ),
      body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
              child: TextField(
                enableInteractiveSelection: false,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.blueGrey,),
                  suffixIcon: Visibility(
                    child: GestureDetector(
                      child: Icon(Icons.clear, color: Colors.blueGrey),
                      onTap: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) => _txtController.clear());
                        setState(() {
                          _searchString = "";
                        });
                      },
                    ),
                    visible: _searchString != "",
                  ),
                  hintText: 'Caută...',
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                  contentPadding: new EdgeInsets.all(0),
                ),
                style: new TextStyle(
                  fontSize: 20.0,
                ),
                onChanged: (String value) {
                  setState(() {
                    _searchString = Song.getSearchable(value);
                  });
                },
                controller: _txtController,
              ),
            ),
            Expanded(
              child: _buildSongList(),
            )
          ],
        ),
    );
  }
}
