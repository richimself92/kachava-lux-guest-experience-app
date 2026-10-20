import 'package:flutter/material.dart';

/// Semantic badge styling triplet (background, border, text/icon colors).
class AdminBadgeStyle {
  const AdminBadgeStyle({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}

/// Kachava Lux Brand & Semantic Operational Tokens (UI/UX Section 6.2).
class KachavaAdminColors {
  const KachavaAdminColors._();

  // Brand Surfaces & Typography
  static const Color canvasLow = Color(0xFFF7F3EA);
  static const Color surfacePaper = Color(0xFFFDF9F0);
  static const Color surfaceContainer = Color(0xFFF2EEE4);
  static const Color surfaceHigh = Color(0xFFECE8DF);
  static const Color borderLimestone = Color(0xFFE6E2D9);
  static const Color borderWarm = Color(0xFFD4C4B7);

  static const Color obsidian = Color(0xFF1C1C16);
  static const Color zapotePrimary = Color(0xFF754D24);
  static const Color zapoteDark = Color(0xFF603917);
  static const Color copalGold = Color(0xFFC49A6C);
  static const Color mutedBronze = Color(0xFFA67D52);
  static const Color warmAmberText = Color(0xFF8B6339);
  static const Color neutralMuted = Color(0xFF7F756A);

  // Semantic Operational Status & SLA Tokens
  static const AdminBadgeStyle stage1Requested = AdminBadgeStyle(
    background: Color(0xFFFEF3C7),
    border: Color(0x66F59E0B),
    foreground: Color(0xFF92400E),
  );

  static const AdminBadgeStyle stage2Assigned = AdminBadgeStyle(
    background: Color(0xFFF7E8D0),
    border: Color(0xFFC49A6C),
    foreground: Color(0xFF754D24),
  );

  static const AdminBadgeStyle stage3InProgress = AdminBadgeStyle(
    background: Color(0xFFE0F2FE),
    border: Color(0x660284C7),
    foreground: Color(0xFF075985),
  );

  static const AdminBadgeStyle stage4Completed = AdminBadgeStyle(
    background: Color(0xFFECFDF5),
    border: Color(0x6610B981),
    foreground: Color(0xFF065F46),
  );

  static const AdminBadgeStyle criticalAllergySla = AdminBadgeStyle(
    background: Color(0xFFFFDAD6),
    border: Color(0xFFBA1A1A),
    foreground: Color(0xFF93000A),
  );

  static const AdminBadgeStyle maritimeCharter = AdminBadgeStyle(
    background: Color(0xFF0B1F33),
    border: Color(0x6618B7C9),
    foreground: Color(0xFF18B7C9),
  );

  static const AdminBadgeStyle lifecyclePreArrival = AdminBadgeStyle(
    background: Color(0xFFF2EEE4),
    border: Color(0xFFD4C4B7),
    foreground: Color(0xFF8B6339),
  );

  static const AdminBadgeStyle lifecycleActiveStay = AdminBadgeStyle(
    background: Color(0xFF754D24),
    border: Color(0xFF603917),
    foreground: Color(0xFFFFFFFF),
  );

  static const AdminBadgeStyle lifecycleCheckedOut = AdminBadgeStyle(
    background: Color(0xFFECE8DF),
    border: Color(0xFFD4C4B7),
    foreground: Color(0xFF7F756A),
  );

  /// Resolves the semantic [AdminBadgeStyle] for any operational status string.
  static AdminBadgeStyle forStatus(String status) {
    final normalized = status.toUpperCase();
    if (normalized.contains('URGENT') ||
        normalized.contains('ALLERGY') ||
        normalized.contains('SLA') ||
        normalized.contains('DIRECT')) {
      return criticalAllergySla;
    }
    if (normalized.contains('COMPLETED') ||
        normalized.contains('CONFIRMED') ||
        normalized.contains('STOCKED') ||
        normalized.contains('SETTLED') ||
        normalized.contains('ATTENDED')) {
      return stage4Completed;
    }
    if (normalized.contains('PROGRESS') ||
        normalized.contains('ROUTE') ||
        normalized.contains('TERMINAL') ||
        normalized.contains('PREPARATION')) {
      return stage3InProgress;
    }
    if (normalized.contains('ASSIGNED')) {
      return stage2Assigned;
    }
    if (normalized.contains('ACTIVE_STAY')) {
      return lifecycleActiveStay;
    }
    if (normalized.contains('PRE_ARRIVAL')) {
      return lifecyclePreArrival;
    }
    if (normalized.contains('CHECKED_OUT') || normalized.contains('EXPIRED')) {
      return lifecycleCheckedOut;
    }
    return stage1Requested;
  }
}

/// Builds the Material 3 theme for the Kachava Lux Admin Dashboard.
class KachavaAdminTheme {
  const KachavaAdminTheme._();

  static ThemeData build() {
    const colorScheme = ColorScheme.light(
      primary: KachavaAdminColors.zapotePrimary,
      onPrimary: Colors.white,
      secondary: KachavaAdminColors.copalGold,
      onSecondary: KachavaAdminColors.obsidian,
      surface: KachavaAdminColors.surfacePaper,
      onSurface: KachavaAdminColors.obsidian,
      error: Color(0xFFBA1A1A),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KachavaAdminColors.canvasLow,
      fontFamily: 'Libre Franklin',
      dividerColor: KachavaAdminColors.borderLimestone,
      cardTheme: CardThemeData(
        color: KachavaAdminColors.surfacePaper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KachavaAdminColors.borderLimestone),
        ),
      ),
    );
  }
}
