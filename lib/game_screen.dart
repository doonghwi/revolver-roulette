import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'audio_manager.dart';
import 'revolver_painter.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// Game phases.
enum _Phase { ready, spinning, dead }

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int chambers = 6;

  final AudioManager _audio = AudioManager();
  final math.Random _rng = math.Random();

  int _bulletAt = 0; // chamber 0..5 holding the live round
  int _pulls = 0; // survived pulls (== shots-fired count)
  _Phase _phase = _Phase.ready;

  double _cylAngle = 0;
  double _spinFrom = 0, _spinTo = 0;
  bool _countAfterSpin = false; // true for a survive spin, false for a reload spin

  late final AnimationController _spinCtrl;
  late final AnimationController _flashCtrl;
  late final AnimationController _cockCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950))
      ..addListener(_onSpinTick)
      ..addStatusListener(_onSpinStatus);
    _flashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addListener(() => setState(() {}));
    _cockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110))
      ..addListener(() => setState(() {}));
    _arm();
  }

  /// Load a fresh game: random live chamber, zero the counter.
  void _arm() {
    _bulletAt = _rng.nextInt(chambers);
    _pulls = 0;
    _phase = _Phase.ready;
  }

  void _onSpinTick() {
    final c = Curves.easeOutCubic.transform(_spinCtrl.value);
    setState(() => _cylAngle = _spinFrom + (_spinTo - _spinFrom) * c);
  }

  void _onSpinStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) {
      setState(() {
        _cylAngle = _spinTo % (2 * math.pi);
        if (_countAfterSpin) _pulls++; // reload spins must NOT count as a shot
        _phase = _Phase.ready;
      });
    }
  }

  /// The trigger pull — the core action. A tap anywhere fires it.
  void _pull() {
    if (_phase != _Phase.ready) {
      if (_phase == _Phase.dead) _reset();
      return;
    }
    _audio.cock(); // hammer cocks the instant the trigger is pressed
    _cockCtrl.forward(from: 0).then((_) => _cockCtrl.reverse());

    final isLive = _pulls == _bulletAt;
    if (isLive) {
      _fire();
    } else {
      _survive();
    }
  }

  void _survive() {
    setState(() => _phase = _Phase.spinning);
    _countAfterSpin = true;
    _audio.spin();
    _spinFrom = _cylAngle;
    _spinTo = _cylAngle + 2 * math.pi * 1.5 + (2 * math.pi / chambers);
    _spinCtrl.forward(from: 0);
  }

  void _fire() {
    setState(() => _phase = _Phase.dead);
    _audio.gunshot();
    _flashCtrl.forward(from: 0);
  }

  void _reset() {
    _flashCtrl.reset();
    setState(_arm);
    _countAfterSpin = false; // reload spin: do not increment the counter
    _spinFrom = _cylAngle;
    _spinTo = _cylAngle + 2 * math.pi;
    _phase = _Phase.spinning;
    _spinCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _flashCtrl.dispose();
    _cockCtrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flash = _flashCtrl.value;
    final shakeT = (1 - (flash / 0.35)).clamp(0.0, 1.0);
    final shake = math.sin(flash * math.pi * 16) * 20 * shakeT;
    final double redAlpha = flash <= 0
        ? 0
        : flash < 0.08
            ? (flash / 0.08) * 0.92
            : (0.92 * math.exp(-(flash - 0.08) * 3.2)).clamp(0.0, 0.92);
    // muzzle flash: intense right at the shot, gone within ~0.18 of the anim
    final double muzzle =
        _phase == _Phase.dead ? (1 - flash / 0.18).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF120d09),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _pull(),
        child: Stack(
          children: [
            // background
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.1, -0.15),
                    radius: 1.3,
                    colors: [Color(0xFF2c1e12), Color(0xFF120d09)],
                  ),
                ),
              ),
            ),
            // the revolver fills the whole screen
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(shake, shake * 0.25),
                child: CustomPaint(
                  painter: RevolverPainter(
                    cylinderAngle: _cylAngle,
                    bulletChamber: _bulletAt,
                    reveal: _phase == _Phase.dead,
                    hammerCock: _cockCtrl.value,
                    muzzleFlash: muzzle,
                  ),
                ),
              ),
            ),
            // HUD overlays (counter, mute, status)
            SafeArea(
              child: Stack(
                children: [
                  Align(alignment: Alignment.topCenter, child: _topHud()),
                  Align(alignment: Alignment.bottomCenter, child: _statusBar()),
                ],
              ),
            ),
            // red flash on a live round
            if (redAlpha > 0.01)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.1,
                        colors: [
                          const Color(0xFFff2a1a).withValues(alpha: redAlpha),
                          const Color(0xFF8b0000).withValues(alpha: redAlpha),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_phase == _Phase.dead) _deadOverlay(flash),
          ],
        ),
      ),
    );
  }

  // ---- top HUD: title (left) + horizontal shots counter (right) + mute ----
  Widget _topHud() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REVOLVER\nROULETTE',
            style: TextStyle(
              fontSize: 14,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Color(0xFFe8d9c5),
              shadows: [Shadow(color: Colors.black, blurRadius: 6)],
            ),
          ),
          const Spacer(),
          _shotsCounter(),
          IconButton(
            onPressed: () => setState(() => _audio.muted = !_audio.muted),
            icon: Icon(_audio.muted ? Icons.volume_off : Icons.volume_up,
                color: const Color(0xFFb9a88f)),
          ),
        ],
      ),
    );
  }

  Widget _shotsCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5a4633), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('SHOTS FIRED · 쏜 횟수',
              style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 1.5,
                  color: Color(0xFFb59c7c),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < chambers; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: _CounterPip(filled: i < _pulls),
                ),
              const SizedBox(width: 8),
              Text('$_pulls',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFe8d9c5))),
            ],
          ),
        ],
      ),
    );
  }

  // ---- bottom status / instruction ----
  Widget _statusBar() {
    String msg;
    Color col;
    switch (_phase) {
      case _Phase.ready:
        msg = _pulls == 0
            ? '아무 곳이나 탭 · TAP ANYWHERE TO PULL THE TRIGGER'
            : '한 발 더? 탭 · ONE MORE? TAP';
        col = const Color(0xFFc7b69c);
        break;
      case _Phase.spinning:
        msg = '철컥… 실린더 회전 · CLICK… CYLINDER SPINS';
        col = const Color(0xFF9fc79f);
        break;
      case _Phase.dead:
        msg = '💥 탕! 명중! 탭하면 재장전 · BANG! TAP TO RELOAD';
        col = const Color(0xFFff9a8a);
        break;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: col)),
      ),
    );
  }

  Widget _deadOverlay(double flash) {
    final appear = (flash / 0.06).clamp(0.0, 1.0);
    final fade = (1 - (flash - 0.45) / 0.35).clamp(0.0, 1.0);
    final t = appear * fade;
    if (t <= 0.01) return const SizedBox.shrink();
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.7 + appear * 0.45,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('💥', style: TextStyle(fontSize: 60)),
                Text('BANG!',
                    style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 14),
                          Shadow(color: Colors.red, blurRadius: 28),
                        ])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single filled/empty pip in the horizontal shots counter.
class _CounterPip extends StatelessWidget {
  const _CounterPip({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? const Color(0xFFc0392b) : Colors.transparent,
        border: Border.all(
            color: filled ? const Color(0xFFff6b5a) : const Color(0xFF6b5a45),
            width: 2),
        boxShadow: filled
            ? [
                BoxShadow(
                    color: const Color(0xFFc0392b).withValues(alpha: 0.6),
                    blurRadius: 7)
              ]
            : null,
      ),
    );
  }
}
