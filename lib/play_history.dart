const int kDefaultPlayWeeks = 26;
const int kPlayWeeksPastYear = 52;

DateTime? parsePlayDate(dynamic raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  if (text.isEmpty) return null;
  final datePart = text.contains(' ') ? text.split(' ').first : text;

  final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(datePart);
  if (isoMatch != null) {
    return DateTime(
      int.parse(isoMatch.group(1)!),
      int.parse(isoMatch.group(2)!),
      int.parse(isoMatch.group(3)!),
    );
  }

  for (final separator in ['.', '/']) {
    final parts = datePart.split(separator);
    if (parts.length != 3) continue;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) continue;
    if (year < 100) continue;
    return DateTime(year, month, day);
  }
  return null;
}

List<String> parsePlayDateList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((value) => value?.toString().trim() ?? '')
      .where((value) => value.isNotEmpty)
      .toList();
}

DateTime? lastSungFrom({String? lastSung, List<String>? playDates}) {
  final fromField = parsePlayDate(lastSung);
  if (fromField != null) return fromField;
  if (playDates == null || playDates.isEmpty) return null;
  return parsePlayDate(playDates.last);
}

/// Monday-aligned weekly bins for the last [weeks] weeks, matching the backend
/// `weekly_play_counts` helper. Dates outside the window are ignored.
List<int> weeklyPlayCounts(
  Iterable<String>? playDates, {
  int weeks = kDefaultPlayWeeks,
  DateTime? asOf,
}) {
  final now = _dateOnly(asOf ?? DateTime.now());
  final thisMonday = now.subtract(Duration(days: now.weekday - DateTime.monday));
  final firstMonday = thisMonday.subtract(Duration(days: 7 * (weeks - 1)));
  final counts = List<int>.filled(weeks, 0);

  for (final raw in playDates ?? const <String>[]) {
    final played = parsePlayDate(raw);
    if (played == null) continue;
    final weekStart =
        played.subtract(Duration(days: played.weekday - DateTime.monday));
    final index = weekStart.difference(firstMonday).inDays ~/ 7;
    if (index >= 0 && index < weeks) {
      counts[index] += 1;
    }
  }
  return counts;
}

String formatLastSungAbsolute(DateTime lastSung) {
  return '${lastSung.day} ${_shortMonth(lastSung.month)} ${lastSung.year}';
}

String playCountLabel(int count) {
  if (count <= 0) return 'Nu apare în istoric';
  if (count == 1) return 'Cântată o dată';
  return 'Cântată de $count ori';
}

String sparklineSemanticsLabel(List<int> counts) {
  final total = counts.fold<int>(0, (sum, value) => sum + value);
  if (total == 0) {
    return 'Nicio cântare în ultimele ${counts.length} săptămâni';
  }
  if (total == 1) {
    return 'Cântată o dată în ultimele ${counts.length} săptămâni';
  }
  return 'Cântată de $total ori în ultimele ${counts.length} săptămâni';
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _shortMonth(int month) {
  switch (month) {
    case 1:
      return 'ian';
    case 2:
      return 'feb';
    case 3:
      return 'mar';
    case 4:
      return 'apr';
    case 5:
      return 'mai';
    case 6:
      return 'iun';
    case 7:
      return 'iul';
    case 8:
      return 'aug';
    case 9:
      return 'sep';
    case 10:
      return 'oct';
    case 11:
      return 'noi';
    case 12:
      return 'dec';
    default:
      return '';
  }
}
