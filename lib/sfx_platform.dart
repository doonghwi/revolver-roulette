// Picks the platform sound implementation at compile time:
//  - web  -> sfx_web.dart   (single Web-Audio AudioContext + BufferSource)
//  - io   -> sfx_io.dart    (audioplayers, works natively on Android/iOS)
export 'sfx_stub.dart'
    if (dart.library.js_interop) 'sfx_web.dart'
    if (dart.library.io) 'sfx_io.dart';

/// Logical sound name -> bundled asset path (shared by all implementations).
const Map<String, String> kSfxAssets = {
  'spin': 'assets/sounds/cylinder_spin.wav',
  'gunshot': 'assets/sounds/gunshot.wav',
  'cock': 'assets/sounds/hammer_cock.wav',
  'click': 'assets/sounds/dry_click.wav',
};
