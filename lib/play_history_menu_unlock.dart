/// Counts title taps that unlock the play-history setting.
/// Taps count only when each one follows the previous within one second.
class PlayHistoryTitleTaps {
  static const requiredTaps = 10;
  static const countdownFromTap = 5;
  static const maxGap = Duration(seconds: 1);

  var count = 0;
  DateTime? _lastTap;

  /// Remaining taps after this one.
  /// Null means the tap stays quiet. Zero means the sequence just unlocked.
  int? register(DateTime now) {
    if (_lastTap != null && now.difference(_lastTap!) > maxGap) {
      count = 0;
    }
    _lastTap = now;
    count++;
    final remaining = requiredTaps - count;
    if (remaining <= 0) {
      count = 0;
      _lastTap = null;
      return 0;
    }
    if (count >= countdownFromTap) return remaining;
    return null;
  }
}
