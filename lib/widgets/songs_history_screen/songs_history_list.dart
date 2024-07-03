import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/models/song.dart';
import 'package:ccc_flutter/models/song_history_entry.dart';
import 'package:flutter/material.dart';

class SongsHistoryList extends StatelessWidget {
  final Future<void> Function(Song song) onTap;
  final Map<String, Song> songById;
  final List<SongsHistoryEntry> songsHistory;

  SongsHistoryList({required songsHistory, required this.onTap, required this.songById}) :
    songsHistory = songsHistory.where((entry) => songById.containsKey(entry.songId)).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        itemCount: songsHistory.length,
        itemBuilder: (context, i) {
          final index = i;
          return _buildRow(songsHistory[index], isDark);
        });
  }

  Widget _buildRow(SongsHistoryEntry entry, bool isDark) {
    var song = songById[entry.songId]!;

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

    Widget txtDateAccessed = Text(
      entry.getHumanReadableDateAdded(),
    );

    return ListTile(
      title: Row(
        children: [txtNum, txtTitle],
      ),
      subtitle: txtDateAccessed,
      onTap: () async {
        await onTap(song);
      },
      dense: true,
    );
  }
}