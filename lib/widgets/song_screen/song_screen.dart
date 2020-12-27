import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/favorites.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';

import 'song_body.dart';

class SongScreen extends StatefulWidget {
  final Song song;
  final bool isFavorite;
  final Function setFavorite;

  SongScreen({Key key, @required this.song, this.isFavorite, this.setFavorite})
      : super(key: key);

  @override
  _SongScreenState createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  double _textSize;
  bool _isFavorite;

  static const DEFAULT_TEXT_SIZE = 21.0;
  static const k = 1.2;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
    _textSize = DEFAULT_TEXT_SIZE;
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _textSize = prefs.getDouble(PREFS_TEXT_SIZE_KEY) ?? DEFAULT_TEXT_SIZE;
      });
    });
    _isFavorite = widget.isFavorite ?? false;
    checkIfIsFavorite(widget.song).then((result) => {
          setState(() {
            _isFavorite = result;
          })
        });
  }

  @override
  void dispose() {
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _titleFont = TextStyle(
      fontSize: _textSize,
      fontWeight: FontWeight.bold,
    );

    final _titleWidget = Text(
      widget.song.fullTitle,
      overflow: TextOverflow.ellipsis,
      style: _titleFont,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: orientation == Orientation.landscape
                ? _titleWidget
                : Container(),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.zoom_in),
                onPressed: () {
                  setState(() {
                    _textSize += 1;
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setDouble(PREFS_TEXT_SIZE_KEY, _textSize);
                    });
                  });
                },
                iconSize: 30.0,
              ),
              IconButton(
                icon: Icon(Icons.zoom_out),
                onPressed: () {
                  setState(() {
                    _textSize -= 1;
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setDouble(PREFS_TEXT_SIZE_KEY, _textSize);
                    });
                  });
                },
                iconSize: 30.0,
              ),
              IconButton(
                icon: _isFavorite
                    ? Icon(
                        Icons.star,
                        color: isDark ? COLOR_DARK_FAVORITE : COLOR_FAVORITE,
                      )
                    : Icon(Icons.star_border),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                    setFavorite(widget.song, _isFavorite);
                    widget.setFavorite(widget.song, _isFavorite);
                  });
                },
                iconSize: 30.0,
              ),
              IconButton(
                icon: Icon(Icons.share),
                onPressed: () {
                  Share.share(
                    widget.song.text,
                  );
                },
                iconSize: 30.0,
              ),
              Padding(
                child: IconButton(
                  icon: Icon(Icons.tonality),
                  onPressed: () {
                    BlocProvider.of<ThemeBloc>(context).add(ThemeChanged());
                  },
                  iconSize: 30.0,
                ),
                padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
              )
            ],
          ),
          body: Column(
            children: <Widget>[
              orientation == Orientation.portrait
                  ? SizedBox(
                      width: double.infinity,
                      child: Container(
                        child: _titleWidget,
                        padding: EdgeInsets.all(15),
                        alignment: Alignment(0.0, 0.0),
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Theme.of(context).dividerColor))),
                      ),
                    )
                  : Container(),
              Expanded(
                child: SingleChildScrollView(
                  child: SongBody(
                    song: widget.song,
                    textSize: _textSize * k - (k - 1) * 20.0,
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
