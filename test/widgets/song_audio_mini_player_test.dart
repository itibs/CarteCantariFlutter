import 'package:ccc_flutter/widgets/song_screen/song_audio_mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  group('formatAudioPosition', () {
    test('formats minutes and zero-padded seconds', () {
      expect(formatAudioPosition(Duration.zero), '0:00');
      expect(formatAudioPosition(const Duration(seconds: 5)), '0:05');
      expect(formatAudioPosition(const Duration(minutes: 3, seconds: 45)), '3:45');
      expect(formatAudioPosition(const Duration(minutes: 12, seconds: 9)), '12:09');
    });
  });

  testWidgets(
      'paused bar shows hint and labeled play without starting audio',
      (tester) async {
    final player = AudioPlayer();
    addTearDown(player.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SongAudioMiniPlayer(
            player: player,
            showPlayHint: true,
            onPlayed: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('Apasă Redă pentru a porni muzica'), findsOneWidget);
    expect(find.text('Redă'), findsOneWidget);
    expect(find.text('Pauză'), findsNothing);
    expect(player.playing, isFalse);
  });
}
