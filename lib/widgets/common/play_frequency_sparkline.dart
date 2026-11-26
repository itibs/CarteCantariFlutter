import 'dart:math' as math;

import 'package:ccc_flutter/play_history.dart';
import 'package:flutter/material.dart';

/// Quiet weekly activity bars. Empty weeks stay almost invisible so sparse
/// history reads as a few ticks rather than a block of tall columns.
class PlayFrequencySparkline extends StatelessWidget {
  final List<String>? playDates;
  final int weeks;
  final double? width;
  final double height;
  final DateTime? asOf;
  final Color? color;
  final bool compact;

  const PlayFrequencySparkline({
    super.key,
    required this.playDates,
    this.weeks = kDefaultPlayWeeks,
    this.width = 52,
    this.height = 8,
    this.asOf,
    this.color,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final counts = weeklyPlayCounts(playDates, weeks: weeks, asOf: asOf);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = (color ?? Theme.of(context).colorScheme.primary)
        .withValues(alpha: compact ? (isDark ? 0.7 : 0.55) : (isDark ? 0.9 : 0.82));
    final empty = Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.22 : 0.14);

    final painter = _PlayFrequencySparklinePainter(
      counts: counts,
      fill: fill,
      empty: empty,
      compact: compact,
    );

    Widget paint(double sparkWidth) => Semantics(
          label: sparklineSemanticsLabel(counts),
          child: CustomPaint(
            size: Size(sparkWidth, height),
            painter: painter,
          ),
        );

    if (width != null) {
      return paint(width!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final sparkWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
        if (sparkWidth <= 0) return const SizedBox.shrink();
        return paint(sparkWidth);
      },
    );
  }
}

class _PlayFrequencySparklinePainter extends CustomPainter {
  final List<int> counts;
  final Color fill;
  final Color empty;
  final bool compact;

  _PlayFrequencySparklinePainter({
    required this.counts,
    required this.fill,
    required this.empty,
    required this.compact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty || size.width <= 0 || size.height <= 0) return;

    final maxCount = counts.fold<int>(0, math.max);
    final gap = compact ? 0.8 : math.max(1.5, size.width / (counts.length * 6));
    final barWidth =
        math.max(1.0, (size.width - gap * (counts.length - 1)) / counts.length);
    final baseline = compact ? 1.0 : 0.0;
    final fillFactor = compact ? 0.55 : 1.0;

    if (!compact) {
      final axis = Paint()
        ..color = empty
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(0, size.height - 0.5),
        Offset(size.width, size.height - 0.5),
        axis,
      );
    }

    for (var i = 0; i < counts.length; i++) {
      final count = counts[i];
      final double barHeight;
      if (count <= 0 || maxCount <= 0) {
        if (!compact) continue;
        barHeight = baseline;
      } else {
        // Mild sqrt so a lone play is visible, without filling the row height.
        final t = math.sqrt(count / maxCount);
        barHeight = compact
            ? baseline + (size.height - baseline) * fillFactor * (0.35 + 0.65 * t)
            : size.height * (0.28 + 0.72 * t);
      }

      final x = i * (barWidth + gap);
      final rect = Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight);
      final radius = compact ? 0.5 : math.min(2.0, barWidth / 2);
      canvas.drawRRect(
        compact
            ? RRect.fromRectAndRadius(rect, Radius.circular(radius))
            : RRect.fromRectAndCorners(
                rect,
                topLeft: Radius.circular(radius),
                topRight: Radius.circular(radius),
              ),
        Paint()..color = count <= 0 ? empty : fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlayFrequencySparklinePainter oldDelegate) {
    return oldDelegate.fill != fill ||
        oldDelegate.empty != empty ||
        oldDelegate.compact != compact ||
        !_listEquals(oldDelegate.counts, counts);
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
