import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand - FinTech Emerald
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primaryDark = Color(0xFF059669); // Emerald 600
  static const Color secondary = Color(0xFF6366F1); // Indigo 500
  static const Color accent = Color(0xFF06B6D4); // Cyan 500

  // Income & Expense Financial Tokens
  static const Color income = Color(0xFF10B981); // Green 500
  static const Color incomeBg = Color(0xFF064E3B); // Dark Green Fill
  static const Color expense = Color(0xFFF43F5E); // Rose 500
  static const Color expenseBg = Color(0xFF4C0519); // Dark Rose Fill

  // Deep Obsidian Dark Surface
  static const Color background = Color(0xFF0B0F19); // Deep Obsidian
  static const Color surface = Color(0xFF131C2E); // Card Base
  static const Color surfaceVariant = Color(0xFF1E293B); // Slate 800
  static const Color surfaceHighlight = Color(0xFF334155); // Slate 700

  // Borders
  static const Color border = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFF334155);

  // Status & Alerts
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // Typography Tokens
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Gradients
  static const LinearGradient balanceCardGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
