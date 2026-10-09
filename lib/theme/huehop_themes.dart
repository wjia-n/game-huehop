import 'package:flutter/material.dart';

/// Hue Hop theme catalog: physical, tangible color stories (toy-box,
/// candy-shop, wooden, playground). No neon, no cyberpunk — warm materials
/// with real depth and shadow. Each theme supplies the 5 gate colors the
/// ball must match, plus the whole UI palette.
@immutable
class HueHopThemeDef {
  final String id;
  final String name;
  final bool isPro;
  final Color bg; // painter background
  final Color bgTop; // vertical wash top (subtle, never gradient-heavy)
  final Color surface; // cards / panels
  final Color surfaceEdge; // card borders
  final Color text;
  final Color subtext;
  final Color accent; // buttons, highlights
  final Color accentDark;
  final Color floor; // the start platform
  final List<Color> gates; // 5 match-colors, used in order
  final Color orbHalo; // swapper-orb halo
  final Color trail; // motion-trail tint

  const HueHopThemeDef({
    required this.id,
    required this.name,
    this.isPro = false,
    required this.bg,
    required this.bgTop,
    required this.surface,
    required this.surfaceEdge,
    required this.text,
    required this.subtext,
    required this.accent,
    required this.accentDark,
    required this.floor,
    required this.gates,
    required this.orbHalo,
    required this.trail,
  });
}

class HueHopThemes {
  HueHopThemes._();

  static const _toyBox = HueHopThemeDef(
    id: 'toybox',
    name: 'Toy Box',
    bg: Color(0xFFF7EDDC),
    bgTop: Color(0xFFFDF8EE),
    surface: Color(0xFFFFFBF2),
    surfaceEdge: Color(0xFFE4D3B4),
    text: Color(0xFF4A3320),
    subtext: Color(0xFF8A6F52),
    accent: Color(0xFFE8604C),
    accentDark: Color(0xFFB84434),
    floor: Color(0xFFE8604C),
    gates: [
      Color(0xFFE8604C), // coral
      Color(0xFF3E9BDC), // sky
      Color(0xFFF2B134), // sunflower
      Color(0xFF7C5CC4), // grape
      Color(0xFF4CAF6D), // grass
    ],
    orbHalo: Color(0xFFF2B134),
    trail: Color(0xFFE8604C),
  );

  static const List<HueHopThemeDef> all = [
    _toyBox,
    HueHopThemeDef(
      id: 'candyshop',
      name: 'Candy Shop',
      bg: Color(0xFFFDEBF3),
      bgTop: Color(0xFFFFF6FA),
      surface: Color(0xFFFFFDFE),
      surfaceEdge: Color(0xFFF2C6DC),
      text: Color(0xFF5C2E44),
      subtext: Color(0xFFA06A86),
      accent: Color(0xFFE75480),
      accentDark: Color(0xFFB93A62),
      floor: Color(0xFFE75480),
      gates: [
        Color(0xFFE75480),
        Color(0xFF7FB6E8),
        Color(0xFFF7C948),
        Color(0xFF9B7ED9),
        Color(0xFF6FCF97),
      ],
      orbHalo: Color(0xFFF7C948),
      trail: Color(0xFFE75480),
    ),
    HueHopThemeDef(
      id: 'woodblocks',
      name: 'Wooden Blocks',
      bg: Color(0xFFEFDFC2),
      bgTop: Color(0xFFF6ECD8),
      surface: Color(0xFFF9F1DE),
      surfaceEdge: Color(0xFFD3B98C),
      text: Color(0xFF4E3A22),
      subtext: Color(0xFF937A55),
      accent: Color(0xFFB5651D),
      accentDark: Color(0xFF8A4C12),
      floor: Color(0xFF8A4C12),
      gates: [
        Color(0xFFB5651D),
        Color(0xFF3E7CB1),
        Color(0xFFC9A227),
        Color(0xFF6A4C93),
        Color(0xFF4E7C3A),
      ],
      orbHalo: Color(0xFFC9A227),
      trail: Color(0xFFB5651D),
    ),
    HueHopThemeDef(
      id: 'chalkboard',
      name: 'Chalkboard',
      bg: Color(0xFF2E3B3A),
      bgTop: Color(0xFF3A4A48),
      surface: Color(0xFF3A4A48),
      surfaceEdge: Color(0xFF5C7370),
      text: Color(0xFFF4EFE3),
      subtext: Color(0xFFB9C6C2),
      accent: Color(0xFFFFD166),
      accentDark: Color(0xFFD9A93F),
      floor: Color(0xFFFFD166),
      gates: [
        Color(0xFFF4F1DE),
        Color(0xFF81B29A),
        Color(0xFFF2CC8F),
        Color(0xFFE07A5F),
        Color(0xFF9DB4D0),
      ],
      orbHalo: Color(0xFFFFD166),
      trail: Color(0xFFF4F1DE),
    ),
    HueHopThemeDef(
      id: 'playground',
      name: 'Playground Rubber',
      bg: Color(0xFFE8F1F5),
      bgTop: Color(0xFFF4FAFC),
      surface: Color(0xFFFFFFFF),
      surfaceEdge: Color(0xFFBFD6E0),
      text: Color(0xFF22333B),
      subtext: Color(0xFF5F7A86),
      accent: Color(0xFFD90429),
      accentDark: Color(0xFFA4031F),
      floor: Color(0xFF2B2D42),
      gates: [
        Color(0xFFD90429),
        Color(0xFF2B7BD4),
        Color(0xFFFFB703),
        Color(0xFF7B2D8E),
        Color(0xFF38A34C),
      ],
      orbHalo: Color(0xFFFFB703),
      trail: Color(0xFFD90429),
    ),
    HueHopThemeDef(
      id: 'claycraft',
      name: 'Clay Craft',
      bg: Color(0xFFF3E3D3),
      bgTop: Color(0xFFFAF0E1),
      surface: Color(0xFFFBF4E8),
      surfaceEdge: Color(0xFFDDB99A),
      text: Color(0xFF5A3A28),
      subtext: Color(0xFF9C7A5E),
      accent: Color(0xFFC1663E),
      accentDark: Color(0xFF9A4E2C),
      floor: Color(0xFF9A4E2C),
      gates: [
        Color(0xFFC1663E),
        Color(0xFF5B8E7D),
        Color(0xFFE0A458),
        Color(0xFF8E5B8F),
        Color(0xFF748B4A),
      ],
      orbHalo: Color(0xFFE0A458),
      trail: Color(0xFFC1663E),
    ),
    HueHopThemeDef(
      id: 'poolparty',
      name: 'Pool Party',
      bg: Color(0xFFDFF3F6),
      bgTop: Color(0xFFEFFBFD),
      surface: Color(0xFFF7FDFE),
      surfaceEdge: Color(0xFFA9DCE6),
      text: Color(0xFF144E5E),
      subtext: Color(0xFF4E8698),
      accent: Color(0xFF1899B6),
      accentDark: Color(0xFF0F7489),
      floor: Color(0xFF0F7489),
      gates: [
        Color(0xFF1899B6),
        Color(0xFFFF6B6B),
        Color(0xFFFFD93D),
        Color(0xFF6C5CE7),
        Color(0xFF00B894),
      ],
      orbHalo: Color(0xFFFFD93D),
      trail: Color(0xFF1899B6),
    ),
    HueHopThemeDef(
      id: 'meadow',
      name: 'Picnic Meadow',
      bg: Color(0xFFE9F2DC),
      bgTop: Color(0xFFF4FAEA),
      surface: Color(0xFFFCFEF7),
      surfaceEdge: Color(0xFFBBD3A4),
      text: Color(0xFF2E4423),
      subtext: Color(0xFF647F52),
      accent: Color(0xFF5C9E46),
      accentDark: Color(0xFF417434),
      floor: Color(0xFF417434),
      gates: [
        Color(0xFF5C9E46),
        Color(0xFFD64550),
        Color(0xFFF4A940),
        Color(0xFF4D7EA8),
        Color(0xFF9B5DE5),
      ],
      orbHalo: Color(0xFFF4A940),
      trail: Color(0xFF5C9E46),
    ),
    HueHopThemeDef(
      id: 'sunsetfair',
      name: 'Sunset Fair',
      bg: Color(0xFFF9E8D2),
      bgTop: Color(0xFFFDF3E4),
      surface: Color(0xFFFFF8EC),
      surfaceEdge: Color(0xFFE8C39A),
      text: Color(0xFF5E3520),
      subtext: Color(0xFF9C6F4E),
      accent: Color(0xFFE76F51),
      accentDark: Color(0xFFB94F35),
      floor: Color(0xFFB94F35),
      gates: [
        Color(0xFFE76F51),
        Color(0xFF2A9D8F),
        Color(0xFFE9C46A),
        Color(0xFF7B4B94),
        Color(0xFFD1495B),
      ],
      orbHalo: Color(0xFFE9C46A),
      trail: Color(0xFFE76F51),
    ),
    HueHopThemeDef(
      id: 'sprinkles',
      name: 'Rainbow Sprinkles',
      isPro: true,
      bg: Color(0xFFFFF3E0),
      bgTop: Color(0xFFFFFAF2),
      surface: Color(0xFFFFFFFF),
      surfaceEdge: Color(0xFFEFC9A8),
      text: Color(0xFF4E342E),
      subtext: Color(0xFF8D6E63),
      accent: Color(0xFFFF7043),
      accentDark: Color(0xFFD84315),
      floor: Color(0xFF6D4C41),
      gates: [
        Color(0xFFFF5252),
        Color(0xFFFFAB40),
        Color(0xFFFFEE58),
        Color(0xFF69F0AE),
        Color(0xFF40C4FF),
      ],
      orbHalo: Color(0xFFFFEE58),
      trail: Color(0xFFFF7043),
    ),
    HueHopThemeDef(
      id: 'starlit',
      name: 'Starlit Circus',
      isPro: true,
      bg: Color(0xFF232347),
      bgTop: Color(0xFF2E2E5C),
      surface: Color(0xFF2E2E5C),
      surfaceEdge: Color(0xFF4A4A7D),
      text: Color(0xFFF6EBD8),
      subtext: Color(0xFFB9B3D1),
      accent: Color(0xFFFFB703),
      accentDark: Color(0xFFD18F00),
      floor: Color(0xFFFFB703),
      gates: [
        Color(0xFFFFB703),
        Color(0xFFEF476F),
        Color(0xFF06D6A0),
        Color(0xFF6C9BF5),
        Color(0xFFF6EBD8),
      ],
      orbHalo: Color(0xFFFFB703),
      trail: Color(0xFFEF476F),
    ),
    HueHopThemeDef(
      id: 'goldtoy',
      name: 'Golden Toy',
      isPro: true,
      bg: Color(0xFFF8F1DE),
      bgTop: Color(0xFFFEFAEF),
      surface: Color(0xFFFFFDF6),
      surfaceEdge: Color(0xFFE3C878),
      text: Color(0xFF4E3E1A),
      subtext: Color(0xFF8A7748),
      accent: Color(0xFFC9A227),
      accentDark: Color(0xFF9A7B1A),
      floor: Color(0xFF9A7B1A),
      gates: [
        Color(0xFFC9A227),
        Color(0xFF8B5E34),
        Color(0xFFD95555),
        Color(0xFF3E7CB1),
        Color(0xFF5C9E46),
      ],
      orbHalo: Color(0xFFFFD166),
      trail: Color(0xFFC9A227),
    ),
    HueHopThemeDef(
      id: 'bubblegum',
      name: 'Bubblegum Pop',
      isPro: true,
      bg: Color(0xFFFDE7EF),
      bgTop: Color(0xFFFFF2F6),
      surface: Color(0xFFFFFAFB),
      surfaceEdge: Color(0xFFF0AEC6),
      text: Color(0xFF5C2740),
      subtext: Color(0xFFA0637F),
      accent: Color(0xFFE0447C),
      accentDark: Color(0xFFB02E5E),
      floor: Color(0xFFB02E5E),
      gates: [
        Color(0xFFE0447C),
        Color(0xFF45B7D1),
        Color(0xFFFFC93C),
        Color(0xFF8E6BC8),
        Color(0xFF5FCF80),
      ],
      orbHalo: Color(0xFFFFC93C),
      trail: Color(0xFFE0447C),
    ),
    HueHopThemeDef(
      id: 'mintchoc',
      name: 'Mint Choc',
      isPro: true,
      bg: Color(0xFF4A3B32),
      bgTop: Color(0xFF5A4A40),
      surface: Color(0xFF5A4A40),
      surfaceEdge: Color(0xFF7D6859),
      text: Color(0xFFF3E9DC),
      subtext: Color(0xFFC3AF9C),
      accent: Color(0xFF7FD1A8),
      accentDark: Color(0xFF5AA87F),
      floor: Color(0xFF7FD1A8),
      gates: [
        Color(0xFF7FD1A8),
        Color(0xFFF3E9DC),
        Color(0xFFE8A87C),
        Color(0xFF9DB4D0),
        Color(0xFFD17F7F),
      ],
      orbHalo: Color(0xFFE8A87C),
      trail: Color(0xFF7FD1A8),
    ),
  ];

  static HueHopThemeDef byId(String id, {HueHopThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static bool isProTheme(String id) =>
      all.any((t) => t.id == id && t.isPro) || id == 'custom';
}
