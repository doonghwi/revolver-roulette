import 'package:audioplayers/audioplayers.dart';

/// Lightweight sound effect manager. Pre-creates players so playback is instant.
/// All assets are self-synthesized copyright-free WAVs (see tool/make_sounds.py).
class AudioManager {
  AudioManager() {
    for (final p in [_spin, _shot, _click]) {
      p.setReleaseMode(ReleaseMode.stop);
    }
  }

  final AudioPlayer _spin = AudioPlayer(playerId: 'spin');
  final AudioPlayer _shot = AudioPlayer(playerId: 'shot');
  final AudioPlayer _click = AudioPlayer(playerId: 'click');

  bool muted = false;

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
  Future<void> spin() => _play(_spin, 'sounds/cylinder_spin.wav', volume: 0.9);

  /// Gunshot — played when the live round fires.
  Future<void> gunshot() => _play(_shot, 'sounds/gunshot.wav', volume: 1.0);

  /// Single hammer click — optional feedback on press.
  Future<void> click() => _play(_click, 'sounds/dry_click.wav', volume: 0.7);

  void dispose() {
    _spin.dispose();
    _shot.dispose();
    _click.dispose();
  }
}
