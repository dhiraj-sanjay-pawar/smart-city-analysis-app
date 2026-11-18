import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Smart City Modern Palette (Deep Navy & Teal) ───────────────
  static const Color primary = Color(0xFF16324F);        // Deep Navy
  static const Color primaryLight = Color(0xFF24476B);   // Navy Tint
  static const Color primaryDark = Color(0xFF0E2033);    // Midnight Navy

  // ── Secondary Palette (Teal) ──────────────────────────────────
  static const Color secondary = Color(0xFF0F766E);      // Teal
  static const Color secondaryLight = Color(0xFF14B8A6); // Bright Teal
  static const Color secondaryDark = Color(0xFF115E59);  // Deep Teal

  // ── Backgrounds ───────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7FA);     // Modern Smart City Cool White
  static const Color backgroundAlt = Color(0xFFEDF2F7);  // Soft Gray-Blue Tint
  static const Color backgroundDark = Color(0xFF0F172A); // Dark Slate
  static const Color surfaceDark = Color(0xFF1E293B);    // Dark Surface

  // ── Card / Surface ────────────────────────────────────────────
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color cardWarm = Color(0xFFF8FAFC);

  // ── Text ──────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF1E293B);       // Primary Text
  static const Color textMedium = Color(0xFF64748B);     // Secondary Text
  static const Color textLight = Color(0xFF94A3B8);      // Muted Text
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDarkMode = Color(0xFFF1F5F9);
  static const Color textDarkModeMedium = Color(0xFF94A3B8);

  // ── Border ────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderWarm = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);

  // ── Status Colors ─────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);          // Critical
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);

  // ── Complaint Status ──────────────────────────────────────────
  static const Color statusSubmitted = Color(0xFF6366F1);
  static const Color statusSubmittedLight = Color(0xFFEEF2FF);
  static const Color statusInProgress = Color(0xFF0F766E);
  static const Color statusInProgressLight = Color(0xFFCCFBF1);
  static const Color statusResolved = Color(0xFF16A34A);
  static const Color statusResolvedLight = Color(0xFFDCFCE7);
  static const Color statusRejected = Color(0xFFDC2626);
  static const Color statusRejectedLight = Color(0xFFFEE2E2);

  // ── Service Card Gradients ────────────────────────────────────
  static const LinearGradient cardTrafficGradient = LinearGradient(
    colors: [Color(0xFF16324F), Color(0xFF24476B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardCrimeGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardHealthGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardWasteGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Header Gradient ───────────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0E2033), Color(0xFF16324F), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Secondary accent ──────────────────────────────────────────
  static const Color accent = Color(0xFF0F766E);
  static const Color accentLight = Color(0xFFCCFBF1);
}
