import 'package:flutter/material.dart';

class LitePalette {
  final bool dark;
  final Color background;
  final Color panel;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final Color primarySoft;
  final Color success;
  final Color warning;
  final Color danger;
  final List<BoxShadow> shadow;

  const LitePalette._({
    required this.dark,
    required this.background,
    required this.panel,
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.primarySoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
  });

  static const _light = LitePalette._(
    dark: false,
    background: Color(0xFFF3F6FA),
    panel: Color(0xFFFAFBFD),
    card: Colors.white,
    border: Color(0xFFE2E8F0),
    text: Color(0xFF0F1B2D),
    muted: Color(0xFF5B6B80),
    primary: Color(0xFF0B6BCB),
    primarySoft: Color(0xFFE6F0FB),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    danger: Color(0xFFB91C1C),
    shadow: [
      BoxShadow(color: Color(0x0F0F1B2D), blurRadius: 24, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x0A0F1B2D), blurRadius: 2, offset: Offset(0, 1)),
    ],
  );

  static const _dark = LitePalette._(
    dark: true,
    background: Color(0xFF0E151E),
    panel: Color(0xFF121B26),
    card: Color(0xFF17222F),
    border: Color(0xFF253344),
    text: Color(0xFFE6EDF5),
    muted: Color(0xFF94A3B8),
    primary: Color(0xFF4C9BEA),
    primarySoft: Color(0xFF16304A),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    shadow: [],
  );

  static LitePalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  BoxDecoration cardDecoration({double radius = 16}) => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: shadow,
      );
}
