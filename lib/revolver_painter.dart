import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Realistic side-view revolver drawn with CustomPaint (no external art,
/// copyright-free). The gun lies horizontally and is auto-scaled to fill the
/// screen: barrel/muzzle to the RIGHT, grip and trigger to the LOWER-LEFT.
///
/// [cylinderAngle] radians the cylinder drum is rotated (spin animation).
/// [bulletChamber] index 0..5 of the live round (revealed only when [reveal]).
/// [reveal]        when true, the live chamber shows its brass round.
/// [hammerCock]    0..1 how far the hammer is thumbed back (trigger feedback).
/// [muzzleFlash]   0..1 muzzle-flash intensity when the live round fires.
class RevolverPainter extends CustomPainter {
  RevolverPainter({
    required this.cylinderAngle,
    required this.bulletChamber,
    required this.reveal,
    required this.hammerCock,
    required this.muzzleFlash,
  });

  final double cylinderAngle;
  final int bulletChamber;
  final bool reveal;
  final double hammerCock;
  final double muzzleFlash;

  // bluedsteel gun-metal palette
  static const _steelHi = Color(0xFF9aa3ad);
  static const _steelMid = Color(0xFF4b515b);
  static const _steelLo = Color(0xFF23262d);
  static const _steelEdge = Color(0xFF0e0f13);
  static const _woodHi = Color(0xFF7a4f29);
  static const _woodLo = Color(0xFF3a2412);
  static const _brass = Color(0xFFd9b24a);
  static const _brassLo = Color(0xFF8a6a1f);

  // local design bounding box (x right, y down); cylinder centre at origin
  static const double _bx0 = -3.05, _by0 = -1.45, _bx1 = 5.55, _by1 = 3.15;

  @override
  void paint(Canvas canvas, Size size) {
    final bw = _bx1 - _bx0, bh = _by1 - _by0;
    final s = math.min(size.width / bw, size.height / bh) * 0.96;
    final cx = (_bx0 + _bx1) / 2, cy = (_by0 + _by1) / 2;
    canvas.save();
    canvas.translate(size.width / 2 - cx * s, size.height / 2 - cy * s);
    canvas.scale(s);

    _drawShadow(canvas);
    _drawGrip(canvas);
    _drawTriggerGuardAndTrigger(canvas);
    _drawBarrel(canvas);
    _drawFrame(canvas);
    _drawHammer(canvas);
    _drawCylinder(canvas);
    _drawSights(canvas);
    if (muzzleFlash > 0.01) _drawMuzzleFlash(canvas);

    canvas.restore();
  }

  void _drawShadow(Canvas canvas) {
    final p = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.18);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(1.0, 2.95), width: 7.6, height: 0.7),
        p);
  }

  // ---- grip: drops down-left from behind the frame ----
  void _drawGrip(Canvas canvas) {
    // steel grip frame (backstrap + frontstrap)
    final frame = Path()
      ..moveTo(-0.55, -0.35)
      ..lineTo(-1.05, -0.2)
      ..cubicTo(-1.7, 0.6, -2.35, 1.9, -2.55, 2.75) // backstrap
      ..cubicTo(-2.25, 2.98, -1.55, 2.98, -1.2, 2.7)
      ..cubicTo(-0.95, 1.95, -0.55, 1.2, -0.15, 0.85) // frontstrap
      ..lineTo(-0.1, 0.45)
      ..close();
    final fb = frame.getBounds();
    canvas.drawPath(
        frame,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [_steelMid, _steelLo, _steelEdge],
            stops: [0.0, 0.5, 1.0],
          ).createShader(fb));

    // wood grip panel inset
    final wood = Path()
      ..moveTo(-0.62, 0.0)
      ..cubicTo(-1.2, 0.7, -1.85, 1.85, -2.05, 2.55)
      ..cubicTo(-1.8, 2.72, -1.4, 2.72, -1.18, 2.52)
      ..cubicTo(-0.95, 1.85, -0.62, 1.15, -0.32, 0.7)
      ..cubicTo(-0.32, 0.4, -0.45, 0.12, -0.62, 0.0)
      ..close();
    final wb = wood.getBounds();
    canvas.drawPath(
        wood,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [_woodHi, _woodLo],
          ).createShader(wb));
    // checkering
    final ck = Paint()
      ..strokeWidth = 0.02
      ..color = Colors.black.withValues(alpha: 0.22);
    for (int i = -3; i <= 4; i++) {
      final o = i * 0.16;
      canvas.drawLine(Offset(-0.55 + o, 0.35), Offset(-1.7 + o, 2.1), ck);
      canvas.drawLine(Offset(-1.5 + o, 0.55), Offset(-0.6 + o, 2.3), ck);
    }
    // grip cap + a fixing screw
    canvas.drawCircle(const Offset(-1.05, 1.25), 0.1,
        Paint()..color = _steelHi.withValues(alpha: 0.8));
    canvas.drawCircle(const Offset(-1.05, 1.25), 0.05, Paint()..color = _steelLo);
    canvas.drawPath(
        frame,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.045
          ..color = _steelEdge);
  }

  // ---- barrel: long, to the right; vented rib on top, ejector rod beneath ----
  void _drawBarrel(Canvas canvas) {
    // ejector-rod housing (under-lug) beneath the barrel
    final lug = RRect.fromRectAndRadius(
        const Rect.fromLTRB(0.85, 0.16, 4.5, 0.56), const Radius.circular(0.12));
    canvas.drawRRect(
        lug,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_steelMid, _steelLo],
          ).createShader(const Rect.fromLTRB(0.85, 0.16, 4.5, 0.56)));
    canvas.drawRRect(
        lug,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.03
          ..color = _steelEdge);
    // ejector rod tip
    canvas.drawCircle(const Offset(4.62, 0.36), 0.08, Paint()..color = _steelHi);

    // main barrel
    final barrel = Path()
      ..moveTo(0.8, -0.62)
      ..lineTo(4.95, -0.62) // top to muzzle
      ..lineTo(5.05, -0.55)
      ..lineTo(5.05, 0.12) // muzzle face
      ..lineTo(4.95, 0.2)
      ..lineTo(0.8, 0.2) // underside back to frame
      ..close();
    final bb = barrel.getBounds();
    canvas.drawPath(
        barrel,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_steelHi, _steelMid, _steelLo],
            stops: [0.0, 0.4, 1.0],
          ).createShader(bb));
    canvas.drawPath(
        barrel,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.045
          ..color = _steelEdge);
    // vented rib on top
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTRB(0.9, -0.78, 4.9, -0.6),
            const Radius.circular(0.04)),
        Paint()..color = _steelLo);
    for (double x = 1.2; x < 4.7; x += 0.42) {
      canvas.drawRect(Rect.fromLTWH(x, -0.76, 0.12, 0.14),
          Paint()..color = _steelEdge.withValues(alpha: 0.7));
    }
    // top highlight line
    canvas.drawLine(const Offset(0.95, -0.55), const Offset(4.85, -0.55),
        Paint()..strokeWidth = 0.03..color = Colors.white.withValues(alpha: 0.22));
    // muzzle face + bore
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTRB(4.95, -0.6, 5.12, 0.18),
            const Radius.circular(0.05)),
        Paint()..color = _steelLo);
    canvas.drawCircle(const Offset(5.03, -0.21), 0.12,
        Paint()..color = const Color(0xFF050506));
    canvas.drawCircle(const Offset(5.03, -0.21), 0.12,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 0.03..color = _steelEdge);
  }

  // ---- frame around / behind the cylinder ----
  void _drawFrame(Canvas canvas) {
    // top strap over the cylinder
    final strap = Path()
      ..moveTo(-1.05, -0.95)
      ..lineTo(0.95, -0.78)
      ..lineTo(0.95, -0.5)
      ..lineTo(-1.05, -0.62)
      ..close();
    canvas.drawPath(
        strap,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_steelMid, _steelLo],
          ).createShader(const Rect.fromLTRB(-1.05, -0.95, 0.95, -0.5)));
    // recoil shield behind cylinder
    final shield = Path()
      ..moveTo(-0.95, -0.85)
      ..cubicTo(-1.5, -0.5, -1.5, 0.7, -0.95, 1.05)
      ..lineTo(-0.6, 0.9)
      ..cubicTo(-1.0, 0.5, -1.0, -0.3, -0.62, -0.7)
      ..close();
    final sb = shield.getBounds();
    canvas.drawPath(
        shield,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_steelMid, _steelLo, _steelEdge],
          ).createShader(sb));
    canvas.drawPath(
        shield,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.04
          ..color = _steelEdge);
    // cylinder-release latch
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTRB(-1.02, 0.0, -0.78, 0.34),
            const Radius.circular(0.05)),
        Paint()..color = _steelHi.withValues(alpha: 0.75));
  }

  // ---- hammer at the rear (cocks back) ----
  void _drawHammer(Canvas canvas) {
    canvas.save();
    canvas.translate(-1.0, -0.78);
    canvas.rotate(-0.5 * hammerCock);
    final hammer = Path()
      ..moveTo(0.05, 0.1)
      ..lineTo(-0.42, -0.2)
      ..lineTo(-0.6, -0.34)
      ..cubicTo(-0.72, -0.5, -0.55, -0.66, -0.4, -0.56)
      ..lineTo(-0.18, -0.34)
      ..lineTo(0.2, 0.0)
      ..close();
    canvas.drawPath(
        hammer,
        Paint()
          ..shader = const LinearGradient(colors: [_steelMid, _steelEdge])
              .createShader(const Rect.fromLTRB(-0.7, -0.66, 0.2, 0.1)));
    canvas.drawPath(
        hammer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.03
          ..color = _steelEdge);
    // thumb-spur serrations
    final r = Paint()..strokeWidth = 0.025..color = Colors.black.withValues(alpha: 0.55);
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(Offset(-0.55 + i * 0.05, -0.45),
          Offset(-0.47 + i * 0.05, -0.55), r);
    }
    canvas.restore();
  }

  // ---- rotating 6-shot cylinder ----
  void _drawCylinder(Canvas canvas) {
    const r = 1.12;
    canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.35, -0.4),
            radius: 1.0,
            colors: [_steelHi, _steelMid, _steelLo],
            stops: [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)));
    canvas.drawCircle(Offset.zero, r,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 0.06..color = _steelEdge);

    canvas.save();
    canvas.rotate(cylinderAngle);
    const holeR = 0.66;
    const chamberR = 0.22;
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * math.pi - math.pi / 2;
      // flute scallop between chambers (shading)
      final fa = a + math.pi / 6;
      canvas.drawCircle(
          Offset(math.cos(fa) * (r - 0.05), math.sin(fa) * (r - 0.05)),
          0.2,
          Paint()..color = Colors.black.withValues(alpha: 0.16));
      // chamber bolt-stop notch on the rim
      canvas.drawCircle(Offset(math.cos(fa) * r, math.sin(fa) * r), 0.05,
          Paint()..color = _steelEdge.withValues(alpha: 0.7));
      final c = Offset(math.cos(a) * holeR, math.sin(a) * holeR);
      canvas.drawCircle(c, chamberR, Paint()..color = const Color(0xFF0c0c0f));
      canvas.drawCircle(
          c,
          chamberR,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.035
            ..color = _steelHi.withValues(alpha: 0.55));
      if (reveal && i == bulletChamber) {
        canvas.drawCircle(c, chamberR * 0.94, Paint()..color = _brass);
        canvas.drawCircle(c, chamberR * 0.44, Paint()..color = _brassLo);
      }
    }
    // center pin / ratchet
    canvas.drawCircle(Offset.zero, 0.17, Paint()..color = _steelLo);
    canvas.drawCircle(Offset.zero, 0.17,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 0.03..color = _steelEdge);
    canvas.drawCircle(const Offset(-0.05, -0.05), 0.06, Paint()..color = _steelHi);
    canvas.restore();
  }

  // ---- trigger guard + trigger ----
  void _drawTriggerGuardAndTrigger(Canvas canvas) {
    final guard = Path()
      ..moveTo(-0.15, 0.5)
      ..cubicTo(0.5, 0.6, 0.62, 1.25, 0.25, 1.62)
      ..cubicTo(0.0, 1.85, -0.5, 1.8, -0.62, 1.45);
    canvas.drawPath(
        guard,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.15
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(colors: [_steelMid, _steelLo])
              .createShader(const Rect.fromLTRB(-0.62, 0.5, 0.62, 1.85)));
    // trigger blade
    canvas.save();
    canvas.translate(-0.02, 0.78);
    canvas.rotate(0.32 * hammerCock);
    final t = Path()
      ..moveTo(0.0, 0.0)
      ..cubicTo(0.2, 0.22, 0.18, 0.62, 0.02, 0.9)
      ..lineTo(-0.14, 0.84)
      ..cubicTo(-0.05, 0.55, -0.09, 0.2, -0.16, 0.02)
      ..close();
    canvas.drawPath(t, Paint()..color = _steelLo);
    canvas.drawPath(t,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 0.03..color = _steelEdge);
    canvas.restore();
  }

  // ---- front + rear sights ----
  void _drawSights(Canvas canvas) {
    // front sight ramp near muzzle
    final fs = Path()
      ..moveTo(4.6, -0.62)
      ..lineTo(4.72, -0.92)
      ..lineTo(4.86, -0.92)
      ..lineTo(4.88, -0.6)
      ..close();
    canvas.drawPath(fs, Paint()..color = _steelLo);
    // rear sight notch over the frame
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTRB(-0.95, -1.05, -0.5, -0.85),
            const Radius.circular(0.03)),
        Paint()..color = _steelLo);
    canvas.drawRect(const Rect.fromLTRB(-0.75, -1.04, -0.69, -0.88),
        Paint()..color = _steelEdge);
  }

  // ---- muzzle flash on fire ----
  void _drawMuzzleFlash(Canvas canvas) {
    final f = muzzleFlash;
    canvas.save();
    canvas.translate(5.08, -0.21);
    final reach = 1.3 + 1.6 * f;
    // outer glow
    canvas.drawCircle(
        Offset(reach * 0.4, 0),
        1.1 * f + 0.4,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFfff3b0).withValues(alpha: 0.9 * f),
            const Color(0xFFff8a1e).withValues(alpha: 0.5 * f),
            const Color(0x00ff8a1e),
          ]).createShader(Rect.fromCircle(
              center: Offset(reach * 0.4, 0), radius: 1.1 * f + 0.4)));
    // star burst spikes
    final star = Path();
    final spikes = 9;
    for (int i = 0; i < spikes * 2; i++) {
      final ang = (i / (spikes * 2)) * 2 * math.pi;
      final rr = (i.isEven ? reach : reach * 0.42) *
          (0.8 + 0.2 * math.sin(i * 12.9));
      final p = Offset(math.cos(ang) * rr * (i.isEven ? 1.0 : 0.6),
          math.sin(ang) * rr * 0.5);
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
        star,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: f),
            const Color(0xFFffd24a).withValues(alpha: 0.95 * f),
            const Color(0xFFff5a1e).withValues(alpha: 0.6 * f),
          ]).createShader(Rect.fromCircle(center: Offset.zero, radius: reach)));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RevolverPainter old) =>
      old.cylinderAngle != cylinderAngle ||
      old.reveal != reveal ||
      old.bulletChamber != bulletChamber ||
      old.hammerCock != hammerCock ||
      old.muzzleFlash != muzzleFlash;
}
