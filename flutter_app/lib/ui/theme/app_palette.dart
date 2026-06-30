import 'package:flutter/material.dart';

class AppPalette {
  AppPalette._();

  static const Color brandPrimary = Color(0xFF1E40AF);
  static const Color brandSecondary = Color(0xFF0EA5E9);
  static const Color brandAccent = Color(0xFF14B8A6);

  static const Color background = Color(0xFFF6F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF2F7);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE5E7EB);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);

  static const Color reaction = Color(0xFF2563EB);
  static const Color ultimate = Color(0xFFE11D48);
  static const Color simulation = Color(0xFF0891B2);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
  );
}
