import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SongList extends StatelessWidget {
  final List<SongSummary> songs;
  final Future<void> Function(SongSummary) onTap;

  SongList({this.songs, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        itemCount: songs.length,
        itemBuilder: (context, i) {
          final index = i;
          return _buildRow(songs[index], isDark);
        });
  }

  Widget _buildRow(SongSummary song, bool isDark) {
    final numFont = TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w900,
      color: isDark ? COLOR_LIGHT_BLUE : COLOR_DARKER_BLUE,
    );

    final songTitleFont = const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
    );

    Widget txtNum = Text(
      song.bookAndNum + " ",
      style: numFont,
    );

    Widget txtTitle = Flexible(
        child: Text(
      song.title,
      style: songTitleFont,
      overflow: TextOverflow.fade,
      softWrap: false,
    ));

    return ListTile(
      title: Row(
        children: [txtNum, txtTitle],
      ),
      onTap: () async {
        await onTap(song);
      },
      dense: true,
    );
  }
}
