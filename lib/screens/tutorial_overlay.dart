import 'package:flutter/material.dart';
import '../theme/ball_styles.dart';
import '../theme/huehop_themes.dart';
import '../theme/toy_ui.dart';

/// First-launch how-to-play overlay for Hue Hop.
///
/// Shows a short looping ANIMATED demo in the game's own art style
/// (a ball hopping through a matching-color gate, an orb swapping its
/// color, then passing the next gate), plus 3 one-line instructions and a
/// "Got it!" button. The round cannot start until this is dismissed.
class TutorialOverlay extends StatefulWidget {
  final HueHopThemeDef theme;
  final int ballStyle;
  final int gateStyle;
  final String buttonText;
  final VoidCallback onDone;

  const TutorialOverlay({
    super.key,
    required this.theme,
    required this.ballStyle,
    required this.gateStyle,
    required this.onDone,
    this.buttonText = '▶ Got it! Play',
  });

  /// Show the overlay as a dialog (used by Settings "How to play").
  static Future<void> showDialogReuse(BuildContext context,
      {required HueHopThemeDef theme,
      required int ballStyle,
      required int gateStyle}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: TutorialOverlay(
          theme: theme,
          ballStyle: ballStyle,
          gateStyle: gateStyle,
          buttonText: '👍 Got it!',
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    // Absorb every tap: the game behind must never start while this is up.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ToyUi.panel(
              theme: t,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('How to play', style: ToyUi.title(22, theme: t)),
                  const SizedBox(height: 10),
                  // Looping animated demo in the game's own art style.
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, _) => CustomPaint(
                      size: const Size(300, 190),
                      painter: _DemoPainter(
                        t: _ctrl.value,
                        theme: t,
                        ballStyle: widget.ballStyle,
                        gateStyle: widget.gateStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('👆 Tap to hop  ·  ↔️ Drag to steer',
                      textAlign: TextAlign.center,
                      style: ToyUi.body(14, theme: t)),
                  const SizedBox(height: 6),
                  Text("🌈 Fly through holes that MATCH your ball's color",
                      textAlign: TextAlign.center,
                      style: ToyUi.body(14, theme: t)),
                  const SizedBox(height: 6),
                  Text('✨ Grab orbs to swap colors — miss and you splat!',
                      textAlign: TextAlign.center,
                      style: ToyUi.body(14, theme: t)),
                  const SizedBox(height: 16),
                  ToyUi.button(
                    theme: t,
                    text: widget.buttonText,
                    onTap: widget.onDone,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One looping demo beat, drawn with the game's own [paintBall]/[paintGate]:
/// hop through a matching gate → orb swaps ball color → pass the next gate.
class _DemoPainter extends CustomPainter {
  final double t; // 0..1 loop progress
  final HueHopThemeDef theme;
  final int ballStyle;
  final int gateStyle;

  _DemoPainter({
    required this.t,
    required this.theme,
    required this.ballStyle,
    required this.gateStyle,
  });

  double _easeOut(double k) => 1 - (1 - k) * (1 - k);

  void _popup(Canvas canvas, String text, Offset at, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 2)
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(at.dx - tp.width / 2, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cA = theme.gates[0];
    final cB = theme.gates[1 % theme.gates.length];
    final gateAY = h * 0.66;
    final gateBY = h * 0.28;
    const holeR = 30.0;
    final bx = w * 0.5;
    final startY = h - 24;

    double ballY;
    Color ballC = cA;
    String? popup;
    Offset? popupAt;
    bool swapOrb = false;
    double swapK = 0;

    if (t < 0.30) {
      // A: hop up through gate A (matching color).
      final k = _easeOut((t / 0.30).clamp(0.0, 1.0));
      ballY = startY + (gateAY - 52 - startY) * k;
      if (t > 0.22) {
        popup = '✔ +1';
        popupAt = Offset(bx + 62, gateAY - 40);
      }
    } else if (t < 0.52) {
      // B: orb swaps the ball color.
      ballY = gateAY - 52;
      swapK = ((t - 0.30) / 0.22).clamp(0.0, 1.0);
      ballC = Color.lerp(cA, cB, swapK)!;
      swapOrb = true;
      popup = '✨ SWAP!';
      popupAt = Offset(bx + 66, ballY - 14);
    } else {
      // C: hop up through gate B (new color).
      final k = _easeOut(((t - 0.52) / 0.38).clamp(0.0, 1.0));
      ballY = (gateAY - 52) + (gateBY - 52 - (gateAY - 52)) * k;
      ballC = cB;
      if (t > 0.80) {
        popup = '✔ +1';
        popupAt = Offset(bx + 62, gateBY - 40);
      }
    }

    // Gates (dim the passed one, like the real game).
    paintGate(canvas, w, gateAY, bx, holeR, cA, gateStyle, 0, t >= 0.30);
    paintGate(canvas, w, gateBY, bx, holeR, cB, gateStyle, 0, t > 0.90);

    // Swap orb with halo.
    if (swapOrb) {
      final pulse = 1 + (1 - swapK) * 0.4;
      canvas.drawCircle(Offset(bx, ballY), 22 * pulse,
          Paint()..color = theme.orbHalo.withValues(alpha: 0.35));
      canvas.drawCircle(
          Offset(bx, ballY), 13 * pulse, Paint()..color = cB);
      canvas.drawCircle(
          Offset(bx - 4 * pulse, ballY - 5 * pulse),
          4 * pulse,
          Paint()..color = Colors.white.withValues(alpha: 0.7));
    }

    // Ball, drawn with the game's own style.
    paintBall(canvas, Offset(bx, ballY), 18, ballC, ballStyle);

    if (popup != null && popupAt != null) {
      _popup(canvas, popup, popupAt, Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _DemoPainter old) => old.t != t;
}
