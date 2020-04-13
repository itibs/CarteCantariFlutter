import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/global/theme/bloc/theme_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../book.dart';
import 'formatted_text.dart';

class SongScreen extends StatefulWidget {
  final Song song;

  SongScreen({Key key, @required this.song}) : super(key: key);

  @override
  _SongScreenState createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  double _textSize;
  final k = 1.2;

  static const DEFAULT_TEXT_SIZE = 21.0;

  @override
  void initState() {
    super.initState();
    _textSize = DEFAULT_TEXT_SIZE;
    SharedPreferences.getInstance()
        .then((prefs) {
      setState(() {
        _textSize = prefs.getDouble(PREFS_TEXT_SIZE_KEY) ?? DEFAULT_TEXT_SIZE;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final _titleFont = TextStyle(
      fontSize: _textSize,
      fontWeight: FontWeight.bold,
    );

    final _textFont = TextStyle(
      fontSize: _textSize * k - (k-1) * 20.0,
      color: Theme.of(context).textTheme.title.color,
    );

    final _titleWidget = Text(
      widget.song.fullTitle,
      overflow: TextOverflow.ellipsis,
      style: _titleFont,
    );

    final Map<String, TextStyle> _lyricsFormatting = {
      r"[0-9]+\.": TextStyle(fontWeight: FontWeight.bold),
      r"(Refren|R\b[^ăâîșțĂÂÎȘȚ])": TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
      r"[^0-9].*\bbis\b": TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
    };

    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
            appBar: AppBar(
              title: orientation == Orientation.landscape ? _titleWidget : Container(),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.zoom_in),
                  onPressed: () {
                    setState(() {
                      _textSize += 1;
                      SharedPreferences.getInstance()
                          .then((prefs) {
                        prefs.setDouble(PREFS_TEXT_SIZE_KEY, _textSize);
                      });
                    });
                  },
                  iconSize: 40.0,
                ),
                IconButton(
                  icon: Icon(Icons.zoom_out),
                  onPressed: () {
                    setState(() {
                      _textSize -= 1;
                      SharedPreferences.getInstance()
                          .then((prefs) {
                        prefs.setDouble(PREFS_TEXT_SIZE_KEY, _textSize);
                      });
                    });
                  },
                  iconSize: 40.0,
                ),
                Padding(
                  child: IconButton(
                    icon: Icon(Icons.tonality),
                    onPressed: () {
                      BlocProvider.of<ThemeBloc>(context).add(ThemeChanged());
                    },
                    iconSize: 40.0,
                  ),
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                )
              ],
            ),
            body: Column(
              children: <Widget>[
                orientation == Orientation.portrait ?
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    child: _titleWidget,
                    padding: EdgeInsets.all(15),
                    alignment: Alignment(0.0, 0.0),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Theme.of(context).dividerColor)
                        )
                    ),
                  ),
                ) :
                Container(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                      child: FormattedText(
                        text: widget.song.text,
                        style: _textFont,
                        stylesMap: _lyricsFormatting),
                    ),
                  ),
                ),
              ],
            ),
//            bottomNavigationBar: BottomAppBar(
//              child: Row(
//                mainAxisSize: MainAxisSize.max,
//                mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                children: <Widget>[
//                  SizedBox(
//                    child: Row(
//                      children: <Widget>[
//                        IconButton(
//                          icon: Icon(Icons.zoom_in),
//                          onPressed: () {
//                            setState(() {
//                              _textSize += 1;
//                              SharedPreferences.getInstance()
//                                  .then((prefs) {
//                                prefs.setDouble(PREFS_TEXT_SIZE_KEY, _textSize);
//                              });
//                            });
//                          },
//                          iconSize: 40.0,
//                        ),
//                        IconButton(
//                          icon: Icon(Icons.zoom_out),
//                          onPressed: () {
//                            setState(() {
//                              _textSize -= 1;
//                              SharedPreferences.getInstance()
//                                  .then((prefs) {
//                                prefs.setDouble(PREFS_TEXT_SIZE_KEY, _textSize);
//                              });
//                            });
//                          },
//                          iconSize: 40.0,
//                        ),
//                      ],
//                    )
//                  ),
//                  SizedBox(
//                    height: 50,
//                    child: IconButton(
//                      icon: Icon(Icons.play_arrow),
//                      onPressed: () {
//
//                      },
//                      iconSize: 40.0,
//                    ),
//                  ),
//                ],
//              ),
//              shape: CircularNotchedRectangle(),
//              color: Theme.of(context).primaryColor,
//            ),
        );
      },
    );
  }
}