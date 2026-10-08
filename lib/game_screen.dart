import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Hue Hop — tap to hop through color-matched gates.
class HueHopScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const HueHopScreen({super.key, required this.players, required this.callbacks});

  @override
  State<HueHopScreen> createState() => _HueHopScreenState();
}

const _palette = [
  Color(0xFFFF5D8F), // pink
  Color(0xFF4DD8FF), // cyan
  Color(0xFFFFD93D), // yellow
  Color(0xFF9B5DE5), // purple
];

class _Gate {
  final double y, holeX;
  final int color;
  bool passed = false;
  _Gate(this.y, this.holeX, this.color);
}

class _Orb {
  final double x, y;
  final int color;
  bool taken = false;
  _Orb(this.x, this.y, this.color);
}

class _Particle {
  double x, y, vx, vy, life;
  final Color color;
  _Particle(this.x, this.y, this.vx, this.vy, this.life, this.color);
}

class _HueHopScreenState extends State<HueHopScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _last = Duration.zero;

  bool started = false, over = false;
  double bx = 0, by = 0, vy = 0; // ball
  int ballColor = 0;
  double camY = 0;
  double time = 0;
  int score = 0, best = 0;
  Size view = Size.zero;

  final List<_Gate> gates = [];
  final List<_Orb> orbs = [];
  final List<_Particle> parts = [];
  final List<Offset> trail = [];
  final rng = Random();
  int _gateCount = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => best = p.getInt('huehop_best') ?? 0);
    });
    _ticker = createTicker(_tick)..start();
  }

  void _reset(Size s) {
    bx = s.width / 2;
    by = 0;
    vy = 0;
    camY = 0;
    ballColor = rng.nextInt(4);
    gates.clear();
    orbs.clear();
    parts.clear();
    trail.clear();
    _gateCount = 0;
    score = 0;
    for (int i = 0; i < 8; i++) {
      _spawnGate();
    }
  }

  void _spawnGate() {
    _gateCount++;
    final y = -_gateCount * 300.0;
    final margin = 70.0;
    final holeX = margin + rng.nextDouble() * (view.width - margin * 2);
    final color = rng.nextInt(4);
    gates.add(_Gate(y, holeX, color));
    // swapper orb between gates, a different color than the ball's current one
    if (_gateCount > 1) {
      int c = rng.nextInt(4);
      if (c == ballColor) { c = (c + 1) % 4; }
      orbs.add(_Orb(holeX + (rng.nextBool() ? 90 : -90), y + 150, c));
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 0.016 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (!mounted || over || !started) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    setState(() => _step(dt.clamp(0.0, 0.05)));
  }

  void _step(double dt) {
    time += dt;
    final prevY = by;

    // physics
    vy += 2000 * dt;
    by += vy * dt;
    // auto-bounce on start floor
    if (by >= 0 && _gateCount < 9) {
      by = 0;
      vy = -720;
      Sfx.tap();
    }

    // camera follows upward only
    final target = by - view.height * 0.55;
    if (target < camY) camY = target;

    // trail
    trail.add(Offset(bx, by));
    if (trail.length > 14) trail.removeAt(0);

    // spawn ahead
    while (gates.isEmpty || gates.last.y > camY - view.height * 1.5) {
      _spawnGate();
    }
    gates.removeWhere((g) => g.y > camY + view.height);
    orbs.removeWhere((o) => o.y > camY + view.height);

    // orb pickup
    for (final o in orbs) {
      if (!o.taken && (bx - o.x).abs() < 42 && (by - o.y).abs() < 42) {
        o.taken = true;
        ballColor = o.color;
        Sfx.click();
      }
    }

    // gate crossing (moving upward through gate plane)
    for (final g in gates) {
      if (!g.passed && prevY > g.y && by <= g.y) {
        g.passed = true;
        final inHole = (bx - g.holeX).abs() < 62;
        if (inHole && g.color == ballColor) {
          score++;
          Sfx.win();
        } else {
          _splat(inHole ? 'Wrong color! 🎨' : 'Missed the hole! 🕳️');
          return;
        }
      }
    }

    // fell below view
    if (by - camY > view.height + 60) {
      _splat('You fell! 🕳️');
      return;
    }

    // particles
    for (final p in parts) {
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 900 * dt;
    }
    parts.removeWhere((p) => p.life <= 0);
  }

  void _hop() {
    if (!started || over) return;
    vy = -980;
    Sfx.move();
  }

  void _splat(String why) {
    over = true;
    for (int i = 0; i < 26; i++) {
      parts.add(_Particle(bx, by, (rng.nextDouble() - 0.5) * 500, -rng.nextDouble() * 500,
          0.7 + rng.nextDouble() * 0.5, _palette[ballColor]));
    }
    Sfx.lose();
    _finish(why);
  }

  Future<void> _finish(String why) async {
    widget.players[0].score = score;
    widget.callbacks.refreshHud();
    final prefs = await SharedPreferences.getInstance();
    final isBest = score > best;
    if (isBest) {
      await prefs.setInt('huehop_best', score);
      if (mounted) setState(() => best = score);
    }
    if (!mounted) return;
    widget.callbacks.finish(
      headline: '$why  $score gates! 🌈',
      subline: isBest ? 'NEW BEST! 🥇' : 'Best: $best gates.',
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return LayoutBuilder(
      builder: (_, c) {
        view = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!started && !over) {
              setState(() {
                _reset(view);
                started = true;
              });
            } else {
              _hop();
            }
          },
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _HuePainter(
                  bx: bx, by: by, camY: camY, time: time,
                  gates: gates, orbs: orbs, parts: parts, trail: trail,
                  ballColor: ballColor, started: started, theme: t,
                ),
              ),
              Positioned(
                top: 12, left: 16, right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_hud('$score 🌈', t), _hud('🏆 $best', t)],
                ),
              ),
              if (!started && !over)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                    decoration: BoxDecoration(color: t.surface, borderRadius: t.radius),
                    child: Text('Tap to start!\nMatch your color to each gate 🎯',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: t.text, fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _hud(String s, GameTheme t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: t.surface.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(14)),
        child: Text(s, style: TextStyle(color: t.text, fontWeight: FontWeight.w800, fontSize: 15)),
      );
}

class _HuePainter extends CustomPainter {
  final double bx, by, camY, time;
  final List<_Gate> gates;
  final List<_Orb> orbs;
  final List<_Particle> parts;
  final List<Offset> trail;
  final int ballColor;
  final bool started;
  final GameTheme theme;

  _HuePainter({
    required this.bx, required this.by, required this.camY, required this.time,
    required this.gates, required this.orbs, required this.parts, required this.trail,
    required this.ballColor, required this.started, required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF14101F));
    canvas.save();
    canvas.translate(0, -camY);

    // start floor
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 14), Paint()..color = theme.accent);

    // orbs
    for (final o in orbs) {
      if (o.taken) continue;
      final pulse = 1 + sin(time * 5 + o.x) * 0.12;
      final col = _palette[o.color];
      canvas.drawCircle(Offset(o.x, o.y), 22 * pulse, Paint()..color = col.withValues(alpha: 0.25));
      canvas.drawCircle(Offset(o.x, o.y), 14 * pulse, Paint()..color = col);
      canvas.drawArc(Rect.fromCircle(center: Offset(o.x, o.y), radius: 19 * pulse),
          time * 3, 4.2, false, Paint()..color = Colors.white..strokeWidth = 3..style = PaintingStyle.stroke);
    }

    // gates: full-width bar with circular hole
    for (final g in gates) {
      final col = _palette[g.color];
      final path = Path()
        ..addRect(Rect.fromLTWH(0, g.y - 12, size.width, 24))
        ..addOval(Rect.fromCircle(center: Offset(g.holeX, g.y), radius: 62))
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(path, Paint()..color = col.withValues(alpha: g.passed ? 0.35 : 0.9));
      // glow ring around hole
      canvas.drawCircle(Offset(g.holeX, g.y), 62,
          (Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = 5));
      // chevrons
      final cp = Paint()..color = Colors.white.withValues(alpha: 0.7)..strokeWidth = 4..strokeCap = StrokeCap.round;
      final bob = sin(time * 4 + g.y * 0.02) * 6;
      for (int i = 0; i < 2; i++) {
        final yy = g.y + 26 + i * 18 + bob;
        canvas.drawLine(Offset(g.holeX - 12, yy), Offset(g.holeX, yy + 10), cp);
        canvas.drawLine(Offset(g.holeX + 12, yy), Offset(g.holeX, yy + 10), cp);
      }
    }

    // trail
    for (int i = 0; i < trail.length; i++) {
      final a = i / trail.length;
      canvas.drawCircle(trail[i], 16 * a, Paint()..color = _palette[ballColor].withValues(alpha: 0.18 * a));
    }

    // ball
    if (started) {
      final squash = 1 + (sin(time * 18) * 0.04);
      canvas.drawCircle(Offset(bx, by), 20, Paint()..color = _palette[ballColor].withValues(alpha: 0.3));
      canvas.drawOval(
          Rect.fromCenter(center: Offset(bx, by), width: 34 * squash, height: 34 / squash),
          Paint()..color = _palette[ballColor]);
      // eyes
      canvas.drawCircle(Offset(bx - 7, by - 4), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(bx + 7, by - 4), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(bx - 6, by - 3), 2.4, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(bx + 8, by - 3), 2.4, Paint()..color = Colors.black);
    }

    // particles
    for (final p in parts) {
      canvas.drawCircle(Offset(p.x, p.y), 6 * p.life.clamp(0.0, 1.0),
          Paint()..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0)));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HuePainter old) => true;
}
