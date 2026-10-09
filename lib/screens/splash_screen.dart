import 'dart:async';

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/huehop_themes.dart';
import '../theme/toy_ui.dart';
import 'menu_screen.dart';

/// Launch splash: WAJIHA company moment -> game splash with logo, name,
/// animated loading line, and the official company logo + credits.
class SplashScreen extends StatefulWidget {
  final HueHopAudio audio;
  final HueHopSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _showCompany = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    unawaited(widget.audio.prewarm());
    unawaited(widget.audio.startMenuMusic());
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _showCompany = false);
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.theme;
    return Scaffold(
      backgroundColor: const Color(0xFF14100C),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _showCompany
            ? const _CompanySplash(key: ValueKey('company'))
            : _GameSplash(
                key: const ValueKey('game'),
                theme: theme,
                loader: _loader,
              ),
      ),
    );
  }
}

/// WAJIHA company moment: official logo, untouched.
class _CompanySplash extends StatelessWidget {
  const _CompanySplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/wajiha_logo.png', width: 110, height: 110),
          const SizedBox(height: 18),
          const Text(
            'W A J I H A',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final HueHopThemeDef theme;
  final AnimationController loader;
  const _GameSplash({super.key, required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return ToyUi.backdrop(
      theme: t,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: t.accent, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/huehop_logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('Hue Hop', style: ToyUi.display(52, theme: t)),
            const SizedBox(height: 6),
            Text(
              'BOUNCE THROUGH YOUR COLORS',
              style: ToyUi.label(13, theme: t),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.black.withValues(alpha: 0.12),
                        border: Border.all(
                            color: t.accent.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: t.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1 ? 'Inflating balls…' : 'Ready!',
                      style: ToyUi.body(13, theme: t),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: ToyUi.label(14, theme: t),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
