import 'package:flutter/material.dart';

/// Shared Instagram DM purple theme used across chat and scribble.
abstract final class AppTheme {
  static const Color scaffoldBg = Color(0xFF1A0033);
  static const Color gradientStart = Color(0xFF2C0069);
  static const Color gradientEnd = Color(0xFF4A00B4);
  static const Color bubbleMe = Color(0xFF8B5CF6);
  static const Color bubbleOther = Color(0xFF1E004B);
  static const Color canvasBg = Color(0xFF12002A);
  static const Color strokeLocal = Color(0xFF8B5CF6);
  static const Color strokeRemote = Color(0xFFC4B5FD);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration gradientBackground() => const BoxDecoration(
        gradient: backgroundGradient,
      );

  static BoxDecoration scribbleSheetDecoration() => BoxDecoration(
        color: scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: bubbleMe.withValues(alpha: 0.35)),
      );
}
