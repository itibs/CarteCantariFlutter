import 'package:flutter/material.dart';
import '../book.dart';

class SongScreen extends StatelessWidget {
  final Song song;

  SongScreen({Key key, @required this.song}) : super(key: key);

  final titleFont = const TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  );

  final textFont = const TextStyle(
    fontSize: 20.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(song.fullTitle, style: titleFont,),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: Container(
              child: Text(song.fullTitle, style: titleFont,),
              padding: EdgeInsets.all(15),
              alignment: Alignment(0.0, 0.0),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor)
                  )
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                child: Text(song.text, style: textFont,),
              ),
            ),
          ),
        ],
      )
    );
  }
}