import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';

/// Sound effect manager.
///
/// Two web-specific pitfalls handled here:
///  1) On web, `AssetSource` makes audioplayers route through its `AudioCache`,
///     which calls `dart:io` and throws "Unsupported operation: _Namespace".
///     We therefore use `UrlSource` on web (a direct `<audio src>` URL, which
///     bypasses AudioCache) and keep `AssetSource` on mobile.
///  2) Re-`play()`ing one AudioPlayer rapidly can "play once then go silent".
///     We use a small pool of players per sound and round-robin them.
///
/// Playback is also kicked off synchronously inside the tap handler (no awaited
/// stop() first) so the browser autoplay policy lets the AudioContext resume.
class AudioManager {
  static const int _poolSize = 3;

  // file names live in assets/sounds/ (mobile) and web/assets/assets/sounds/.
  static const _spinFile = 'cylinder_spin.wav';
  static const _shotFile = 'gunshot.mp3'; // mixkit real recording (CC0/Mixkit License)
  static const _cockFile = 'hammer_cock.wav';
  static const _clickFile = 'dry_click.wav';
  static const _files = [_spinFile, _shotFile, _cockFile, _clickFile];

  final Map<String, List<AudioPlayer>> _pool = {};
  final Map<String, int> _next = {};
  bool muted = false;

  AudioManager() {
    _init();
  }

  Future<void> _init() async {
    for (final f in _files) {
      final list = <AudioPlayer>[];
      for (var i = 0; i < _poolSize; i++) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        try {
          await p.setSource(_source(f)); // pre-load
        } catch (_) {/* best-effort */}
        list.add(p);
      }
      _pool[f] = list;
      _next[f] = 0;
    }
  }

  Source _source(String file) => kIsWeb
      ? UrlSource('assets/assets/sounds/$file')
      : AssetSource('sounds/$file');

  void _play(String file, double volume) {
    if (muted) return;
    final list = _pool[file];
    if (list == null || list.isEmpty) return;
    final i = _next[file]!;
    _next[file] = (i + 1) % list.length;
    // Fire inside the gesture frame; round-robin avoids the "plays once" issue.
    list[i].play(_source(file), volume: volume).catchError((_) {});
  }

  void spin() => _play(_spinFile, 1.0);
  void gunshot() => _play(_shotFile, 1.0);
  void cock() => _play(_cockFile, 0.9);
  void click() => _play(_clickFile, 0.7);

  void dispose() {
    for (final list in _pool.values) {
      for (final p in list) {
        p.dispose();
      }
    }
    _pool.clear();
  }
}
