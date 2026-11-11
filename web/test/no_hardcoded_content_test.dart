import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/core/i18n/l10n.dart';
import 'package:kachava_guest_portal/core/theme/kachava_colors.dart';
import 'package:kachava_guest_portal/core/theme/kachava_theme.dart';
import 'package:kachava_guest_portal/domain/catalog.dart';

/// Every Dart source under lib/ (production code only).
Map<String, String> _sources() => {
      for (final f
          in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
    };

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final x = _luminance(a), y = _luminance(b);
  return (max(x, y) + 0.05) / (min(x, y) + 0.05);
}

void main() {
  test('no hardcoded services, places, phones or demo guests in lib/', () {
    final banned = RegExp(
      r'yacht|cenote|tulum|philosophy|lux bar|breakfast|massage|cocktail|catamaran|'
      r'villa 102|ceiba|miller|550e8400|\+52|whatsapp|demo',
      caseSensitive: false,
    );
    final hits = <String>[];
    _sources().forEach((path, code) {
      for (final (i, line) in code.split('\n').indexed) {
        if (banned.hasMatch(line)) hits.add('$path:${i + 1}: ${line.trim()}');
      }
    });
    expect(hits, isEmpty);
  });

  test('no fake success: every "copied" toast follows a real Clipboard call',
      () {
    _sources().forEach((path, code) {
      if (path.contains('presentation') && code.contains('wifiCopied')) {
        expect(code, contains('Clipboard.setData'), reason: path);
      }
    });
  });

  test('visible wording says Resort Host, never Concierge', () {
    final l10n = File('lib/core/i18n/l10n.dart').readAsStringSync();
    expect(RegExp(r"'[^']*Concierge[^']*'").hasMatch(l10n), isFalse);
  });

  test('missing Spanish shows "Translation pending", never auto-translated',
      () {
    expect(const L10n(Lang.es).text(const LocalizedText(en: 'Pool')),
        'Traducción pendiente');
    expect(const L10n(Lang.en).text(const LocalizedText(en: 'Pool')), 'Pool');
  });

  test('text styles are >= 14px and AA on cream', () {
    final theme = KachavaTheme.buildTheme().textTheme;
    final styles = [
      theme.headlineMedium,
      theme.titleLarge,
      theme.titleMedium,
      theme.bodyLarge,
      theme.bodyMedium,
      theme.bodySmall,
      theme.labelLarge,
      theme.labelMedium,
      theme.labelSmall,
    ];
    for (final s in styles) {
      expect(s!.fontSize, greaterThanOrEqualTo(14));
      expect(
          _contrast(s.color!, KachavaColors.surface), greaterThanOrEqualTo(4.5),
          reason: '${s.color}');
    }
    expect(theme.bodyLarge!.fontSize, 16);
    expect(
        _contrast(
            KachavaColors.mutedMetadata, KachavaColors.surfaceContainerLow),
        greaterThanOrEqualTo(4.5));
  });

  test('no text style in lib/ is smaller than 14px', () {
    final small = RegExp(r'fontSize:\s*(\d+(\.\d+)?)');
    _sources().forEach((path, code) {
      for (final m in small.allMatches(code)) {
        expect(double.parse(m.group(1)!), greaterThanOrEqualTo(14),
            reason: path);
      }
    });
  });
}
