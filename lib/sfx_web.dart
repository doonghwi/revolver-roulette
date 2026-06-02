import 'dart:js_interop';
import 'package:flutter/services.dart' show rootBundle;
import 'package:web/web.dart' as web;
import 'sfx_platform.dart' show kSfxAssets;

/// Web sound engine: ONE AudioContext shared by all effects. Each asset is
/// decoded once into an AudioBuffer; every play spins up a fresh
/// AudioBufferSourceNode (cheap, unlimited overlap/repeat). The context is
/// resumed on the first tap and then stays running — so unlike audioplayers'
/// per-player suspended contexts, sound keeps working after the first one.
class Sfx {
  final web.AudioContext _ctx = web.AudioContext();
  final Map<String, web.AudioBuffer> _bufs = {};
  bool muted = false;

  Sfx() {
    _loadAll();
  }

  Future<void> _loadAll() async {
    for (final e in kSfxAssets.entries) {
      try {
        final bytes = await rootBundle.load(e.value); // ByteData
        final jsBuf = bytes.buffer.toJS; // ByteBuffer -> JSArrayBuffer
        final decoded = await _ctx.decodeAudioData(jsBuf).toDart;
        _bufs[e.key] = decoded;
      } catch (_) {/* best-effort */}
    }
  }

  void play(String name, double volume) {
    if (muted) return;
    // First tap: unlock the context (stays running afterwards).
    if (_ctx.state == 'suspended') _ctx.resume();
    final b = _bufs[name];
    if (b == null) return;
    final src = _ctx.createBufferSource();
    src.buffer = b;
    final g = _ctx.createGain();
    g.gain.value = volume;
    src.connect(g);
    g.connect(_ctx.destination);
    src.start();
  }

  void dispose() {
    _ctx.close();
  }
}

Sfx createSfx() => Sfx();
