import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/huehop_themes.dart';
import '../theme/ball_styles.dart';

/// Persisted settings + profile + stats for Hue Hop. Survives app restarts.
///
/// Player names are stored as ONE order-preserving JSON list
/// (`huehop_player_names_json`) via setString — NEVER setStringList: on
/// Android a StringList is backed by an unordered StringSet (HashSet), so
/// names come back SCRAMBLED across slots after every app restart. The JSON
/// list keeps every slot exactly where it belongs.
/// Legacy keys `huehop_player_name` (plain string) and `huehop_profile_json`
/// (interim object key) are migrated once, then removed.
class HueHopSettings extends ChangeNotifier {
  // --- keys ---------------------------------------------------------------
  static const _kMusic = 'huehop_music_on';
  static const _kSfx = 'huehop_sfx_on';
  static const _kVolume = 'huehop_volume';
  static const _kNamesJson = 'huehop_player_names_json';
  static const _kLegacyName = 'huehop_player_name'; // legacy plain key
  static const _kLegacyProfileJson = 'huehop_profile_json'; // interim key
  static const _kTheme = 'huehop_theme_id';
  static const _kBallStyle = 'huehop_ball_style';
  static const _kGateStyle = 'huehop_gate_style';
  static const _kDifficulty = 'huehop_difficulty'; // 0 chill, 1 zippy, 2 wild
  static const _kMode = 'huehop_mode'; // 'endless' | 'attack'
  static const _kIsPro = 'huehop_is_pro';
  static const _kGames = 'huehop_games_played';
  static const _kBestPrefix = 'huehop_best_'; // + '<mode>_<difficulty>'
  static const _kCustomPrefix = 'huehop_custom_';

  static const defaultName = 'Hopper';

  // --- state --------------------------------------------------------------
  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;

  /// Ordered, order-safe player-name list (slot 0 = the current player).
  final List<String> _playerNames = [defaultName];
  List<String> get playerNames => List.unmodifiable(_playerNames);
  String get playerName =>
      _playerNames.isNotEmpty ? _playerNames[0] : defaultName;
  set playerName(String v) {
    final clean = v.trim();
    final name = clean.isEmpty ? defaultName : clean;
    if (_playerNames.isEmpty) {
      _playerNames.add(name);
    } else {
      _playerNames[0] = name;
    }
  }
  String themeId = 'toybox';
  int ballStyle = 0;
  int gateStyle = 0;
  int difficulty = 0;
  String mode = 'endless';
  bool isPro = false;
  int gamesPlayed = 0;
  final Map<String, int> bestScores = {}; // '<mode>_<difficulty>' -> score

  /// Custom-creator colors (ARGB). Pro feature.
  Map<String, int> customColors = Map.of(_defaultCustomColors);
  static const Map<String, int> _defaultCustomColors = {
    'ball': 0xFFE8604C,
    'background': 0xFFF7EDDC,
    'accent': 0xFF3E9BDC,
  };

  HueHopThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    final ball = c('ball');
    final bg = c('background');
    final acc = c('accent');
    return HueHopThemeDef(
      id: 'custom',
      name: 'My Creation',
      bg: bg,
      bgTop: bg,
      surface: const Color(0xFFFFFBF2),
      surfaceEdge: const Color(0xFFE4D3B4),
      text: const Color(0xFF4A3320),
      subtext: const Color(0xFF8A6F52),
      accent: acc,
      accentDark: acc,
      floor: acc,
      gates: [ball, acc, const Color(0xFFF2B134), const Color(0xFF7C5CC4), const Color(0xFF4CAF6D)],
      orbHalo: const Color(0xFFF2B134),
      trail: ball,
    );
  }

  SharedPreferences? _prefs;

  HueHopThemeDef get theme => HueHopThemes.byId(themeId, custom: customTheme);

  String bestKey(String mode, int difficulty) => '${mode}_$difficulty';
  int bestFor(String mode, int difficulty) => bestScores[bestKey(mode, difficulty)] ?? 0;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;

    // Player names: prefer the order-safe JSON list key; migrate legacy
    // keys once and remove them. NEVER setStringList (Android HashSet
    // scrambling — see class docs).
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      try {
        final d = jsonDecode(namesRaw);
        if (d is List) {
          final list = d
              .whereType<String>()
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (list.isNotEmpty) {
            _playerNames
              ..clear()
              ..addAll(list);
          }
        }
      } catch (_) {
        // keep the default
      }
      // Even on the JSON path, drop any legacy leftovers.
      await p.remove(_kLegacyName);
      await p.remove(_kLegacyProfileJson);
    } else {
      // One-time migration from the legacy plain-string key and the interim
      // object key.
      String? legacy = p.getString(_kLegacyName)?.trim();
      if (legacy == null || legacy.isEmpty) {
        final prof = p.getString(_kLegacyProfileJson);
        if (prof != null) {
          try {
            final d = jsonDecode(prof);
            if (d is Map) legacy = (d['name'] as String?)?.trim();
          } catch (_) {}
        }
      }
      if (legacy != null && legacy.isNotEmpty) {
        _playerNames
          ..clear()
          ..add(legacy);
      }
      await p.remove(_kLegacyName);
      await p.remove(_kLegacyProfileJson);
      await _saveNames();
    }

    themeId = p.getString(_kTheme) ?? 'toybox';
    ballStyle = (p.getInt(_kBallStyle) ?? 0).clamp(0, BallStyles.all.length - 1);
    gateStyle = (p.getInt(_kGateStyle) ?? 0).clamp(0, GateStyles.all.length - 1);
    difficulty = (p.getInt(_kDifficulty) ?? 0).clamp(0, 2);
    final m = p.getString(_kMode);
    mode = (m == 'attack') ? 'attack' : 'endless';
    isPro = p.getBool(_kIsPro) ?? false;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    for (final mm in ['endless', 'attack']) {
      for (int d = 0; d < 3; d++) {
        final b = p.getInt('$_kBestPrefix${mm}_$d') ?? 0;
        if (b > 0) bestScores['${mm}_$d'] = b;
      }
    }
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  /// Persist the name list immediately (order-preserving JSON string).
  Future<void> _saveNames() async {
    await _prefs?.setString(_kNamesJson, jsonEncode(_playerNames));
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await _saveNames();
    await p.remove(_kLegacyName);
    await p.remove(_kLegacyProfileJson);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kBallStyle, ballStyle);
    await p.setInt(_kGateStyle, gateStyle);
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kMode, mode);
    await p.setBool(_kIsPro, isPro);
    await p.setInt(_kGames, gamesPlayed);
    for (final e in bestScores.entries) {
      await p.setInt('$_kBestPrefix${e.key}', e.value);
    }
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp Pro-only picks back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || HueHopThemes.isProTheme(themeId)) {
      themeId = 'toybox';
      changed = true;
    }
    if (BallStyles.isPro(ballStyle)) {
      ballStyle = 0;
      changed = true;
    }
    if (GateStyles.isPro(gateStyle)) {
      gateStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  // --- mutators -----------------------------------------------------------
  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  /// Set the current player name. Saves on EVERY keystroke: the name list is
  /// persisted as one order-preserving JSON string (never setStringList).
  Future<void> setPlayerName(String raw) async {
    playerName = raw; // setter trims + falls back to the default
    notifyListeners();
    await _saveNames();
  }

  /// Commit on focus loss: re-trims and persists even when the text did not
  /// change since the last keystroke.
  Future<void> commitPlayerName(String raw) async {
    playerName = raw;
    notifyListeners();
    await _saveNames();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || HueHopThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setBallStyle(int v) async {
    v = v.clamp(0, BallStyles.all.length - 1);
    if (!isPro && BallStyles.isPro(v)) return;
    ballStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setGateStyle(int v) async {
    v = v.clamp(0, GateStyles.all.length - 1);
    if (!isPro && GateStyles.isPro(v)) return;
    gateStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) return; // Wild is Pro
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setMode(String m) async {
    if (m != 'attack' && m != 'endless') return;
    mode = m;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  /// Record a finished run. Returns true if it is a new best.
  Future<bool> recordRun({required String mode, required int difficulty, required int score}) async {
    gamesPlayed++;
    final k = '${mode}_$difficulty';
    final prev = bestScores[k] ?? 0;
    final isBest = score > prev;
    if (isBest) bestScores[k] = score;
    notifyListeners();
    await _save();
    return isBest;
  }
}
