import 'package:ccc_flutter/blocs/settings/show_key_signatures/show_key_signatures.dart';
import 'package:ccc_flutter/blocs/settings/show_play_history/show_play_history.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/widgets/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openMenu(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ShowKeySignaturesCubit()),
          BlocProvider(create: (_) => ShowPlayHistoryCubit()),
        ],
        child: Scaffold(
          drawer: SideMenu(
            syncBooks: () {},
            goToSongsHistory: () {},
            goToCategories: () {},
            goToCustomLists: () {},
            goToMusicSheetSettings: () {},
          ),
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapTitle(WidgetTester tester, int times) async {
    for (var i = 0; i < times; i++) {
      await tester.tap(find.text('Carte Cântări Carol'));
      await tester.pump();
    }
  }

  testWidgets('hides play history until the title is tapped ten times', (tester) async {
    await openMenu(tester);

    expect(find.text('Afișează istoricul cântărilor'), findsNothing);

    await tapTitle(tester, 4);
    expect(find.text('Afișează istoricul cântărilor'), findsNothing);
    expect(find.text('Mai sunt 5 atingeri.'), findsNothing);

    await tapTitle(tester, 1);
    expect(find.text('Mai sunt 5 atingeri.'), findsOneWidget);
    expect(find.text('Afișează istoricul cântărilor'), findsNothing);

    await tapTitle(tester, 4);
    expect(find.text('Mai este o atingere.'), findsOneWidget);

    await tapTitle(tester, 1);
    await tester.pump();
    expect(find.text('Afișează istoricul cântărilor'), findsOneWidget);
    expect(find.text('Istoricul cântărilor este acum disponibil.'), findsOneWidget);

    await tapTitle(tester, 1);
    expect(find.text('Istoricul cântărilor este deja disponibil.'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PREFS_PLAY_HISTORY_MENU_UNLOCKED), isTrue);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('stays hidden when play history was already turned on', (tester) async {
    SharedPreferences.setMockInitialValues({
      PREFS_SETTINGS_SHOW_PLAY_HISTORY: true,
    });

    await openMenu(tester);

    expect(find.text('Afișează istoricul cântărilor'), findsNothing);
  });

  testWidgets('shows play history when it was unlocked before', (tester) async {
    SharedPreferences.setMockInitialValues({
      PREFS_PLAY_HISTORY_MENU_UNLOCKED: true,
    });

    await openMenu(tester);

    expect(find.text('Afișează istoricul cântărilor'), findsOneWidget);
  });
}
