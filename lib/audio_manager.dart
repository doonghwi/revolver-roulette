import 'sfx_platform.dart';

/// Thin facade over the platform sound engine (see sfx_platform.dart, which
/// picks sfx_web.dart on web and sfx_io.dart on mobile/desktop).
///
/// Web uses a single shared AudioContext + AudioBufferSource (reliable autoplay
/// unlock and repeat playback); native uses audioplayers. All effects are
/// triggered synchronously from the tap handler.
class AudioManager {
  final Sfx _sfx = createSfx();

  bool get muted => _sfx.muted;
  set muted(bool v) => _sfx.muted = v;

  void spin() => _sfx.play('spin', 1.0);
  void gunshot() => _sfx.play('gunshot', 1.0);
  void cock() => _sfx.play('cock', 0.9);
  void click() => _sfx.play('click', 0.7);

  void dispose() => _sfx.dispose();
}
