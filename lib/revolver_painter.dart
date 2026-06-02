import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Side-view revolver illustration drawn with CustomPaint (no external assets,
/// copyright-free). The whole gun is rotated clockwise so the muzzle points to
/// the bottom-right, as requested.
///
/// [cylinderAngle]   radians the cylinder drum is rotated (for the spin anim).
/// [bulletChamber]   index 0..5 of the live round (only revealed when [reveal]).
/// [reveal]          when true, the live chamber is drawn loaded (after a bang).
/// [hammerCock]      0..1 how far the hammer is pulled back (trigger feedback).
class RevolverPainter extends CustomPainter {
  RevolverPainter({
    required this.cylinderAngle,
    required this.bulletChamber,
    required this.reveal,
    required this.hammerCock,
  });

  final double cylinderAngle;
  final int bulletChamber;
  final bool reveal;
  final double hammerCock;

  // gun-metal palette
  static const _metalLight = Color(0xFF9aa0a8);
  static const _metalMid = Color(0xFF565a61);
  static const _metalDark = Color(0xFF26282d);
  static const _metalEdge = Color(0xFF14151a);
  static const _woodLight = Color(0xFF7a5230);
  static const _woodDark = Color(0xFF3d2614);
  static const _brass = Color(0xFFd9b24a);
  static const _brassDark = Color(0xFF8a6a1f);

  @override
  void paint(Canvas canvas, Size size) {
    // Fit the gun-local coordinate system into the widget.
    // The gun (barrel pointing +X) spans roughly x:[-2.4, 3.6], y:[-1.2, 2.2].
    final s = size.shortestSide / 6.2;
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.46);
    // Rotate clockwise so the muzzle (+X) tilts down -> bottom-right.
    canvas.rotate(0.42);
    canvas.scale(s);

    _drawGrip(canvas);
    _drawTriggerGuard(canvas);
    _drawFrameAndBarrel(canvas);
    _drawHammer(canvas);
    _drawCylinder(canvas);
    _drawTrigger(canvas);

    canvas.restore();
  }

  // ---- grip / handle (wood), drops down-left behind the cylinder ----
  void _drawGrip(Canvas canvas) {
    final path = Path()
      ..moveTo(-0.45, 0.15)
      ..lineTo(-0.95, 0.05)
      ..cubicTo(-1.35, 0.45, -1.75, 1.35, -1.95, 2.05)
      ..cubicTo(-1.55, 2.25, -1.05, 2.25, -0.7, 2.0)
      ..cubicTo(-0.45, 1.25, -0.2, 0.7, -0.1, 0.35)
      ..close();
    final rect = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: const [_woodLight, _woodDark],
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05
        ..color = _metalEdge,
    );
    // a couple of grip checkering highlights
    final hl = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.025
      ..color = Colors.white.withValues(alpha: 0.10);
    for (int i = 0; i < 3; i++) {
      final d = 0.25 + i * 0.3;
      canvas.drawLine(
          Offset(-0.85 - d * 0.5, 0.45 + d), Offset(-1.6, 0.95 + d * 0.6), hl);
    }
  }

  // ---- frame + barrel (metal), barrel points +X (right) ----
  void _drawFrameAndBarrel(Canvas canvas) {
    // top strap / frame over the cylinder, into the barrel
    final barrel = Path()
      ..moveTo(-0.55, -0.62)
      ..lineTo(3.35, -0.5) // top of barrel to muzzle
      ..lineTo(3.5, -0.46)
      ..lineTo(3.5, 0.12) // muzzle face
      ..lineTo(3.35, 0.16)
      ..lineTo(0.95, 0.2) // underside of barrel back to frame
      ..lineTo(0.6, 0.55)
      ..lineTo(-0.55, 0.5) // frame bottom
      ..close();
    final b = barrel.getBounds();
    canvas.drawPath(
      barrel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_metalLight, _metalMid, _metalDark],
          stops: [0.0, 0.45, 1.0],
        ).createShader(b),
    );
    canvas.drawPath(
      barrel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05
        ..color = _metalEdge,
    );
    // barrel top rib highlight
    canvas.drawLine(
      const Offset(-0.4, -0.55),
      const Offset(3.3, -0.43),
      Paint()
        ..strokeWidth = 0.04
        ..color = Colors.white.withValues(alpha: 0.25),
    );
    // front sight
    final sight = Path()
      ..moveTo(3.05, -0.5)
      ..lineTo(3.2, -0.72)
      ..lineTo(3.3, -0.72)
      ..lineTo(3.32, -0.48)
      ..close();
    canvas.drawPath(sight, Paint()..color = _metalDark);
    // muzzle bore
    canvas.drawCircle(const Offset(3.46, -0.17), 0.1,
        Paint()..color = const Color(0xFF0a0a0c));
    // ejector rod under barrel
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0.9, 0.24, 2.3, 0.14), const Radius.circular(0.07)),
      Paint()..color = _metalDark,
    );
    canvas.drawCircle(const Offset(3.2, 0.31), 0.1, Paint()..color = _metalMid);
  }

  // ---- hammer at the rear-top (cocks back with trigger) ----
  void _drawHammer(Canvas canvas) {
    canvas.save();
    canvas.translate(-0.7, -0.55);
    canvas.rotate(-0.5 * hammerCock); // pull back
    final hammer = Path()
      ..moveTo(0.0, 0.0)
      ..lineTo(-0.45, -0.35)
      ..lineTo(-0.55, -0.5)
      ..lineTo(-0.38, -0.62)
      ..lineTo(-0.18, -0.42)
      ..lineTo(0.12, -0.05)
      ..close();
    canvas.drawPath(
      hammer,
      Paint()
        ..shader = const LinearGradient(
          colors: [_metalMid, _metalEdge],
        ).createShader(const Rect.fromLTWH(-0.55, -0.62, 0.7, 0.62)),
    );
    // thumb spur ridges
    final ridge = Paint()
      ..strokeWidth = 0.03
      ..color = Colors.black.withValues(alpha: 0.5);
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
          Offset(-0.5 + i * 0.05, -0.5), Offset(-0.4 + i * 0.05, -0.58), ridge);
    }
    canvas.restore();
  }

  // ---- the rotating 6-shot cylinder ----
  void _drawCylinder(Canvas canvas) {
    const r = 1.08;
    // drum body
    final body = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        radius: 1.0,
        colors: [_metalLight, _metalMid, _metalDark],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r, body);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.06
        ..color = _metalEdge,
    );

    canvas.save();
    canvas.rotate(cylinderAngle);
    // 6 flutes (scallops) + chamber holes
    const holeR = 0.62;
    const chamberR = 0.2;
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * math.pi - math.pi / 2;
      final c = Offset(math.cos(a) * holeR, math.sin(a) * holeR);
      // flute shading between chambers
      final flute = Offset(math.cos(a + math.pi / 6) * (r - 0.06),
          math.sin(a + math.pi / 6) * (r - 0.06));
      canvas.drawCircle(flute, 0.16,
          Paint()..color = Colors.black.withValues(alpha: 0.18));
      // chamber hole
      canvas.drawCircle(c, chamberR, Paint()..color = const Color(0xFF101013));
      canvas.drawCircle(
        c,
        chamberR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.035
          ..color = _metalLight.withValues(alpha: 0.6),
      );
      // when revealed, draw the brass primer in the live chamber
      if (reveal && i == bulletChamber) {
        canvas.drawCircle(c, chamberR * 0.92,
            Paint()..color = _brass);
        canvas.drawCircle(c, chamberR * 0.42, Paint()..color = _brassDark);
      }
    }
    // center pin
    canvas.drawCircle(Offset.zero, 0.16, Paint()..color = _metalDark);
    canvas.drawCircle(Offset.zero, 0.16,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 0.03..color = _metalEdge);
    canvas.drawCircle(const Offset(-0.05, -0.05), 0.06,
        Paint()..color = _metalLight);
    canvas.restore();
  }

  // ---- trigger guard loop ----
  void _drawTriggerGuard(Canvas canvas) {
    final guard = Path()
      ..moveTo(-0.05, 0.45)
      ..cubicTo(0.55, 0.55, 0.7, 1.15, 0.35, 1.5)
      ..cubicTo(0.1, 1.75, -0.4, 1.7, -0.5, 1.35);
    canvas.drawPath(
      guard,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.14
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(colors: [_metalMid, _metalDark])
            .createShader(const Rect.fromLTWH(-0.5, 0.45, 1.2, 1.3)),
    );
  }

  // ---- trigger blade (inside the guard) ----
  void _drawTrigger(Canvas canvas) {
    canvas.save();
    canvas.translate(0.05, 0.7);
    canvas.rotate(0.35 * hammerCock);
    final t = Path()
      ..moveTo(0.0, 0.0)
      ..cubicTo(0.18, 0.2, 0.16, 0.6, 0.02, 0.85)
      ..lineTo(-0.12, 0.8)
      ..cubicTo(-0.05, 0.5, -0.08, 0.2, -0.14, 0.02)
      ..close();
    canvas.drawPath(t, Paint()..color = _metalDark);
    canvas.drawPath(
        t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.03
          ..color = _metalEdge);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RevolverPainter old) =>
      old.cylinderAngle != cylinderAngle ||
      old.reveal != reveal ||
      old.bulletChamber != bulletChamber ||
      old.hammerCock != hammerCock;
}
