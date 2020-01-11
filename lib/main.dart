import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'book.dart';
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
        primarySwatch: Colors.cyan
      ),
      darkTheme: ThemeData.dark(),
      home: MyHomePage(title: 'Toate cântările'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //final _saved = Set<String>();
  final _txtController = TextEditingController();
  var _books = <Book>[];
  var _searchString = "";

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

  @override
  void initState() {
    super.initState();

    fetchBooks().then((books) {
      books.forEach((book) =>
      {
        fetchSongs(book).then((songs) {
          songs.sort((s1, s2) => s1.compareTo(s2));
          books
              .firstWhere((b) => b.id == book.id)
              .songs = songs;
          setState(() {
            _books = books;
          });
        })}
      );
    });
  }

  Widget _buildSongList() {
    final List<Song> allSongs =_books.map((b) => b.songs).expand((i) => i).toList();
    //final filteredSongs = all_songs.where((song) => _searchString == "" || song.)
    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        itemCount: allSongs.length,
        itemBuilder: (context, i) {
          final index = i;
          return _buildRow(allSongs[index]);
    });
  }

  Widget _buildRow(Song song) {
    final numFont = const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    );

    final titleFont = const TextStyle(
      fontSize: 20.0,
    );

    //final bool alreadySaved = _saved.contains(song.getId());

    Widget txtNum = Text(
      song.book.id + ' ' + song.number.toString() + ' ',
      style: numFont,
    );

    Widget txtTitle = Text(song.title,
      style: titleFont,
    );

    return ListTile(
      title: Row(
        children: [txtNum, txtTitle],
      ),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
        ),
      ),
      //body: _buildSongList(),
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
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  contentPadding: new EdgeInsets.all(0),
                ),
                style: new TextStyle(
                  fontSize: 20.0,
                ),
                onChanged: (String value) {
                  setState(() {
                    _searchString = value;
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
