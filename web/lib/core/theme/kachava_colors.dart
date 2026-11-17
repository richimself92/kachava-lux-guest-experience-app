import 'package:flutter/material.dart';

/// Text, quiet background and hairline of one status label.
@immutable
class StatusTone {
  const StatusTone(this.text, this.wash, this.line);
  final Color text;
  final Color wash;
  final Color line;
}

/// Kachava Lux MUJI tokens, shared with the admin Command Center.
///
/// Contrast (WCAG): ink 12.9 / muted 4.8 on paper; ink 13.7 / muted 5.1 on
/// surface; ink 11.9 / brand 6.8 on wash; onBrand 7.8 on brand. Muted on
/// wash is only 4.47, so text on wash is always [ink] or [brand].
/// [lineStrong] (1.8:1) is decorative; focus is shown in [ink] at 1.5px.
abstract final class KachavaColors {
  // Neutrals: warm paper and ink.
  static const Color paper = Color(0xFFF4F2EC);
  static const Color surface = Color(0xFFFAF9F5);
  static const Color wash = Color(0xFFECE9E1);
  static const Color ink = Color(0xFF2A2A28);
  static const Color muted = Color(0xFF6B6A65);
  static const Color faint = Color(0xFFA3A097);
  static const Color line = Color(0xFFD9D6CD);
  static const Color lineStrong = Color(0xFFC2BEB2);

  // The single accent.
  static const Color brand = Color(0xFF6D4627);
  static const Color primary = brand;
  static const Color brandDeep = Color(0xFF55361D);
  static const Color onBrand = Color(0xFFFAF9F5);

  // Status colours carry meaning only (text / wash / line).
  static const Color pendingText = Color(0xFF8F611A);
  static const Color pendingWash = Color(0xFFF3EBD9);
  static const Color pendingLine = Color(0xFFE2D2AE);
  static const StatusTone pending =
      StatusTone(pendingText, pendingWash, pendingLine);

  static const Color infoText = Color(0xFF3F5A7A);
  static const Color infoWash = Color(0xFFE6EBF1);
  static const Color infoLine = Color(0xFFC9D3DF);
  static const StatusTone info = StatusTone(infoText, infoWash, infoLine);

  static const Color okText = Color(0xFF4F6B3A);
  static const Color okWash = Color(0xFFE8EDE1);
  static const Color okLine = Color(0xFFCDD8C1);
  static const StatusTone ok = StatusTone(okText, okWash, okLine);

  static const Color dangerText = Color(0xFFA8322D);
  static const Color dangerWash = Color(0xFFF5E3E1);
  static const Color dangerLine = Color(0xFFE6C3BF);
  static const StatusTone danger =
      StatusTone(dangerText, dangerWash, dangerLine);

  static const List<StatusTone> statuses = [pending, info, ok, danger];
}
