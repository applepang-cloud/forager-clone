import 'package:flame_audio/flame_audio.dart';

/// Thin wrapper around flame_audio for SFX + looping BGM.
class Audio {
  static bool testMode = false; // disables all audioplayers calls in tests
  static bool sfxOn = true;
  static bool musicOn = true;
  static bool _ready = false;
  static bool _bgmStarted = false;

  static const _sfx = [
    'hit.mp3',
    'harvest.mp3',
    'pickup.mp3',
    'build.mp3',
    'nope.mp3',
    'hurt.mp3',
    'die.mp3',
    'levelup.mp3',
    'shoot.mp3',
    'coin.mp3',
  ];

  static Future<void> preload() async {
    if (testMode) return;
    try {
      await FlameAudio.audioCache.loadAll(_sfx);
      _ready = true;
    } catch (_) {
      // ignore missing audio in tests / headless
    }
  }

  static void play(String name, {double volume = 0.6}) {
    if (testMode || !sfxOn || !_ready) return;
    try {
      FlameAudio.play(name, volume: volume);
    } catch (_) {}
  }

  /// Must be triggered from a user gesture on the web.
  static void startBgm() {
    if (testMode || !musicOn || _bgmStarted) return;
    _bgmStarted = true;
    try {
      FlameAudio.bgm.play('bgm.mp3', volume: 0.3);
    } catch (_) {}
  }

  static void toggleMusic() {
    musicOn = !musicOn;
    try {
      if (musicOn) {
        _bgmStarted = false;
        startBgm();
      } else {
        FlameAudio.bgm.stop();
      }
    } catch (_) {}
  }
}
