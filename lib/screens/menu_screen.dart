import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/huehop_themes.dart';
import '../theme/toy_ui.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Hue Hop main menu: mode + difficulty select, play, customize, PRO.
class MenuScreen extends StatefulWidget {
  final HueHopAudio audio;
  final HueHopSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  HueHopAudio get _audio => widget.audio;
  HueHopSettings get _s => widget.settings;

  @override
  void initState() {
    super.initState();
    _audio.startMenuMusic();
  }

  void _play() {
    // The start fanfare plays on the first tap-to-hop inside the game
    // screen (_start), so every run — first and replays — gets exactly one.
    _audio.startGameMusic();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: _audio,
          settings: _s,
        ),
      ),
    ).then((_) => _audio.startMenuMusic());
  }

  Future<void> _share() async {
    _audio.click();
    try {
      await Share.share(
        'I just scored ${_s.bestFor(_s.mode, _s.difficulty)} gates in Hue Hop! Can you beat me?\n'
        'https://play.google.com/store/apps/details?id=com.gameswajiha.huehop',
        subject: 'Hue Hop — bounce through your colors!',
      );
    } catch (_) {}
  }

  Future<void> _rate() async {
    _audio.click();
    try {
      final review = InAppReview.instance;
      // Graceful when not installed from Play: requestReview is a safe no-op
      // on stores that don't support it; isAvailable() guards the rest.
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (_, _) {
        final t = _s.theme;
        return ToyUi.backdrop(
          theme: t,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Column(
                  children: [
                    // Header: logo + name + profile chip
                    Row(
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: t.accent, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                offset: const Offset(0, 5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset('assets/huehop_logo.png', fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hue Hop', style: ToyUi.display(34, theme: t)),
                              Text('BOUNCE THROUGH YOUR COLORS',
                                  style: ToyUi.label(11, theme: t)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _audio.click();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(
                                    audio: _audio, settings: _s, focusName: true),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: t.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: t.surfaceEdge, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person, color: t.accent, size: 18),
                                const SizedBox(width: 6),
                                Text(_s.playerName,
                                    style: ToyUi.title(14, theme: t)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Mode select
                    ToyUi.panel(
                      theme: t,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MODE', style: ToyUi.label(13, theme: t)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                  child: _modeCard(t, 'endless', '🏃 Endless',
                                      'One life.\nHow far can you bounce?')),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _modeCard(t, 'attack', '⏱️ Score Attack',
                                      '90 seconds.\n3 lives. Max gates!')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Difficulty tiers
                    ToyUi.panel(
                      theme: t,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('DIFFICULTY', style: ToyUi.label(13, theme: t)),
                              const Spacer(),
                              if (!_s.isPro)
                                GestureDetector(
                                  onTap: () {
                                    _audio.click();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProScreen(
                                            audio: _audio,
                                            settings: _s,
                                            store: StoreService()),
                                      ),
                                    );
                                  },
                                  child: Text('🔒 Wild is PRO',
                                      style: ToyUi.body(12,
                                          theme: t, color: t.accent)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _diffCard(t, 0, '🐣 Chill', 'Slow & roomy')),
                              const SizedBox(width: 10),
                              Expanded(child: _diffCard(t, 1, '⚡ Zippy', 'Drifting gates')),
                              const SizedBox(width: 10),
                              Expanded(child: _diffCard(t, 2, '🔥 Wild', '5 colors, fast')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Best score banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      decoration: BoxDecoration(
                        color: t.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: t.accent.withValues(alpha: 0.5), width: 2),
                      ),
                      child: Row(
                        children: [
                          Text('🏆', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Best: ${_s.bestFor(_s.mode, _s.difficulty)} gates  ·  ${_modeName()} ${_diffName()}',
                              style: ToyUi.title(15, theme: t),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // PLAY
                    ToyUi.button(
                      theme: t,
                      text: '▶  PLAY',
                      fontSize: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 18),
                      onTap: _play,
                    ),
                    const SizedBox(height: 16),

                    // Row of utility buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ToyUi.iconButton(
                            theme: t,
                            icon: Icons.palette,
                            tooltip: 'Customize',
                            onTap: () {
                              _audio.click();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SettingsScreen(
                                      audio: _audio, settings: _s),
                                ),
                              );
                            }),
                        const SizedBox(width: 14),
                        ToyUi.iconButton(
                            theme: t,
                            icon: _s.isPro ? Icons.workspace_premium : Icons.lock_open,
                            tooltip: 'Hue Hop PRO',
                            onTap: () {
                              _audio.click();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProScreen(
                                      audio: _audio,
                                      settings: _s,
                                      store: StoreService()),
                                ),
                              );
                            }),
                        const SizedBox(width: 14),
                        ToyUi.iconButton(
                            theme: t,
                            icon: Icons.share,
                            tooltip: 'Share',
                            onTap: _share),
                        const SizedBox(width: 14),
                        ToyUi.iconButton(
                            theme: t,
                            icon: Icons.star,
                            tooltip: 'Rate',
                            onTap: _rate),
                        const SizedBox(width: 14),
                        ToyUi.iconButton(
                            theme: t,
                            icon: _s.musicOn ? Icons.music_note : Icons.music_off,
                            tooltip: 'Music on/off',
                            onTap: () {
                              final v = !_s.musicOn;
                              _s.setMusic(v);
                              _audio.configure(
                                  musicOn: v,
                                  sfxOn: _s.sfxOn,
                                  volume: _s.volume);
                              if (v) {
                                _audio.startMenuMusic();
                              } else {
                                _audio.stopMusic();
                              }
                              _audio.click();
                            }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Made with 💛 by WAJIHA',
                        style: ToyUi.body(12, theme: t)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _modeName() => _s.mode == 'attack' ? 'Score Attack' : 'Endless';
  String _diffName() => ['Chill', 'Zippy', 'Wild'][_s.difficulty];

  Widget _modeCard(HueHopThemeDef t, String id, String title, String desc) {
    final sel = _s.mode == id;
    return GestureDetector(
      onTap: () {
        _audio.click();
        _s.setMode(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: sel ? t.accent : t.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: sel ? t.accentDark : t.surfaceEdge, width: 2),
          boxShadow: sel
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 0)
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(title,
                style: ToyUi.title(15,
                    theme: t,
                    color: sel ? Colors.white : t.text)),
            const SizedBox(height: 6),
            Text(desc,
                textAlign: TextAlign.center,
                style: ToyUi.body(12,
                    theme: t,
                    color: sel ? Colors.white.withValues(alpha: 0.9) : t.subtext)),
          ],
        ),
      ),
    );
  }

  Widget _diffCard(HueHopThemeDef t, int idx, String title, String desc) {
    final sel = _s.difficulty == idx;
    final locked = idx == 2 && !_s.isPro;
    return GestureDetector(
      onTap: () {
        if (locked) {
          _audio.invalid();
          toySnack(context, 'Wild difficulty is a PRO perk 🔥', t);
          return;
        }
        _audio.click();
        _s.setDifficulty(idx);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? t.accent : t.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: sel ? t.accentDark : t.surfaceEdge, width: 2),
          boxShadow: sel
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 0)
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: ToyUi.title(14,
                    theme: t, color: sel ? Colors.white : t.text)),
            const SizedBox(height: 4),
            Text(desc,
                textAlign: TextAlign.center,
                style: ToyUi.body(11,
                    theme: t,
                    color: sel
                        ? Colors.white.withValues(alpha: 0.9)
                        : t.subtext)),
            if (locked)
              const Text('🔒', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
