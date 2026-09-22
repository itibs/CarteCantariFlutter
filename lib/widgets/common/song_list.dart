import 'package:ccc_flutter/blocs/settings/show_play_history/show_play_history.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/widgets/common/app_scrollbar.dart';
import 'package:ccc_flutter/widgets/common/play_history_list_subtitle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SongList extends StatelessWidget {
  final List<SongSummary> songs;
  final Future<void> Function(SongSummary) onTap;

  /// When set, rows can be swiped away (end-to-start) to remove them.
  final void Function(SongSummary)? onDismiss;

  SongList({required this.songs, required this.onTap, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showPlayHistory = context.watch<ShowPlayHistoryCubit>().state;

    return AppScrollbar(
      builder: (context, controller) => ListView.builder(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          itemCount: songs.length,
          itemBuilder: (context, i) {
            final index = i;
            final row = _buildRow(songs[index], isDark, showPlayHistory);
            if (onDismiss == null) {
              return row;
            }
            return Dismissible(
              key: ValueKey(songs[index].id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => onDismiss!(songs[index]),
              child: row,
            );
          }),
    );
  }

  Widget _buildRow(SongSummary song, bool isDark, bool showPlayHistory) {
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
      trailing: showPlayHistory && song.lastSungDate != null
          ? PlayHistoryListSubtitle(song: song)
          : null,
      onTap: () async {
        await onTap(song);
      },
      dense: true,
    );
  }
}
