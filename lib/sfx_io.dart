import 'package:audioplayers/audioplayers.dart';
import 'sfx_platform.dart' show kSfxAssets;

/// Native (Android/iOS/desktop) sound engine using audioplayers. AssetSource
/// works fine off the web, and a small per-sound pool avoids the
/// "plays once then silent" issue when the same player is replayed quickly.
class Sfx {
  static const int _poolSize = 3;
  final Map<String, List<AudioPlayer>> _pool = {};
  final Map<String, int> _next = {};
  bool muted = false;

  Sfx() {
    _init();
  }

  // audioplayers' AssetSource implicitly prefixes 'assets/'.
  String _rel(String name) => kSfxAssets[name]!.replaceFirst('assets/', '');

  Future<void> _init() async {
    for (final name in kSfxAssets.keys) {
      final list = <AudioPlayer>[];
      for (var i = 0; i < _poolSize; i++) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        try {
          await p.setSource(AssetSource(_rel(name)));
        } catch (_) {/* best-effort */}
        list.add(p);
      }
      _pool[name] = list;
      _next[name] = 0;
    }
  }

  void play(String name, double volume) {
    if (muted) return;
    final list = _pool[name];
    if (list == null || list.isEmpty) return;
    final i = _next[name]!;
    _next[name] = (i + 1) % list.length;
    list[i].play(AssetSource(_rel(name)), volume: volume).catchError((_) {});
  }

  void dispose() {
    for (final list in _pool.values) {
      for (final p in list) {
        p.dispose();
      }
    }
    _pool.clear();
  }
}

Sfx createSfx() => Sfx();
