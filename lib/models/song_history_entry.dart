import 'package:sprintf/sprintf.dart';

class SongsHistoryEntry {
  String songId;
  DateTime dateAdded;

  SongsHistoryEntry({required this.songId, DateTime? dateAdded})
      : dateAdded = dateAdded ?? DateTime.now();

  String toFileEncoding() {
    var strDateAdded = dateAdded.millisecondsSinceEpoch.toString();
    return strDateAdded + "|" + songId;
  }

  String getHumanReadableDateAdded() {
    var dt = dateAdded;
    if (isToday(dt)) {
      return sprintf("Astăzi, %02d:%02d", [dt.hour, dt.minute]);
    } else if (isYesterday(dt)) {
      return sprintf("Ieri, %02d:%02d", [dt.hour, dt.minute]);
    }

    var formattedDate = sprintf("%s, %2d %s %04d, %02d:%02d", [getDayOfWeek(dt.weekday), dt.day, getMonth(dt.month), dt.year, dt.hour, dt.minute]);
    return formattedDate;
  }

  factory SongsHistoryEntry.fromFileEncoding(String encodedEntry) {
    var tokens = encodedEntry.split("|");

    var songId = tokens[1];
    var dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(tokens[0]));
    return SongsHistoryEntry(songId: songId, dateAdded: dateTime);
  }
}

String getDayOfWeek(int dayOfWeek) {
  switch (dayOfWeek) {
    case 1: return "Luni";
    case 2: return "Marți";
    case 3: return "Miercuri";
    case 4: return "Joi";
    case 5: return "Vineri";
    case 6: return "Sâmbătă";
    case 7: return "Duminică";
  }

  return "";
}

String getMonth(int month) {
  switch (month) {
    case 1: return "ian";
    case 2: return "feb";
    case 3: return "mar";
    case 4: return "apr";
    case 5: return "mai";
    case 6: return "iun";
    case 7: return "iul";
    case 8: return "aug";
    case 9: return "sep";
    case 10: return "oct";
    case 11: return "noi";
    case 12: return "dec";
  }

  return "";
}

bool isToday(DateTime dt) {
  var now = DateTime.now();
  return dt.year == now.year &&
      dt.month == now.month &&
      dt.day == now.day;
}

bool isYesterday(DateTime dt) {
  // check if dt is yesterday by checking the day after yesterday is today
  var nextDayDt = dt.add(Duration(days: 1));
  return isToday(nextDayDt);
}