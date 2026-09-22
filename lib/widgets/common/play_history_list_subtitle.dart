import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/play_history.dart';
import 'package:ccc_flutter/widgets/common/play_frequency_sparkline.dart';
import 'package:flutter/material.dart';

class PlayHistoryListSubtitle extends StatelessWidget {
  final SongSummary song;

  const PlayHistoryListSubtitle({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final lastSung = song.lastSungDate;
    final recencyColor = lastSungRecencyColor(lastSung, isDark: Theme.of(context).brightness == Brightness.dark);
    if (lastSung == null || recencyColor == null) {
      return const SizedBox.shrink();
    }

    const dateWidth = 108.0;
    const fontSize = 14.0;

    return SizedBox(
      width: dateWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatLastSungAbsolute(lastSung),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: fontSize,
              color: recencyColor,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          PlayFrequencySparkline(
            playDates: song.playDates,
            color: recencyColor,
            width: dateWidth,
          ),
        ],
      ),
    );
  }
}

/// Hot when recently sung, blue when less recent, gray when old.
/// Returns null when the song has never been sung so the list can stay unmarked.
Color? lastSungRecencyColor(DateTime? lastSung, {required bool isDark, DateTime? now}) {
  if (lastSung == null) return null;

  final today = now ?? DateTime.now();
  final days = DateTime(today.year, today.month, today.day)
      .difference(DateTime(lastSung.year, lastSung.month, lastSung.day))
      .inDays;

  if (days <= 14) {
    return isDark ? const Color(0xFFFF8A65) : const Color(0xFFD84315);
  }
  if (days <= 60) {
    return isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00);
  }
  if (days <= 180) {
    return isDark ? COLOR_BLUE : COLOR_DARK_BLUE;
  }
  return isDark ? Colors.grey[300]! : Colors.grey[800]!;
}
