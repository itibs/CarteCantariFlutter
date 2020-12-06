import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
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
  Soundpool _soundpool;
  Map<String, Future<int>> _soundIds;
  Map<String, int> _streamIds;

  PitchSoundService()
      : _soundpool = Soundpool(maxStreams: 1, streamType: StreamType.music),
        _soundIds = new Map(),
        _streamIds = new Map() {
    for (var pitch in CHORDS) {
      _soundIds[pitch] = _loadChord(pitch);
    }
  }

  Future<void> playChord(String pitch) async {
    if (_soundIds.containsKey(pitch)) {
      developer.log("Playing chord $pitch");
      if (_streamIds.containsKey(pitch)) {
        _streamIds.remove(pitch);
      }
      final soundId = await _soundIds[pitch];
      _streamIds[pitch] = await _soundpool.play(soundId);
    }
  }

  Future<void> stopChord(String pitch) async {
    const NUM_TRIES = 50;
    developer.log("Trying to stop chord $pitch");
    for (var i = 0; i <= NUM_TRIES; i++) {
      developer.log("Try #$i");
      if (_streamIds.containsKey(pitch)) {
        developer.log("Stopping chord $pitch");
        await _soundpool.stop(_streamIds[pitch]);
        return;
      }
      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  Future<int> _loadChord(String pitch) async {
    final asset = await rootBundle.load("$CHORDS_SOUNDS_DIRECTORY/$pitch.mp3");
    return await _soundpool.load(asset);
  }
}
