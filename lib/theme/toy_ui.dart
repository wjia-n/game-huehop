import 'package:flutter/material.dart';
import 'huehop_themes.dart';

/// Shared physical toy-box UI kit for Hue Hop.
/// Chunky rounded panels, soft drop shadows, readable type — no neon,
/// no generic Material dashboard look.
class ToyUi {
  ToyUi._();

  static TextStyle display(double size, {required HueHopThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color ?? theme.text,
        letterSpacing: 0.5,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.12), offset: const Offset(0, 2), blurRadius: 0),
        ],
      );

  static TextStyle title(double size, {required HueHopThemeDef theme, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color ?? theme.text);

  static TextStyle body(double size, {required HueHopThemeDef theme, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w500, color: color ?? theme.subtext, height: 1.35);

  static TextStyle label(double size, {required HueHopThemeDef theme, Color? color}) =>
      TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color ?? theme.subtext,
          letterSpacing: 1.6);

  /// A chunky panel with a soft physical shadow.
  static Widget panel({required HueHopThemeDef theme, required Widget child, EdgeInsets? padding, Color? color}) =>
      Container(
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color ?? theme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.surfaceEdge, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: child,
      );

  /// A big squishy physical button.
  static Widget button({
    required HueHopThemeDef theme,
    required String text,
    required VoidCallback onTap,
    Color? color,
    Color? textColor,
    double fontSize = 18,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 34, vertical: 15),
  }) {
    final c = color ?? theme.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.18), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.22), offset: const Offset(0, 5), blurRadius: 0),
            BoxShadow(color: Colors.white.withValues(alpha: 0.28), offset: const Offset(0, 2), blurRadius: 0, spreadRadius: -1),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: textColor ?? Colors.white, letterSpacing: 0.6),
        ),
      ),
    );
  }

  /// Icon chip button (small, chunky, readable).
  static Widget iconButton({
    required HueHopThemeDef theme,
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    double size = 26,
  }) =>
      Tooltip(
        message: tooltip ?? '',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.surfaceEdge, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.16), offset: const Offset(0, 4), blurRadius: 0),
              ],
            ),
            child: Icon(icon, color: theme.text, size: size),
          ),
        ),
      );

  /// Soft paper-wash backdrop used behind every screen.
  static Widget backdrop({required HueHopThemeDef theme, required Widget child}) =>
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.bgTop, theme.bg],
          ),
        ),
        child: child,
      );
}

/// Shows a toast-style message bubble that always works, even mid-game.
void toySnack(BuildContext context, String msg, HueHopThemeDef theme) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: ToyUi.body(15, theme: theme, color: theme.text)),
      backgroundColor: theme.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.surfaceEdge, width: 2),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}
