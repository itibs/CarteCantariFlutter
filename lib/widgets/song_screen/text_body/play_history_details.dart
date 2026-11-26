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
      fontSize: textSize * 0.58,
      fontWeight: FontWeight.w400,
      color: onSurface.withValues(alpha: 0.72),
    );
    final dateStyle = style.copyWith(
      color: recencyColor?.withValues(alpha: 0.9) ?? style.color,
    );
    final captionStyle = style.copyWith(
      fontSize: textSize * 0.48,
      color: onSurface.withValues(alpha: 0.5),
    );

    if (lastSung == null) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          'Cântată ultima dată: Necântată',
          style: TextStyle(
            fontSize: textSize * 0.58,
            fontWeight: FontWeight.w400,
            color: onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: onSurface.withValues(alpha: isDark ? 0.16 : 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Cântată ultima dată: ', style: style),
              TextSpan(
                text: formatLastSungAbsolute(lastSung),
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
