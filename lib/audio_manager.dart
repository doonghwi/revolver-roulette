import 'package:audioplayers/audioplayers.dart';

/// Sound effect manager. Pre-creates low-latency players so playback is instant.
/// All assets are self-synthesized copyright-free WAVs (see tool/make_sounds.py).
class AudioManager {
  AudioManager() {
    for (final p in [_spin, _shot, _cock, _click]) {
      p.setReleaseMode(ReleaseMode.stop);
      p.setPlayerMode(PlayerMode.lowLatency);
    }
    // Warm up so the very first effect is not delayed.
    _prime();
  }

  final AudioPlayer _spin = AudioPlayer(playerId: 'spin');
  final AudioPlayer _shot = AudioPlayer(playerId: 'shot');
  final AudioPlayer _cock = AudioPlayer(playerId: 'cock');
  final AudioPlayer _click = AudioPlayer(playerId: 'click');

  bool muted = false;

  Future<void> _prime() async {
    try {
      await _spin.setSource(AssetSource('sounds/cylinder_spin.wav'));
      await _shot.setSource(AssetSource('sounds/gunshot.wav'));
      await _cock.setSource(AssetSource('sounds/hammer_cock.wav'));
      await _click.setSource(AssetSource('sounds/dry_click.wav'));
    } catch (_) {/* best-effort */}
  }

  Future<void> _play(AudioPlayer p, String asset, {double volume = 1.0}) async {
    if (muted) return;
    try {
      await p.stop();
      await p.play(AssetSource(asset), volume: volume);
    } catch (_) {
      // Audio is best-effort; never let a playback error break the game.
    }
  }

  /// Cylinder spinning / ratcheting — played on a safe (survived) pull.
  Future<void> spin() => _play(_spin, 'sounds/cylinder_spin.wav', volume: 1.0);

  /// Gunshot — played when the live round fires.
  Future<void> gunshot() => _play(_shot, 'sounds/gunshot.wav', volume: 1.0);

  /// Single-action hammer cock — played the instant the trigger is pressed.
  Future<void> cock() => _play(_cock, 'sounds/hammer_cock.wav', volume: 0.9);

  /// Light mechanism tick (reserved for subtle feedback).
  Future<void> click() => _play(_click, 'sounds/dry_click.wav', volume: 0.7);

  void dispose() {
    _spin.dispose();
    _shot.dispose();
    _cock.dispose();
    _click.dispose();
  }
}
