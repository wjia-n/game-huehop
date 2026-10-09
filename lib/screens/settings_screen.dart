import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/ball_styles.dart';
import '../theme/huehop_themes.dart';
import '../theme/toy_ui.dart';
import 'pro_screen.dart';
import '../services/iap_service.dart';

/// Settings: renameable profile, audio, 14 themes, 10 ball styles,
/// 8 gate styles, Pro custom creator.
class SettingsScreen extends StatefulWidget {
  final HueHopAudio audio;
  final HueHopSettings settings;
  final bool focusName;
  const SettingsScreen(
      {super.key,
      required this.audio,
      required this.settings,
      this.focusName = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  HueHopAudio get _audio => widget.audio;
  HueHopSettings get _s => widget.settings;
  late final TextEditingController _nameCtrl;
  late final FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _s.playerName);
    _nameFocus = FocusNode();
    // Commit on focus loss: re-trim + persist even if the text did not
    // change since the last keystroke save.
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && mounted) {
        _s.commitPlayerName(_nameCtrl.text);
      }
    });
    if (widget.focusName) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _nameFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
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
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: t.text),
                onPressed: () {
                  _audio.click();
                  Navigator.of(context).pop();
                },
              ),
              title: Text('Customize', style: ToyUi.title(22, theme: t)),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Player name
                    ToyUi.panel(
                      theme: t,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PLAYER NAME', style: ToyUi.label(13, theme: t)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameCtrl,
                                  focusNode: _nameFocus,
                                  maxLength: 16,
                                  style: ToyUi.title(17, theme: t),
                                  // Save on EVERY keystroke (not just
                                  // keyboard-done): the name is persisted as
                                  // one order-preserving JSON string.
                                  onChanged: (v) => _s.setPlayerName(v),
                                  decoration: InputDecoration(                                    counterText: '',
                                    filled: true,
                                    fillColor: t.bg,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                          color: t.surfaceEdge, width: 2),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                  ),
                                  onSubmitted: (v) {
                                    _audio.click();
                                    _s.setPlayerName(v);
                                    _nameFocus.unfocus();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              ToyUi.button(
                                theme: t,
                                text: 'Save',
                                fontSize: 15,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 12),
                                onTap: () {
                                  _audio.click();
                                  _s.setPlayerName(_nameCtrl.text);
                                  _nameFocus.unfocus();
                                  toySnack(context, 'Name saved! 🎉', t);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Audio
                    ToyUi.panel(
                      theme: t,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SOUND', style: ToyUi.label(13, theme: t)),
                          _switchRow(t, 'Music', Icons.music_note, _s.musicOn,
                              (v) {
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
                          }),
                          _switchRow(t, 'Sound effects', Icons.volume_up,
                              _s.sfxOn, (v) {
                            _s.setSfx(v);
                            _audio.configure(
                                musicOn: _s.musicOn,
                                sfxOn: v,
                                volume: _s.volume);
                            if (v) _audio.click();
                          }),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.graphic_eq,
                                  color: t.subtext, size: 20),
                              Expanded(
                                child: Slider(
                                  value: _s.volume,
                                  onChanged: (v) {
                                    _s.setVolume(v);
                                    _audio.configure(
                                        musicOn: _s.musicOn,
                                        sfxOn: _s.sfxOn,
                                        volume: v);
                                  },
                                  onChangeEnd: (_) => _audio.click(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Themes
                    Text('THEMES (${HueHopThemes.all.length})',
                        style: ToyUi.label(13, theme: t)),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: HueHopThemes.all.length + 1,
                      itemBuilder: (_, i) {
                        if (i == HueHopThemes.all.length) {
                          return _customThemeCard(t);
                        }
                        final th = HueHopThemes.all[i];
                        final locked = th.isPro && !_s.isPro;
                        final sel = _s.themeId == th.id;
                        return GestureDetector(
                          onTap: () {
                            if (locked) {
                              _audio.invalid();
                              _goPro('That theme is a PRO treat 🎨');
                              return;
                            }
                            _audio.click();
                            _s.setTheme(th.id);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: sel ? t.accent : t.surfaceEdge,
                                  width: sel ? 3 : 2),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.18),
                                          offset: const Offset(0, 4),
                                          blurRadius: 0)
                                    ]
                                  : null,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(color: th.bg),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    color: Colors.black
                                        .withValues(alpha: 0.45),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5),
                                    child: Text(
                                      th.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      for (int g = 0;
                                          g < 4;
                                          g++)
                                        Container(
                                          width: 20,
                                          height: 20,
                                          margin:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 3),
                                          decoration: BoxDecoration(
                                            color: th.gates[g],
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 2),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (locked)
                                  Container(
                                    color: Colors.black
                                        .withValues(alpha: 0.45),
                                    child: const Center(
                                        child: Text('🔒',
                                            style: TextStyle(fontSize: 26))),
                                  ),
                                if (sel)
                                  const Positioned(
                                    top: 6,
                                    right: 8,
                                    child: Text('✅',
                                        style: TextStyle(fontSize: 18)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Ball styles
                    Text('BALL STYLES (${BallStyles.all.length})',
                        style: ToyUi.label(13, theme: t)),
                    const SizedBox(height: 8),
                    _styleStrip<BallStyleDef>(
                      t,
                      items: BallStyles.all,
                      selected: _s.ballStyle,
                      isProItem: (d) => d.isPro,
                      nameOf: (d) => d.name,
                      onPick: (i) => _s.setBallStyle(i),
                      swatch: (d) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: t.gates[0],
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.black.withValues(alpha: 0.2),
                              width: 2),
                        ),
                        child: Center(
                            child: Text(_ballGlyph(d.index),
                                style: const TextStyle(fontSize: 20))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Gate styles
                    Text('GATE STYLES (${GateStyles.all.length})',
                        style: ToyUi.label(13, theme: t)),
                    const SizedBox(height: 8),
                    _styleStrip<GateStyleDef>(
                      t,
                      items: GateStyles.all,
                      selected: _s.gateStyle,
                      isProItem: (d) => d.isPro,
                      nameOf: (d) => d.name,
                      onPick: (i) => _s.setGateStyle(i),
                      swatch: (d) => Container(
                        width: 56,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: t.gates[1], width: 7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Custom creator (Pro)
                    ToyUi.panel(
                      theme: t,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('CUSTOM CREATOR',
                                  style: ToyUi.label(13, theme: t)),
                              const Spacer(),
                              if (!_s.isPro) const Text('🔒 PRO',
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _s.isPro
                                ? 'Design your own ball + playground colors.'
                                : 'PRO unlocks your own color lab.',
                            style: ToyUi.body(13, theme: t),
                          ),
                          const SizedBox(height: 8),
                          for (final k in [
                            'ball',
                            'background',
                            'accent'
                          ])
                            _colorRow(t, k),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ToyUi.button(
                                  theme: t,
                                  text: 'Use My Creation',
                                  fontSize: 15,
                                  onTap: () {
                                    if (!_s.isPro) {
                                      _goPro(
                                          'The custom creator is a PRO treat 🎨');
                                      return;
                                    }
                                    _audio.click();
                                    _s.setTheme('custom');
                                    toySnack(context,
                                        'Your creation is live! ✨', t);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              ToyUi.iconButton(
                                theme: t,
                                icon: Icons.refresh,
                                tooltip: 'Reset colors',
                                onTap: () {
                                  _audio.click();
                                  _s.resetCustomColors();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _goPro(String msg) {
    toySnack(context, msg, _s.theme);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
            audio: _audio, settings: _s, store: StoreService()),
      ),
    );
  }

  Widget _customThemeCard(HueHopThemeDef t) {
    final sel = _s.themeId == 'custom';
    final locked = !_s.isPro;
    return GestureDetector(
      onTap: () {
        if (locked) {
          _audio.invalid();
          _goPro('The custom creator is a PRO treat 🎨');
          return;
        }
        _audio.click();
        _s.setTheme('custom');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: sel ? t.accent : t.surfaceEdge, width: sel ? 3 : 2),
          color: t.surface,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎨', style: TextStyle(fontSize: 30)),
                  const SizedBox(height: 4),
                  Text('My Creation',
                      style: ToyUi.title(14, theme: t)),
                ],
              ),
            ),
            if (locked)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black.withValues(alpha: 0.45),
                ),
                child: const Center(
                    child: Text('🔒', style: TextStyle(fontSize: 26))),
              ),
            if (sel)
              const Positioned(
                top: 6,
                right: 8,
                child: Text('✅', style: TextStyle(fontSize: 18)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(HueHopThemeDef t, String label, IconData icon, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Icon(icon, color: t.subtext, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: ToyUi.title(15, theme: t))),
        Switch(
          value: value,
          activeColor: t.accent,
          onChanged: (v) {
            _audio.click();
            onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _colorRow(HueHopThemeDef t, String key) {
    const names = {'ball': 'Ball', 'background': 'Background', 'accent': 'Accent'};
    const palette = [
      0xFFE8604C,
      0xFF3E9BDC,
      0xFFF2B134,
      0xFF7C5CC4,
      0xFF4CAF6D,
      0xFFE75480,
      0xFF1899B6,
      0xFF8B5E34,
      0xFF232347,
      0xFFF7EDDC,
    ];
    final cur = _s.customColors[key] ?? 0xFFE8604C;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 96,
              child: Text(names[key] ?? key,
                  style: ToyUi.title(14, theme: t))),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in palette)
                  GestureDetector(
                    onTap: () {
                      if (!_s.isPro) {
                        _goPro('The custom creator is a PRO treat 🎨');
                        return;
                      }
                      _audio.click();
                      _s.setCustomColor(key, c);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cur == c ? t.accent : Colors.black.withValues(alpha: 0.15),
                          width: cur == c ? 3 : 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _styleStrip<T>(
    HueHopThemeDef t, {
    required List<T> items,
    required int selected,
    required bool Function(T) isProItem,
    required String Function(T) nameOf,
    required ValueChanged<int> onPick,
    required Widget Function(T) swatch,
  }) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          final locked = isProItem(item) && !_s.isPro;
          final sel = selected == i;
          return GestureDetector(
            onTap: () {
              if (locked) {
                _audio.invalid();
                _goPro('That style is a PRO treat ✨');
                return;
              }
              _audio.click();
              onPick(i);
            },
            child: Container(
              width: 96,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: sel ? t.accent : t.surfaceEdge,
                    width: sel ? 3 : 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 46, child: Center(child: swatch(item))),
                  const SizedBox(height: 4),
                  Text(nameOf(item),
                      textAlign: TextAlign.center,
                      style: ToyUi.body(11, theme: t)),
                  if (locked) const Text('🔒', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _ballGlyph(int i) {
    const glyphs = ['🙂', '⚽', '🏀', '🏖️', '🎾', '🐞', '🎱', '🍉', '🍩', '⭐'];
    return glyphs[i % glyphs.length];
  }
}
