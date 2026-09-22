import 'package:ccc_flutter/blocs/settings/show_play_history/show_play_history.dart';
import 'package:ccc_flutter/models/song_summary.dart';
import 'package:ccc_flutter/play_history.dart';
import 'package:ccc_flutter/widgets/common/play_frequency_sparkline.dart';
import 'package:ccc_flutter/widgets/common/play_history_list_subtitle.dart';
import 'package:ccc_flutter/widgets/common/song_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SongSummary song({
  required String title,
  List<String>? playDates,
  String? lastSung,
}) {
  return SongSummary(
    bookId: 'CC',
    title: title,
    number: 1,
    searchableTitle: 'cc 1',
    playDates: playDates,
    lastSung: lastSung,
  );
}

Widget wrap(Widget child, {required bool showPlayHistory}) {
  final cubit = ShowPlayHistoryCubit()..setValue(showPlayHistory);
  return MaterialApp(
    home: BlocProvider.value(
      value: cubit,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('hides play history when the setting is off', (tester) async {
    await tester.pumpWidget(wrap(
      SongList(
        songs: [
          song(title: 'Cântare', playDates: ['2026-09-05'], lastSung: '2026-09-05'),
        ],
        onTap: (_) async {},
      ),
      showPlayHistory: false,
    ));

    expect(find.text('Cântare'), findsOneWidget);
    expect(find.byType(PlayHistoryListSubtitle), findsNothing);
    expect(find.text('Necântată'), findsNothing);
  });

  testWidgets('shows last sung and never-sung from the list when enabled',
      (tester) async {
    await tester.pumpWidget(wrap(
      SongList(
        songs: [
          song(title: 'Recentă', playDates: ['2026-09-05'], lastSung: '2026-09-05'),
          song(title: 'Nouă'),
        ],
        onTap: (_) async {},
      ),
      showPlayHistory: true,
    ));

    expect(find.text('Recentă'), findsOneWidget);
    expect(
      find.text(formatLastSungAbsolute(DateTime(2026, 9, 5))),
      findsOneWidget,
    );
    expect(find.text('Necântată'), findsNothing);
    expect(find.byType(PlayHistoryListSubtitle), findsOneWidget);
    expect(find.byType(PlayFrequencySparkline), findsOneWidget);
  });
}
