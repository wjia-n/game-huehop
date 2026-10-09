import 'dart:math';
import 'package:flutter/material.dart';

/// Ball style catalog: the player's ball painted as a physical object.
/// Free: 0..5. Pro: 6..9.
@immutable
class BallStyleDef {
  final int index;
  final String name;
  final bool isPro;
  const BallStyleDef(this.index, this.name, {this.isPro = false});
}

class BallStyles {
  BallStyles._();
  static const List<BallStyleDef> all = [
    BallStyleDef(0, 'Smiley'),
    BallStyleDef(1, 'Soccer'),
    BallStyleDef(2, 'Basketball'),
    BallStyleDef(3, 'Beach Ball'),
    BallStyleDef(4, 'Tennis'),
    BallStyleDef(5, 'Ladybug'),
    BallStyleDef(6, 'Eight Ball', isPro: true),
    BallStyleDef(7, 'Watermelon', isPro: true),
    BallStyleDef(8, 'Donut', isPro: true),
    BallStyleDef(9, 'Golden', isPro: true),
  ];
  static bool isPro(int i) =>
      i >= 0 && i < all.length ? all[i].isPro : false;
  static String nameOf(int i) =>
      i >= 0 && i < all.length ? all[i].name : all.first.name;
}

/// Gate (obstacle) style catalog: the hoop the ball flies through.
/// Free: 0..5. Pro: 6..7.
@immutable
class GateStyleDef {
  final int index;
  final String name;
  final bool isPro;
  const GateStyleDef(this.index, this.name, {this.isPro = false});
}

class GateStyles {
  GateStyles._();
  static const List<GateStyleDef> all = [
    GateStyleDef(0, 'Chunky Ring'),
    GateStyleDef(1, 'Wooden Frame'),
    GateStyleDef(2, 'Brick Arch'),
    GateStyleDef(3, 'Candy Hoop'),
    GateStyleDef(4, 'Chalk Circle'),
    GateStyleDef(5, 'Flower Ring'),
    GateStyleDef(6, 'Tire Ring', isPro: true),
    GateStyleDef(7, 'Golden Hoop', isPro: true),
  ];
  static bool isPro(int i) =>
      i >= 0 && i < all.length ? all[i].isPro : false;
  static String nameOf(int i) =>
      i >= 0 && i < all.length ? all[i].name : all.first.name;
}

// ---------------------------------------------------------------------------
// Physical ball painter. Every style draws shading + highlight so the ball
// feels like a real object, tinted by the theme's current gate color.
// ---------------------------------------------------------------------------
void paintBall(Canvas canvas, Offset c, double r, Color base, int style) {
  Color shade(Color c, double amt) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness * (1 - amt)).clamp(0.0, 1.0))
        .toColor();
  }

  // soft ground-shadow
  canvas.drawOval(
    Rect.fromCenter(center: Offset(c.dx, c.dy + r * 1.28), width: r * 1.7, height: r * 0.42),
    Paint()..color = Colors.black.withValues(alpha: 0.18),
  );
  // body
  final body = Paint()..color = base;
  canvas.drawCircle(c, r, body);
  // bottom shading for roundness
  canvas.drawArc(
    Rect.fromCircle(center: c, radius: r),
    pi * 0.25,
    pi * 0.5,
    true,
    Paint()..color = shade(base, 0.25),
  );
  // top-left highlight
  canvas.drawCircle(
    Offset(c.dx - r * 0.35, c.dy - r * 0.4),
    r * 0.22,
    Paint()..color = Colors.white.withValues(alpha: 0.5),
  );

  final line = Paint()
    ..color = shade(base, 0.45)
    ..strokeWidth = max(2.0, r * 0.09)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  switch (style) {
    case 1: // soccer: pentagon-ish patches
      for (int i = 0; i < 5; i++) {
        final a = i * 2 * pi / 5 - pi / 2;
        final p = Offset(c.dx + cos(a) * r * 0.62, c.dy + sin(a) * r * 0.62);
        canvas.drawCircle(p, r * 0.24, Paint()..color = Colors.white.withValues(alpha: 0.9));
        canvas.drawCircle(p, r * 0.13, Paint()..color = Colors.black87);
      }
      break;
    case 2: // basketball seams
      canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), line);
      canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), line);
      canvas.drawArc(Rect.fromCircle(center: Offset(c.dx - r * 1.7, c.dy), radius: r * 1.7),
          -0.6, 1.2, false, line);
      canvas.drawArc(Rect.fromCircle(center: Offset(c.dx + r * 1.7, c.dy), radius: r * 1.7),
          pi - 0.6, 1.2, false, line);
      break;
    case 3: // beach ball panels
      final panelColors = [Colors.white, Colors.red.shade400, Colors.yellow.shade600];
      for (int i = 0; i < 6; i++) {
        final a0 = i * pi / 3;
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, pi / 3, true,
            Paint()..color = panelColors[i % 3].withValues(alpha: 0.55));
      }
      canvas.drawCircle(c, r * 0.2, Paint()..color = Colors.white);
      break;
    case 4: // tennis curve
      canvas.drawArc(Rect.fromCircle(center: Offset(c.dx - r * 1.3, c.dy), radius: r * 1.15),
          -0.7, 1.4, false, Paint()
            ..color = Colors.white
            ..strokeWidth = max(3.0, r * 0.14)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
      canvas.drawArc(Rect.fromCircle(center: Offset(c.dx + r * 1.3, c.dy), radius: r * 1.15),
          pi - 0.7, 1.4, false, Paint()
            ..color = Colors.white
            ..strokeWidth = max(3.0, r * 0.14)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
      break;
    case 5: // ladybug
      canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), line);
      final spots = [Offset(-0.45, -0.35), Offset(0.45, -0.3), Offset(-0.4, 0.35), Offset(0.42, 0.4), Offset(0, 0.05)];
      for (final s in spots) {
        canvas.drawCircle(Offset(c.dx + s.dx * r, c.dy + s.dy * r), r * 0.16, Paint()..color = Colors.black87);
      }
      break;
    case 6: // eight ball
      canvas.drawCircle(c, r * 0.52, Paint()..color = Colors.white);
      final tp = TextPainter(
        text: const TextSpan(text: '8', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
      break;
    case 7: // watermelon stripes
      for (int i = -2; i <= 2; i++) {
        canvas.drawLine(
          Offset(c.dx + i * r * 0.36 - r * 0.12, c.dy - r * 0.9),
          Offset(c.dx + i * r * 0.36 + r * 0.12, c.dy + r * 0.9),
          Paint()..color = shade(base, 0.35)..strokeWidth = max(3.0, r * 0.12)..strokeCap = StrokeCap.round,
        );
      }
      break;
    case 8: // donut: frosting + sprinkles
      canvas.drawCircle(c, r * 0.78, Paint()..color = const Color(0xFFF8BBD0));
      final rnd = Random(7);
      for (int i = 0; i < 10; i++) {
        final a = rnd.nextDouble() * 2 * pi;
        final d = rnd.nextDouble() * r * 0.62;
        final p = Offset(c.dx + cos(a) * d, c.dy + sin(a) * d);
        canvas.drawLine(p, p + Offset(cos(a + 1) * r * 0.22, sin(a + 1) * r * 0.22),
            Paint()
              ..color = [Colors.red, Colors.blue, Colors.yellow, Colors.green, Colors.purple][i % 5]
              ..strokeWidth = max(2.5, r * 0.1)
              ..strokeCap = StrokeCap.round);
      }
      canvas.drawCircle(c, r * 0.32, Paint()..color = base);
      break;
    case 9: // golden: star medallion
      canvas.drawCircle(c, r * 0.55,
          Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.stroke..strokeWidth = max(3.0, r * 0.14));
      final sp = Path();
      for (int i = 0; i < 10; i++) {
        final a = -pi / 2 + i * pi / 5;
        final rr = i.isEven ? r * 0.34 : r * 0.16;
        final p = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr);
        if (i == 0) { sp.moveTo(p.dx, p.dy); } else { sp.lineTo(p.dx, p.dy); }
      }
      sp.close();
      canvas.drawPath(sp, Paint()..color = const Color(0xFFFFD54F));
      break;
    case 0:
    default: // smiley face
      final eye = Paint()..color = Colors.black87;
      canvas.drawCircle(Offset(c.dx - r * 0.32, c.dy - r * 0.12), r * 0.13, eye);
      canvas.drawCircle(Offset(c.dx + r * 0.32, c.dy - r * 0.12), r * 0.13, eye);
      canvas.drawArc(Rect.fromCircle(center: Offset(c.dx, c.dy + r * 0.08), radius: r * 0.42),
          pi * 0.15, pi * 0.7, false,
          Paint()..color = Colors.black87..strokeWidth = max(3.0, r * 0.13)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      break;
  }
}

// ---------------------------------------------------------------------------
// Gate painter: full-width bar with a hop-hole, styled per gate style.
// Returns the hole radius used (for hit logic the engine owns its own).
// ---------------------------------------------------------------------------
void paintGate(
  Canvas canvas,
  double width,
  double y,
  double holeX,
  double holeR,
  Color color,
  int style,
  double time,
  bool passed,
) {
  final a = passed ? 0.3 : 1.0;
  final hole = Rect.fromCircle(center: Offset(holeX, y), radius: holeR);
  final bar = Path()
    ..addRect(Rect.fromLTWH(0, y - 14, width, 28))
    ..addOval(hole)
    ..fillType = PathFillType.evenOdd;

  Color shade(Color c, double amt) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness * (1 - amt)).clamp(0.0, 1.0)).toColor();
  }

  final base = Paint()..color = color.withValues(alpha: 0.92 * a);
  final dark = Paint()..color = shade(color, 0.3).withValues(alpha: 0.95 * a);
  final light = Paint()..color = Colors.white.withValues(alpha: 0.35 * a);

  switch (style) {
    case 1: // wooden frame: bar + posts
      canvas.drawPath(bar, Paint()..color = const Color(0xFF8A5A2B).withValues(alpha: a));
      canvas.drawRect(Rect.fromLTWH(0, y - 20, width, 10), Paint()..color = const Color(0xFFA9713A).withValues(alpha: a));
      canvas.drawRect(Rect.fromLTWH(0, y + 10, width, 8), dark);
      // color band around hole
      canvas.drawCircle(Offset(holeX, y), holeR + 7,
          Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 10);
      break;
    case 2: // brick arch: bricks across the bar
      canvas.drawPath(bar, base);
      final brickW = 46.0;
      final stroke = Paint()
        ..color = shade(color, 0.35).withValues(alpha: a)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      for (double x = 8; x < width; x += brickW) {
        if ((x - holeX).abs() < holeR + brickW / 2) continue;
        canvas.drawRect(Rect.fromLTWH(x, y - 14, brickW - 4, 28), stroke);
      }
      break;
    case 3: // candy hoop: stripes + white ring
      canvas.drawPath(bar, base);
      final stripe = Paint()..color = Colors.white.withValues(alpha: 0.55 * a)..strokeWidth = 7;
      for (double x = 14; x < width; x += 34) {
        if ((x - holeX).abs() < holeR + 14) continue;
        canvas.drawLine(Offset(x, y - 14), Offset(x + 10, y + 14), stripe);
      }
      canvas.drawCircle(Offset(holeX, y), holeR + 4,
          Paint()..color = Colors.white.withValues(alpha: 0.9 * a)..style = PaintingStyle.stroke..strokeWidth = 8);
      break;
    case 4: // chalk circle: dashed ring on bar
      canvas.drawPath(bar, Paint()..color = color.withValues(alpha: 0.28 * a));
      final dash = Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * a)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (double a0 = 0; a0 < 2 * pi; a0 += 0.35) {
        canvas.drawArc(Rect.fromCircle(center: Offset(holeX, y), radius: holeR + 6), a0, 0.2, false, dash);
      }
      break;
    case 5: // flower ring: petals around hole
      canvas.drawPath(bar, base);
      for (int i = 0; i < 10; i++) {
        final pa = i * 2 * pi / 10 + time * 0.2;
        final pp = Offset(holeX + cos(pa) * (holeR + 16), y + sin(pa) * (holeR + 16));
        canvas.drawCircle(pp, 11, Paint()..color = Colors.white.withValues(alpha: 0.85 * a));
        canvas.drawCircle(pp, 6, Paint()..color = color.withValues(alpha: a));
      }
      break;
    case 6: // tire ring: dark tire with tread
      canvas.drawPath(bar, Paint()..color = const Color(0xFF2B2B2E).withValues(alpha: a));
      final tread = Paint()
        ..color = const Color(0xFF55555C).withValues(alpha: a)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke;
      for (double a0 = 0; a0 < 2 * pi; a0 += 0.45) {
        canvas.drawArc(Rect.fromCircle(center: Offset(holeX, y), radius: holeR + 8), a0, 0.25, false, tread);
      }
      canvas.drawCircle(Offset(holeX, y), holeR + 2,
          Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 6);
      break;
    case 7: // golden hoop: metallic band
      canvas.drawPath(bar, Paint()..color = const Color(0xFFC9A227).withValues(alpha: 0.95 * a));
      canvas.drawRect(Rect.fromLTWH(0, y - 14, width, 8), Paint()..color = const Color(0xFFFFE082).withValues(alpha: a));
      canvas.drawRect(Rect.fromLTWH(0, y + 6, width, 8), Paint()..color = const Color(0xFF8A6D1A).withValues(alpha: a));
      canvas.drawCircle(Offset(holeX, y), holeR + 4,
          Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.stroke..strokeWidth = 7);
      break;
    case 0:
    default: // chunky ring
      canvas.drawPath(bar, base);
      canvas.drawRect(Rect.fromLTWH(0, y - 14, width, 7), light);
      canvas.drawRect(Rect.fromLTWH(0, y + 7, width, 7), dark);
      canvas.drawCircle(Offset(holeX, y), holeR,
          Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 6);
      break;
  }
}
