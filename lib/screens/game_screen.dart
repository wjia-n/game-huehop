import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../engine/huehop_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/ball_styles.dart';
import '../theme/huehop_themes.dart';
import '../theme/toy_ui.dart';

/// Game screen: renders [HueHopEngine] (which owns ALL state/phases +
/// watchdog). Tap = hop, drag horizontally = steer.
class GameScreen extends StatefulWidget {
  final HueHopAudio audio;
  final HueHopSettings settings;
  const GameScreen({super.key, required this.audio, required this.settings});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  HueHopAudio get _audio => widget.audio;
  HueHopSettings get _s => widget.settings;

  late final HueHopEngine _engine;
  bool _reviewAsked = false;
  String? _overHeadline;
  String? _overSubline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = HueHopEngine();
    _engine.onEvent = _onEngineEvent;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    _engine.configure(
      difficulty: _s.difficulty,
      mode: _s.mode,
      theme: _s.theme,
      ballStyle: _s.ballStyle,
      gateStyle: _s.gateStyle,
      view: size,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _engine.pause();
    }
  }

  // --- engine events -> juicy feedback -------------------------------------
  void _onEngineEvent(HopEvent e) {
    switch (e.type) {
      case HopEventType.hop:
        _audio.hop();
        break;
      case HopEventType.gatePass:
        _audio.gatePass();
        break;
      case HopEventType.perfect:
        _audio.gatePass();
        break;
      case HopEventType.comboBonus:
        _audio.combo();
        break;
      case HopEventType.orb:
        _audio.orb();
        break;
      case HopEventType.oof:
        _audio.wrongColor();
        break;
      case HopEventType.splat:
        _audio.wrongColor();
        break;
      case HopEventType.tickSecond:
        if (e.value <= 5 && e.value > 0) _audio.tick();
        break;
      case HopEventType.gameOver:
        _onGameOver(e);
        break;
      case HopEventType.newBest:
        break;
    }
  }

  Future<void> _onGameOver(HopEvent e) async {
    final isBest = await _s.recordRun(
        mode: _s.mode, difficulty: _s.difficulty, score: _engine.score);
    if (!mounted) return;
    setState(() {
      _overHeadline = e.label == "Time's up!"
          ? "⏱️ Time's up, ${_s.playerName}!"
          : '💥 Splat! ${_engine.score} gates';
      _overSubline = isBest
          ? '🏆 NEW BEST! ${_engine.score} gates!'
          : 'Best: ${_s.bestFor(_s.mode, _s.difficulty)} gates';
    });
    if (isBest) {
      _audio.newBest();
    } else if (e.label == "Time's up!") {
      _audio.win();
    } else {
      _audio.lose();
    }
    // Ask for a review after a new best — graceful when not from Play.
    if (isBest && !_reviewAsked) {
      _reviewAsked = true;
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      } catch (_) {}
    }
  }

  void _start() {
    // Every run start gets the start fanfare — first run and replays alike.
    _audio.gameStart();
    setState(() {
      _overHeadline = null;
      _overSubline = null;
    });
    _engine.startRun();
  }

  @override
  Widget build(BuildContext context) {
    final t = _s.theme;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // Play field: tap = hop, horizontal drag = steer.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) {
                if (_engine.phase == HopPhase.idle) {
                  _start();
                } else {
                  if (!_engine.tap()) _audio.invalid();
                }
              },
              onHorizontalDragUpdate: (d) =>
                  _engine.dragTo(d.localPosition.dx),
              onVerticalDragUpdate: (d) =>
                  _engine.dragTo(d.localPosition.dx),
              child: AnimatedBuilder(
                animation: _engine,
                builder: (_, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _HopPainter(
                    engine: _engine,
                    theme: t,
                    ballStyle: _s.ballStyle,
                    gateStyle: _s.gateStyle,
                  ),
                ),
              ),
            ),
            // HUD
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: AnimatedBuilder(
                animation: _engine,
                builder: (_, _) => Row(
                  children: [
                    _hudChip(t, '🌈 ${_engine.score}'),
                    const SizedBox(width: 8),
                    if (_engine.mode == 'attack')
                      _hudChip(t, '❤️ ${_engine.lives}'),
                    if (_engine.mode == 'attack') const SizedBox(width: 8),
                    if (_engine.mode == 'attack')
                      _hudChip(t, '⏱️ ${_engine.timeLeft.ceil()}s'),
                    const Spacer(),
                    _hudChip(t, '🏆 ${_s.bestFor(_s.mode, _s.difficulty)}'),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _audio.click();
                        _showPause(t);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: t.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: t.surfaceEdge, width: 2),
                        ),
                        child: Icon(Icons.pause,
                            color: t.text, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tap-to-start card
            AnimatedBuilder(
              animation: _engine,
              builder: (_, _) => _engine.phase == HopPhase.idle
                  ? Center(
                      child: ToyUi.panel(
                        theme: t,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Ready, ${_s.playerName}?',
                                style: ToyUi.title(20, theme: t)),
                            const SizedBox(height: 8),
                            Text(
                              _s.mode == 'attack'
                                  ? '⏱️ 90 seconds, 3 lives.\nHop through gates that match your ball color!'
                                  : '🏃 One life, endless gates.\nHop through gates that match your ball color!',
                              textAlign: TextAlign.center,
                              style: ToyUi.body(15, theme: t),
                            ),
                            const SizedBox(height: 6),
                            Text('👆 Tap to hop · ↔️ Drag to steer',
                                style: ToyUi.body(13, theme: t)),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // OOF banner (attack life lost)
            AnimatedBuilder(
              animation: _engine,
              builder: (_, _) => _engine.phase == HopPhase.oof
                  ? Center(
                      child: Text('OOF!',
                          style: ToyUi.display(64, theme: t, color: t.accent)),
                    )
                  : const SizedBox.shrink(),
            ),
            // Game-over panel
            if (_overHeadline != null)
              Center(
                child: ToyUi.panel(
                  theme: t,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_overHeadline!,
                          textAlign: TextAlign.center,
                          style: ToyUi.title(22, theme: t)),
                      const SizedBox(height: 8),
                      Text(_overSubline ?? '',
                          textAlign: TextAlign.center,
                          style: ToyUi.body(16, theme: t)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ToyUi.button(
                              theme: t, text: '🔁 Again', onTap: _start),
                          const SizedBox(width: 12),
                          ToyUi.button(
                            theme: t,
                            text: '🏠 Menu',
                            color: t.surface,
                            textColor: t.text,
                            onTap: () {
                              _audio.click();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hudChip(HueHopThemeDef t, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: t.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.surfaceEdge, width: 2),
        ),
        child: Text(text,
            style: ToyUi.title(14, theme: t)),
      );

  void _showPause(HueHopThemeDef t) {
    if (_engine.phase != HopPhase.playing) return;
    _engine.pause();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ToyUi.panel(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⏸️ Paused', style: ToyUi.title(24, theme: t)),
              const SizedBox(height: 6),
              Text('Score: ${_engine.score} gates',
                  style: ToyUi.body(15, theme: t)),
              const SizedBox(height: 16),
              ToyUi.button(
                theme: t,
                text: '▶ Resume',
                onTap: () {
                  _audio.click();
                  Navigator.of(context).pop();
                  _engine.resume();
                },
              ),
              const SizedBox(height: 10),
              ToyUi.button(
                theme: t,
                text: '🔁 Restart',
                color: t.surface,
                textColor: t.text,
                onTap: () {
                  _audio.click();
                  Navigator.of(context).pop();
                  setState(() {
                    _overHeadline = null;
                    _overSubline = null;
                  });
                  _engine.startRun();
                },
              ),
              const SizedBox(height: 10),
              ToyUi.button(
                theme: t,
                text: '🏠 Quit',
                color: t.surface,
                textColor: t.text,
                onTap: () {
                  _audio.click();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Renders the engine state: background wash, floor, orbs, gates, trail,
/// ball, particles, popups. The painter never owns logic — only paint.
class _HopPainter extends CustomPainter {
  final HueHopEngine engine;
  final HueHopThemeDef theme;
  final int ballStyle;
  final int gateStyle;

  _HopPainter({
    required this.engine,
    required this.theme,
    required this.ballStyle,
    required this.gateStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // background wash
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [theme.bgTop, theme.bg],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    canvas.save();
    canvas.translate(0, -engine.camY);

    // start floor (only near the beginning)
    if (engine.camY > -size.height) {
      final floorY = 0.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(24, floorY, size.width - 48, 26), const Radius.circular(13)),
        Paint()..color = theme.floor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(24, floorY, size.width - 48, 9), const Radius.circular(5)),
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
    }

    // orbs
    for (final o in engine.orbs) {
      if (o.taken) continue;
      final col = theme.gates[o.color % theme.gates.length];
      final pulse = 1 + sin(engine.simTime * 5 + o.x) * 0.12;
      canvas.drawCircle(Offset(o.x, o.y), 24 * pulse,
          Paint()..color = theme.orbHalo.withValues(alpha: 0.3));
      canvas.drawCircle(Offset(o.x, o.y), 15 * pulse, Paint()..color = col);
      canvas.drawCircle(
          Offset(o.x - 5 * pulse, o.y - 6 * pulse),
          5 * pulse,
          Paint()..color = Colors.white.withValues(alpha: 0.7));
    }

    // gates
    for (final g in engine.gates) {
      paintGate(
        canvas,
        size.width,
        g.y,
        g.holeX(engine.simTime),
        engine.holeRadius,
        theme.gates[g.color % theme.gates.length],
        gateStyle,
        engine.simTime,
        g.passed,
      );
    }

    // trail
    final trail = engine.trail;
    for (int i = 0; i < trail.length; i++) {
      final a = i / trail.length;
      canvas.drawCircle(trail[i], 15 * a,
          Paint()..color = theme.trail.withValues(alpha: 0.16 * a));
    }

    // ball
    if (engine.phase != HopPhase.idle) {
      final squash = 1 + sin(engine.simTime * 18) * 0.05;
      final r = 20.0;
      canvas.save();
      canvas.translate(engine.ballX, engine.ballY);
      canvas.scale(squash, 1 / squash);
      paintBall(canvas, Offset.zero, r, engine.ballPaintColor, ballStyle);
      canvas.restore();
    }

    // particles
    for (final p in engine.particles) {
      final a = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(p.x, p.y), p.size * a,
          Paint()..color = p.color.withValues(alpha: a));
    }

    // popups
    for (final p in engine.popups) {
      final a = p.life.clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            color: p.color.withValues(alpha: a),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                  color: Colors.black.withValues(alpha: 0.3 * a),
                  offset: const Offset(0, 2),
                  blurRadius: 2)
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.x - tp.width / 2, p.y - tp.height / 2));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HopPainter old) => true;
}
