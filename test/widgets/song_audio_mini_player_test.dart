import 'package:ccc_flutter/widgets/song_screen/song_audio_mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

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
    final player = MockAudioPlayer();
    final pausedState = PlayerState(false, ProcessingState.ready);
    when(() => player.playerState).thenReturn(pausedState);
    when(() => player.playerStateStream)
        .thenAnswer((_) => Stream.value(pausedState));
    when(() => player.durationStream)
        .thenAnswer((_) => Stream.value(const Duration(minutes: 3)));
    when(() => player.positionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));

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
    await tester.pump();

    expect(find.text('Apasă Redă pentru a porni muzica'), findsOneWidget);
    expect(find.text('Redă'), findsOneWidget);
    expect(find.text('Pauză'), findsNothing);
    verifyNever(() => player.play());
  });
}
