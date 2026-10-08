import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const HueHopApp());

class HueHopApp extends StatelessWidget {
  const HueHopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Hue Hop',
      tagline: 'Bounce through color gates that match your ball',
      emoji: '🌈',
      slug: 'huehop',
      howToPlay:
          '• Your ball auto-bounces — tap to hop higher.\n• Slip through each gate\'s hole ONLY when your color matches the gate.\n• Grab swapper orbs to change color.\n• Wrong color or a fall = SPLAT. How many gates can you clear?',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => HueHopScreen(players: players, callbacks: cb),
    );
  }
}
