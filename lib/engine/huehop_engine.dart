import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/huehop_themes.dart';

/// Phases owned ENTIRELY by the engine. The UI only renders.
/// Every non-terminal phase has a live engine-owned timer: a phase can never
/// get stuck by construction, and the watchdog recovers a dead sim timer.
enum HopPhase { idle, playing, paused, oof, splatting, over }

/// Events the engine emits for juicy UI/audio feedback. No silent scoring.
enum HopEventType {
  hop, // tap → hop impulse
  gatePass, // +1, matched color
  perfect, // gate pass + orb combo streak
  comboBonus, // every 5th perfect: bonus points
  orb, // color swap pickup
  oof, // attack mode: life lost, respawning
  splat, // run ended
  gameOver, // terminal, score final
  tickSecond, // score-attack countdown tick
  newBest, // final score beats saved best (UI supplies the comparison)
}

class HopEvent {
  final HopEventType type;
  final int value; // score / lives / seconds, depending on type
  final String label; // human-readable popup text
  const HopEvent(this.type, {this.value = 0, this.label = ''});
}

class HopGate {
  final double y;
  final double baseHoleX;
  final double driftAmp;
  final double driftSpeed;
  final double driftPhase;
  final int color;
  bool passed = false;
  HopGate({
    required this.y,
    required this.baseHoleX,
    this.driftAmp = 0,
    this.driftSpeed = 0,
    this.driftPhase = 0,
    required this.color,
  });
  double holeX(double t) => baseHoleX + driftAmp * sin(driftSpeed * t + driftPhase);
}

class HopOrb {
  final double x, y;
  final int color;
  bool taken = false;
  HopOrb(this.x, this.y, this.color);
}

class HopParticle {
  double x, y, vx, vy, life, maxLife;
  final Color color;
  final double size;
  HopParticle(this.x, this.y, this.vx, this.vy, this.life, this.color, this.size)
      : maxLife = life;
}

class HopPopup {
  final double x;
  double y;
  final String text;
  final Color color;
  double life = 1.0;
  HopPopup(this.x, this.y, this.text, this.color);
}

/// Hue Hop engine: tap-to-hop color-matching arcade.
///
/// - Ball falls under gravity; tap = hop impulse; drag = steer horizontally.
/// - Gates are full-width bars with a hole; pass ONLY when ball color matches
///   the gate color AND the ball is inside the hole when crossing the plane.
/// - Swapper orbs change the ball's color.
/// - Endless: one life, speed ramps with score. Score attack: 90 seconds,
///   3 lives.
/// - Difficulty tiers: Chill (0) / Zippy (1) / Wild (2, Pro).
class HueHopEngine extends ChangeNotifier {
  // --- configuration ------------------------------------------------------
  int difficulty = 0; // 0 chill, 1 zippy, 2 wild
  String mode = 'endless'; // 'endless' | 'attack'
  HueHopThemeDef theme = HueHopThemes.all.first;
  int ballStyle = 0;
  int gateStyle = 0;
  int colorCount = 4;
  double gravity = 2000;
  double hopV = -980;
  double holeRadius = 62;
  double gateSpacing = 300;
  double driftMax = 0;
  double speedRamp = 0.0; // extra speed per gate cleared (endless)

  // --- live state ----------------------------------------------------------
  HopPhase phase = HopPhase.idle;
  double ballX = 0, ballY = 0, ballVy = 0;
  double camY = 0;
  double simTime = 0;
  int score = 0;
  int combo = 0; // consecutive perfect gates
  int lives = 1;
  double timeLeft = 0; // attack mode
  double width = 400, height = 700;
  int seed = 0;

  final List<HopGate> gates = [];
  final List<HopOrb> orbs = [];
  final List<HopParticle> particles = [];
  final List<HopPopup> popups = [];
  final List<Offset> trail = [];

  void Function(HopEvent)? onEvent;

  late Random _rng;
  int _gateCount = 0;
  int _lastWholeSecond = -1;

  Timer? _sim; // 60fps simulation, engine-owned
  Timer? _watchdog; // stuck-state recovery
  Timer? _phaseTimer; // oof / splat one-shots, engine-owned
  DateTime _lastStep = DateTime.now();
  bool _disposed = false;

  HueHopEngine() {
    _rng = Random();
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _recover());
  }

  // --- configuration ------------------------------------------------------
  void configure({
    required int difficulty,
    required String mode,
    required HueHopThemeDef theme,
    required int ballStyle,
    required int gateStyle,
    required Size view,
  }) {
    this.difficulty = difficulty.clamp(0, 2);
    this.mode = mode == 'attack' ? 'attack' : 'endless';
    this.theme = theme;
    this.ballStyle = ballStyle;
    this.gateStyle = gateStyle;
    width = view.width;
    height = view.height;
    switch (this.difficulty) {
      case 0: // Chill
        colorCount = 4;
        gravity = 2000;
        hopV = -980;
        holeRadius = 64;
        gateSpacing = 310;
        driftMax = 0;
        speedRamp = 0.004;
        break;
      case 1: // Zippy
        colorCount = 4;
        gravity = 2350;
        hopV = -1010;
        holeRadius = 56;
        gateSpacing = 290;
        driftMax = 46;
        speedRamp = 0.007;
        break;
      case 2: // Wild
        colorCount = 5;
        gravity = 2650;
        hopV = -1040;
        holeRadius = 50;
        gateSpacing = 275;
        driftMax = 90;
        speedRamp = 0.010;
        break;
    }
  }

  // --- run control ---------------------------------------------------------
  void startRun({int? seed}) {
    _cancelSim();
    _phaseTimer?.cancel();
    this.seed = seed ?? DateTime.now().millisecondsSinceEpoch;
    _rng = Random(this.seed);
    ballX = width / 2;
    ballY = 0;
    ballVy = 0;
    camY = 0;
    simTime = 0;
    score = 0;
    combo = 0;
    lives = mode == 'attack' ? 3 : 1;
    timeLeft = mode == 'attack' ? 90.0 : 0.0;
    _lastWholeSecond = -1;
    gates.clear();
    orbs.clear();
    particles.clear();
    popups.clear();
    trail.clear();
    _gateCount = 0;
    for (int i = 0; i < 8; i++) {
      _spawnGate();
    }
    _ballColor = _rng.nextInt(colorCount);
    phase = HopPhase.playing;
    _lastStep = DateTime.now();
    _sim = Timer.periodic(const Duration(milliseconds: 16), (_) => _step(1 / 60));
    notifyListeners();
  }

  int _ballColor = 0;
  int get ballColor => _ballColor;

  Color get ballPaintColor => theme.gates[_ballColor % theme.gates.length];

  /// Tap anywhere: hop impulse. Returns false if the tap did nothing
  /// (paused/over), so the UI can give invalid feedback.
  bool tap() {
    if (phase != HopPhase.playing) return false;
    ballVy = hopV * (1 + score * speedRamp * 0.15);
    _burst(ballX, ballY + 14, ballPaintColor, 6, 120);
    onEvent?.call(const HopEvent(HopEventType.hop));
    return true;
  }

  /// Drag steering: the ball chases the finger horizontally.
  void dragTo(double x) {
    if (phase != HopPhase.playing) return;
    ballX = x.clamp(24.0, width - 24.0);
  }

  void pause() {
    if (phase != HopPhase.playing) return;
    phase = HopPhase.paused;
    _cancelSim();
    notifyListeners();
  }

  void resume() {
    if (phase != HopPhase.paused) return;
    phase = HopPhase.playing;
    _lastStep = DateTime.now();
    _sim = Timer.periodic(const Duration(milliseconds: 16), (_) => _step(1 / 60));
    notifyListeners();
  }

  void quitToIdle() {
    _cancelSim();
    _phaseTimer?.cancel();
    phase = HopPhase.idle;
    notifyListeners();
  }

  // --- simulation ----------------------------------------------------------
  void _cancelSim() {
    _sim?.cancel();
    _sim = null;
  }

  void _spawnGate() {
    _gateCount++;
    final y = -_gateCount * gateSpacing;
    final margin = 90.0;
    final holeX = margin + _rng.nextDouble() * (width - margin * 2);
    final color = _rng.nextInt(colorCount);
    final drift = driftMax > 0 ? driftMax * (0.5 + _rng.nextDouble() * 0.5) : 0.0;
    gates.add(HopGate(
      y: y,
      baseHoleX: holeX,
      driftAmp: drift,
      driftSpeed: drift > 0 ? 0.9 + _rng.nextDouble() * 0.9 : 0,
      driftPhase: _rng.nextDouble() * 2 * pi,
      color: color,
    ));
    // Swapper orb in the gap before this gate — never the ball's current
    // color, so picking it up always matters.
    if (_gateCount > 1 && _gateCount % 2 == 0) {
      int c = _rng.nextInt(colorCount);
      if (c == _ballColor) c = (c + 1) % colorCount;
      final ox = (holeX + (_rng.nextBool() ? 110 : -110)).clamp(50.0, width - 50.0);
      orbs.add(HopOrb(ox, y + gateSpacing / 2, c));
    }
  }

  void _step(double dt) {
    if (_disposed || phase != HopPhase.playing) return;
    _lastStep = DateTime.now();
    simTime += dt;

    // score-attack countdown
    if (mode == 'attack') {
      timeLeft -= dt;
      final whole = timeLeft.ceil();
      if (whole != _lastWholeSecond && whole >= 0 && whole <= 10) {
        _lastWholeSecond = whole;
        onEvent?.call(HopEvent(HopEventType.tickSecond, value: whole));
      }
      if (timeLeft <= 0) {
        _finishRun(timedOut: true);
        return;
      }
    }

    final prevY = ballY;
    final speedMul = 1 + score * speedRamp * 0.4;

    // physics
    ballVy += gravity * speedMul * dt;
    ballY += ballVy * dt;

    // camera follows upward only
    final target = ballY - height * 0.55;
    if (target < camY) camY = target;

    // trail
    trail.add(Offset(ballX, ballY));
    if (trail.length > 14) trail.removeAt(0);

    // spawn ahead / cull behind
    while (gates.isEmpty || gates.last.y > camY - height * 1.5) {
      _spawnGate();
    }
    gates.removeWhere((g) => g.y > camY + height + 100);
    orbs.removeWhere((o) => o.y > camY + height + 100 || o.taken);

    // orb pickup
    for (final o in orbs) {
      if (!o.taken && (ballX - o.x).abs() < 44 && (ballY - o.y).abs() < 44) {
        o.taken = true;
        _ballColor = o.color;
        _burst(o.x, o.y, theme.gates[o.color % theme.gates.length], 10, 200);
        popups.add(HopPopup(o.x, o.y - 30, 'SWAP!', theme.orbHalo));
        onEvent?.call(const HopEvent(HopEventType.orb, label: 'Color swap!'));
      }
    }

    // gate crossing (moving upward through the gate plane)
    for (final g in gates) {
      if (!g.passed && prevY > g.y && ballY <= g.y) {
        g.passed = true;
        final hx = g.holeX(simTime);
        final inHole = (ballX - hx).abs() < holeRadius;
        if (inHole && g.color == _ballColor) {
          score++;
          combo++;
          final perfect = combo >= 2;
          _burst(hx, g.y, theme.gates[g.color % theme.gates.length], 12, 260);
          popups.add(HopPopup(hx, g.y - 44, perfect ? 'PERFECT +1' : '+1',
              theme.gates[g.color % theme.gates.length]));
          if (combo % 5 == 0) {
            score += 2;
            popups.add(HopPopup(ballX, ballY - 70, 'COMBO x$combo! +2', theme.orbHalo));
            onEvent?.call(HopEvent(HopEventType.comboBonus, value: combo, label: 'Combo x$combo!'));
          } else {
            onEvent?.call(HopEvent(perfect ? HopEventType.perfect : HopEventType.gatePass,
                value: score, label: perfect ? 'Perfect!' : '+1 gate'));
          }
        } else {
          _failGate(inHole ? 'Wrong color!' : 'Missed the hole!');
          return;
        }
      }
    }

    // fell below view
    if (ballY - camY > height + 80) {
      _failGate('You fell!');
      return;
    }

    // particles & popups
    for (final p in particles) {
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 900 * dt;
    }
    particles.removeWhere((p) => p.life <= 0);
    for (final p in popups) {
      p.life -= dt * 1.4;
      p.y -= dt * 46;
    }
    popups.removeWhere((p) => p.life <= 0);

    notifyListeners();
  }

  void _failGate(String why) {
    if (phase != HopPhase.playing) return;
    if (mode == 'attack' && lives > 1) {
      // Lose a life, brief OOF beat, then keep flying. Engine-owned timer —
      // the phase always advances by construction.
      lives--;
      combo = 0;
      _splatBurst(silent: true);
      phase = HopPhase.oof;
      _cancelSim();
      onEvent?.call(HopEvent(HopEventType.oof, value: lives, label: '$why  $lives left'));
      _phaseTimer?.cancel();
      _phaseTimer = Timer(const Duration(milliseconds: 900), () {
        if (_disposed || phase != HopPhase.oof) return;
        // Respawn just below the camera's top third with a fresh color.
        ballY = camY + height * 0.25;
        ballX = width / 2;
        ballVy = -600;
        _ballColor = _rng.nextInt(colorCount);
        phase = HopPhase.playing;
        _lastStep = DateTime.now();
        _sim = Timer.periodic(const Duration(milliseconds: 16), (_) => _step(1 / 60));
        notifyListeners();
      });
      notifyListeners();
      return;
    }
    // Terminal splat.
    _splatBurst(silent: false);
    phase = HopPhase.splatting;
    _cancelSim();
    onEvent?.call(HopEvent(HopEventType.splat, value: score, label: why));
    _phaseTimer?.cancel();
    _phaseTimer = Timer(const Duration(milliseconds: 1200), () {
      if (_disposed || phase != HopPhase.splatting) return;
      _finishRun(timedOut: false);
    });
    notifyListeners();
  }

  void _finishRun({required bool timedOut}) {
    _cancelSim();
    _phaseTimer?.cancel();
    phase = HopPhase.over;
    onEvent?.call(HopEvent(
      HopEventType.gameOver,
      value: score,
      label: timedOut ? "Time's up!" : 'Splat!',
    ));
    notifyListeners();
  }

  void _burst(double x, double y, Color color, int n, double power) {
    for (int i = 0; i < n; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      particles.add(HopParticle(
        x,
        y,
        cos(a) * power * (0.4 + _rng.nextDouble() * 0.6),
        sin(a) * power * (0.4 + _rng.nextDouble() * 0.6) - 120,
        0.5 + _rng.nextDouble() * 0.4,
        color,
        4 + _rng.nextDouble() * 6,
      ));
    }
  }

  void _splatBurst({required bool silent}) {
    for (int i = 0; i < 26; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      particles.add(HopParticle(
        ballX,
        ballY,
        cos(a) * 320 * _rng.nextDouble(),
        -_rng.nextDouble() * 420,
        0.7 + _rng.nextDouble() * 0.5,
        ballPaintColor,
        5 + _rng.nextDouble() * 8,
      ));
    }
    if (!silent) {
      // keep particles animating during the splat beat
      _sim = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (_disposed) return;
        for (final p in particles) {
          p.life -= 1 / 60;
          p.x += p.vx / 60;
          p.y += p.vy / 60;
          p.vy += 900 / 60;
        }
        particles.removeWhere((p) => p.life <= 0);
        notifyListeners();
      });
    }
  }

  // --- watchdog ------------------------------------------------------------
  /// If the sim timer ever dies without progress (or an oof/splat phase loses
  /// its one-shot), recover automatically. Stuck states impossible.
  void _recover() {
    if (_disposed) return;
    final stale = DateTime.now().difference(_lastStep).inSeconds > 3;
    if (phase == HopPhase.playing && (stale || _sim == null)) {
      _cancelSim();
      _lastStep = DateTime.now();
      _sim = Timer.periodic(const Duration(milliseconds: 16), (_) => _step(1 / 60));
      notifyListeners();
    } else if ((phase == HopPhase.oof || phase == HopPhase.splatting) &&
        _phaseTimer != null &&
        !_phaseTimer!.isActive) {
      // One-shot died without firing: finish the phase transition now.
      _phaseTimer!.cancel();
      if (phase == HopPhase.oof) {
        ballY = camY + height * 0.25;
        ballX = width / 2;
        ballVy = -600;
        phase = HopPhase.playing;
        _lastStep = DateTime.now();
        _sim = Timer.periodic(const Duration(milliseconds: 16), (_) => _step(1 / 60));
      } else {
        _finishRun(timedOut: false);
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelSim();
    _watchdog?.cancel();
    _phaseTimer?.cancel();
    super.dispose();
  }
}
