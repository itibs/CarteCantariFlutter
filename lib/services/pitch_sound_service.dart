import 'package:just_audio/just_audio.dart';
import 'dart:developer' as developer;

const CHORDS_SOUNDS_DIRECTORY = "assets/sounds/chords";
const CHORDS = [
  "C",
  "Db",
  "D",
  "Eb",
  "E",
  "F",
  "F#",
  "G",
  "Ab",
  "A",
  "Bb",
  "B",
  "Cm",
  "C#m",
  "Dm",
  "D#m",
  "Em",
  "Fm",
  "F#m",
  "G#m",
  "Gm",
  "Am",
  "Bbm",
  "Bm",
];

class PitchSoundService {
  final AudioPlayer _audioPlayer;
  String? _currentlyPlayingPitch;

  PitchSoundService() : _audioPlayer = AudioPlayer() {
    // Preload all chord assets (optional, for faster playback)
    // This is not strictly necessary but can improve responsiveness
  }

  Future<void> playChord(String pitch) async {
    if (!CHORDS.contains(pitch)) {
      developer.log("Unknown pitch: $pitch");
      return;
    }

    try {
      developer.log("Playing chord $pitch");
      
      // Stop any currently playing chord
      if (_currentlyPlayingPitch != null) {
        await _audioPlayer.stop();
      }

      // Load and play the new chord
      final assetPath = "$CHORDS_SOUNDS_DIRECTORY/$pitch.mp3";
      await _audioPlayer.setAsset(assetPath);
      _currentlyPlayingPitch = pitch;
      await _audioPlayer.play();
    } catch (e) {
      developer.log("Error playing chord $pitch: $e");
    }
  }

  Future<void> stopChord(String pitch) async {
    if (_currentlyPlayingPitch == pitch) {
      developer.log("Stopping chord $pitch");
      try {
        await _audioPlayer.stop();
        _currentlyPlayingPitch = null;
      } catch (e) {
        developer.log("Error stopping chord $pitch: $e");
      }
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
