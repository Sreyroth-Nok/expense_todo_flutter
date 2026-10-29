import 'package:flutter/material.dart';

/// LifeMate Design System — Color Palette (Deep Teal + Honey)
///
/// Never use Flutter's built-in color constants directly in UI code.
/// Always reference these tokens so color changes propagate everywhere.
abstract final class AppColors {
  // ── Primary brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);

  // ── Honey accent ───────────────────────────────────────────────
  static const Color honey = Color(0xFFF0B429);

  // ── Backgrounds ────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color softTeal = Color(0xFFCCFBF1);

  // ── Text ───────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  // ── Borders / dividers ─────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);

  // ── Semantic colors ────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);

  // ── Derived / helper ───────────────────────────────────────────
  static const Color primaryLight = Color(0xFF0D9488); // teal-600
  static const Color surfaceVariant = Color(0xFFF9FAFB); // gray-50
  static const Color divider = Color(0xFFF3F4F6); // gray-100
}
