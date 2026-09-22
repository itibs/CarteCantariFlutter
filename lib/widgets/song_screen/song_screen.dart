import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/services/book_service.dart';
import 'package:ccc_flutter/widgets/common/app_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'music_sheet_body/music_sheet_body.dart';
import 'save_to_list_sheet.dart';
import 'song_audio_mini_player.dart';
import 'text_body/song_body.dart';

enum _SongOverflowAction { share, youtube }

class SongScreen extends StatefulWidget {
  final Song song;
  final List<String>? musicSheet;
  final BookService bookService;
  final void Function(SongSummary, bool) setFavorite;

  SongScreen({
    Key? key,
    required this.song,
    required this.bookService,
    required this.setFavorite,
  }) : musicSheet = song.musicSheetPDFs ?? song.musicSheet,
       super(key: key);

  @override
  _SongScreenState createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  double _textSize;
  bool _isFavorite;
  bool _isMusicSheetAvailable = false;
  bool _showMusicSheet = false;
  bool _audioBarOpen = false;
  bool _hasStartedPlayback = false;
  String? _audioError;
  AudioPlayer? _songAudioPlayer;

  static const DEFAULT_TEXT_SIZE = 21.0;
  static const k = 1.2;

  _SongScreenState() : _isFavorite = false, _textSize = DEFAULT_TEXT_SIZE;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    if (widget.song.audioUrl != null) {
      _songAudioPlayer = AudioPlayer();
    }
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _textSize = prefs.getDouble(PREFS_TEXT_SIZE_KEY) ?? DEFAULT_TEXT_SIZE;
        _isMusicSheetAvailable = isMusicSheetAvailable(prefs.getBool(PREFS_ALLOW_JUBILATE) ?? false, prefs.getBool(PREFS_ALLOW_COR) ?? false);
      });
    });
    widget.bookService.checkIsFavorite(widget.song).then((result) {
      if (mounted) {
        setState(() {
          _isFavorite = result;
        });
      }
    });
  }

  @override
  void dispose() {
    _songAudioPlayer?.dispose();
    WakelockPlus.disable();
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
    final hasAudio = widget.song.audioUrl != null;
    final youtubeUri = widget.song.youtubeLaunchUri;

    return PopScope(
      canPop: !_audioBarOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closeAudioBar();
        }
      },
      child: OrientationBuilder(
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
                      widget.bookService.setFavorite(widget.song, _isFavorite);
                      widget.setFavorite(widget.song, _isFavorite);
                    });
                  },
                  iconSize: 30.0,
                ),
                IconButton(
                  icon: Icon(Icons.playlist_add),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => SaveToListSheet(
                        song: widget.song,
                        bookService: widget.bookService,
                      ),
                    );
                  },
                  iconSize: 30.0,
                ),
                if (hasAudio)
                  IconButton(
                    tooltip: 'Ascultă în aplicație',
                    icon: Icon(
                      _audioBarOpen ? Icons.headphones : Icons.headphones_outlined,
                    ),
                    onPressed: _toggleAudioBar,
                    iconSize: 30.0,
                  ),
                IconButton(
                  icon: Icon(Icons.tonality),
                  onPressed: () {
                    BlocProvider.of<ThemeBloc>(context).add(ThemeChanged());
                  },
                  iconSize: 30.0,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
                  child: PopupMenuButton<_SongOverflowAction>(
                    tooltip: 'Mai multe',
                    icon: Icon(Icons.more_vert),
                    iconSize: 30.0,
                    onSelected: _onOverflowSelected,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _SongOverflowAction.share,
                        child: Text('Distribuie'),
                      ),
                      if (youtubeUri != null)
                        PopupMenuItem(
                          value: _SongOverflowAction.youtube,
                          child: Text('Deschide în YouTube'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            body: _showMusicSheet
                ? MusicSheetBody.createMusicSheetBody(widget.musicSheet!)
                : SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                                  color: Theme.of(context)
                                                      .dividerColor))),
                                    ),
                                  )
                                : Container(),
                            Expanded(
                              child: AppScrollbar(
                                builder: (context, controller) =>
                                    SingleChildScrollView(
                                  controller: controller,
                                  child: SongBody(
                                    song: widget.song,
                                    textSize: _textSize * k - (k - 1) * 20.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            floatingActionButton: _isMusicSheetAvailable
                ? FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _showMusicSheet = !_showMusicSheet;
                      });
                    },
                    shape: CircleBorder(),
                    backgroundColor:
                        Theme.of(context).appBarTheme.backgroundColor,
                    child: _showMusicSheet
                        ? const Icon(Icons.notes, color: Colors.white)
                        : const Icon(Icons.queue_music, color: Colors.white),
                  )
                : null,
            bottomNavigationBar: _audioBarOpen && _songAudioPlayer != null
                ? SongAudioMiniPlayer(
                    player: _songAudioPlayer!,
                    showPlayHint: !_hasStartedPlayback,
                    errorMessage: _audioError,
                    onPlayed: () {
                      if (!_hasStartedPlayback) {
                        setState(() {
                          _hasStartedPlayback = true;
                        });
                      }
                    },
                    onClose: _closeAudioBar,
                  )
                : null,
          );
        },
      ),
    );
  }

  void _toggleAudioBar() {
    if (_audioBarOpen) {
      _closeAudioBar();
    } else {
      _openAudioBar();
    }
  }

  Future<void> _openAudioBar() async {
    _songAudioPlayer ??= AudioPlayer();
    setState(() {
      _audioBarOpen = true;
    });
    await _prepareAudio();
  }

  Future<void> _prepareAudio() async {
    final player = _songAudioPlayer;
    final url = widget.song.audioUrl;
    if (player == null || url == null) {
      return;
    }
    if (player.audioSource != null && _audioError == null) {
      return;
    }
    try {
      await player.setUrl(url);
      if (mounted) {
        setState(() {
          _audioError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _audioError = 'Nu s-a putut încărca muzica';
        });
      }
    }
  }

  Future<void> _closeAudioBar() async {
    try {
      await _songAudioPlayer?.pause();
      await _songAudioPlayer?.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _audioBarOpen = false;
      });
    }
  }

  Future<void> _onOverflowSelected(_SongOverflowAction action) async {
    switch (action) {
      case _SongOverflowAction.share:
        await SharePlus.instance
            .share(ShareParams(text: widget.song.text));
        break;
      case _SongOverflowAction.youtube:
        final uri = widget.song.youtubeLaunchUri;
        if (uri != null) {
          await _openYoutube(uri);
        }
        break;
    }
  }

  Future<void> _openYoutube(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool isMusicSheetAvailable(bool allowJubilate, bool allowCor) {
    if (widget.song.bookId == "J" && !allowJubilate) {
      return false;
    }
    if (widget.song.bookId == "Cor" && !allowCor) {
      return false;
    }
    if (widget.musicSheet == null) {
      return false;
    }
    return widget.musicSheet!.length > 0;
  }
}
