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

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  static const int chambers = 6;

  final AudioManager _audio = AudioManager();
  final math.Random _rng = math.Random();

  int _bulletAt = 0; // chamber 0..5 holding the live round
  int _pulls = 0; // how many times survived (== shots fired count)
  _Phase _phase = _Phase.ready;

  double _cylAngle = 0; // current cylinder rotation (radians)
  double _spinFrom = 0, _spinTo = 0;

  late final AnimationController _spinCtrl; // cylinder spin on a safe pull
  late final AnimationController _flashCtrl; // red flash + shake on bang
  late final AnimationController _cockCtrl; // hammer cock on press
  late final AnimationController _pulseCtrl; // tap-indicator pulse

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..addListener(_onSpinTick)
      ..addStatusListener(_onSpinStatus);
    _flashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addListener(() => setState(() {}));
    _cockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120))
      ..addListener(() => setState(() {}));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
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
        _pulls++;
        _phase = _Phase.ready;
      });
    }
  }

  /// The trigger pull — the core action.
  void _pull() {
    if (_phase != _Phase.ready) {
      if (_phase == _Phase.dead) _reset();
      return;
    }
    _audio.click();
    // hammer cock feedback
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
    _audio.spin();
    _spinFrom = _cylAngle;
    // A lively spin: ~1.5 turns plus one chamber notch, decelerating.
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
    // little reload spin for feel
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
    _pulseCtrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flash = _flashCtrl.value;
    // shake decays over the first ~40% of the flash animation
    final shakeT = (1 - (flash / 0.4)).clamp(0.0, 1.0);
    final shake = math.sin(flash * math.pi * 14) * 14 * shakeT;

    return Scaffold(
      backgroundColor: const Color(0xFF140f0b),
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
                    center: Alignment(-0.2, -0.1),
                    radius: 1.2,
                    colors: [Color(0xFF2a1d12), Color(0xFF140f0b)],
                  ),
                ),
              ),
            ),
            // main content
            Transform.translate(
              offset: Offset(shake, shake * 0.3),
              child: SafeArea(
                child: Column(
                  children: [
                    _topBar(),
                    Expanded(child: _revolverArea()),
                    _bottomBar(),
                  ],
                ),
              ),
            ),
            // red flash overlay on a live round
            if (flash > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.red.withValues(
                      alpha: (math.sin(flash * math.pi) * 0.7).clamp(0.0, 0.7),
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

  // ---- top: title + horizontal shots-fired counter ----
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'REVOLVER\nROULETTE',
            style: TextStyle(
              fontSize: 15,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Color(0xFFe8d9c5),
            ),
          ),
          const Spacer(),
          _shotsCounter(),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => setState(() => _audio.muted = !_audio.muted),
            icon: Icon(
              _audio.muted ? Icons.volume_off : Icons.volume_up,
              color: const Color(0xFFb9a88f),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shotsCounter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'SHOTS FIRED · 쏜 횟수',
          style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: Color(0xFF9c8b73),
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < chambers; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _CounterPip(filled: i < _pulls),
              ),
            const SizedBox(width: 8),
            Text(
              '$_pulls',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFFe8d9c5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- center: the revolver + tap indicator ----
  Widget _revolverArea() {
    return LayoutBuilder(
      builder: (context, c) {
        final pulse = _pulseCtrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: RevolverPainter(
                  cylinderAngle: _cylAngle,
                  bulletChamber: _bulletAt,
                  reveal: _phase == _Phase.dead,
                  hammerCock: _cockCtrl.value,
                ),
              ),
            ),
            // tap-to-spin indicator near the trigger (center-lower area)
            if (_phase == _Phase.ready)
              Align(
                alignment: const Alignment(0.05, 0.42),
                child: _TapIndicator(pulse: pulse),
              ),
          ],
        );
      },
    );
  }

  // ---- bottom: status / instructions ----
  Widget _bottomBar() {
    String msg;
    Color col;
    switch (_phase) {
      case _Phase.ready:
        msg = _pulls == 0
            ? '화면을 탭해 방아쇠를 당기세요 · TAP TO PULL THE TRIGGER'
            : '한 발 더? 화면을 탭하세요 · ONE MORE? TAP TO PULL';
        col = const Color(0xFFb9a88f);
        break;
      case _Phase.spinning:
        msg = '...철컥... 실린더 회전 · CLICK... CYLINDER SPINS';
        col = const Color(0xFF8fb98f);
        break;
      case _Phase.dead:
        msg = '💥 탕! 명중! 탭하면 재장전 · BANG! TAP TO RELOAD';
        col = const Color(0xFFff8a7a);
        break;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: col,
        ),
      ),
    );
  }

  Widget _deadOverlay(double flash) {
    final t = (flash * 2).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.8 + t * 0.2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('💥', style: TextStyle(fontSize: 56)),
                Text(
                  'BANG!',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 12),
                      Shadow(color: Colors.red, blurRadius: 24),
                    ],
                  ),
                ),
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
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? const Color(0xFFc0392b) : Colors.transparent,
        border: Border.all(
          color: filled ? const Color(0xFFff6b5a) : const Color(0xFF6b5a45),
          width: 2,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                    color: const Color(0xFFc0392b).withValues(alpha: 0.6),
                    blurRadius: 8)
              ]
            : null,
      ),
    );
  }
}

/// Pulsing "TAP HERE" indicator that shows where to tap.
class _TapIndicator extends StatelessWidget {
  const _TapIndicator({required this.pulse});
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final scale = 0.9 + pulse * 0.25;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: scale,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFffd24a)
                      .withValues(alpha: 0.5 + pulse * 0.5),
                  width: 3),
              color: const Color(0xFFffd24a).withValues(alpha: 0.10),
            ),
            child: const Icon(Icons.touch_app,
                color: Color(0xFFffd24a), size: 32),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '여기 탭 · TAP',
            style: TextStyle(
              color: Color(0xFFffd24a),
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
