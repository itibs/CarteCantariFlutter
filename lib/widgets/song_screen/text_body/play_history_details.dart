import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/play_history.dart';
import 'package:ccc_flutter/widgets/common/play_frequency_sparkline.dart';
import 'package:ccc_flutter/widgets/common/play_history_list_subtitle.dart';
import 'package:flutter/material.dart';

class PlayHistoryDetails extends StatelessWidget {
  final SongSummary song;
  final double textSize;

  const PlayHistoryDetails({
    super.key,
    required this.song,
    required this.textSize,
  });

  @override
  Widget build(BuildContext context) {
    final lastSung = song.lastSungDate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recencyColor = lastSungRecencyColor(lastSung, isDark: isDark);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final style = TextStyle(
      fontSize: textSize * 0.75,
      color: onSurface,
    );
    final headerStyle = style.copyWith(fontWeight: FontWeight.bold);
    final dateStyle = style.copyWith(
      fontWeight: FontWeight.w700,
      color: recencyColor ?? onSurface,
    );
    final captionStyle = style.copyWith(
      fontSize: textSize * 0.55,
      color: onSurface.withValues(alpha: 0.72),
    );

    final lastSungText =
        lastSung == null ? 'Necântată' : formatLastSungAbsolute(lastSung);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Cântată ultima dată: ', style: headerStyle),
              TextSpan(
                text: lastSungText,
                style: dateStyle,
              ),
            ]),
          ),
          const SizedBox(height: 14),
          PlayFrequencySparkline(
            playDates: song.playDates,
            color: recencyColor,
            width: null,
            height: 48,
            weeks: kPlayWeeksPastYear,
            compact: false,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('acum un an', style: captionStyle),
              Text('azi', style: captionStyle),
            ],
          ),
        ],
      ),
    );
  }
}
