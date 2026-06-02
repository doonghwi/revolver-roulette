/// Fallback sound engine for platforms without web or io libraries.
/// Never actually used in this app's targets (web + Android), but required so
/// the conditional export in sfx_platform.dart always resolves.
class Sfx {
  bool muted = false;
  void play(String name, double volume) {}
  void dispose() {}
}

Sfx createSfx() => Sfx();
