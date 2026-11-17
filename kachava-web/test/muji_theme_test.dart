import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/core/i18n/l10n.dart';
import 'package:kachava_guest_portal/core/theme/kachava_colors.dart';
import 'package:kachava_guest_portal/core/theme/kachava_theme.dart';
import 'package:kachava_guest_portal/domain/requests.dart';
import 'package:kachava_guest_portal/presentation/common/widgets.dart';

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final x = _luminance(a), y = _luminance(b);
  return (max(x, y) + 0.05) / (min(x, y) + 0.05);
}

const _radius2 = BorderRadius.all(Radius.circular(2));

BorderRadiusGeometry? _radiusOf(OutlinedBorder? shape) =>
    shape is RoundedRectangleBorder ? shape.borderRadius : null;

void main() {
  final theme = KachavaTheme.buildTheme();

  group('MUJI palette', () {
    test('exact token values; one brand shared with admin', () {
      expect(KachavaColors.paper, const Color(0xFFF4F2EC));
      expect(KachavaColors.surface, const Color(0xFFFAF9F5));
      expect(KachavaColors.wash, const Color(0xFFECE9E1));
      expect(KachavaColors.ink, const Color(0xFF2A2A28));
      expect(KachavaColors.muted, const Color(0xFF6B6A65));
      expect(KachavaColors.faint, const Color(0xFFA3A097));
      expect(KachavaColors.line, const Color(0xFFD9D6CD));
      expect(KachavaColors.lineStrong, const Color(0xFFC2BEB2));
      expect(KachavaColors.brand, const Color(0xFF6D4627));
      expect(KachavaColors.primary, KachavaColors.brand);
      expect(KachavaColors.brandDeep, const Color(0xFF55361D));
      expect(KachavaColors.onBrand, const Color(0xFFFAF9F5));
    });

    test('ink and muted are AA on paper and surface', () {
      for (final bg in [KachavaColors.paper, KachavaColors.surface]) {
        expect(_contrast(KachavaColors.ink, bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(KachavaColors.muted, bg), greaterThanOrEqualTo(4.5));
      }
    });

    test('text on wash (ink, brand) is AA; text on brand is AA', () {
      expect(_contrast(KachavaColors.ink, KachavaColors.wash),
          greaterThanOrEqualTo(4.5));
      expect(_contrast(KachavaColors.brand, KachavaColors.wash),
          greaterThanOrEqualTo(4.5));
      expect(_contrast(KachavaColors.onBrand, KachavaColors.brand),
          greaterThanOrEqualTo(4.5));
      expect(_contrast(KachavaColors.onBrand, KachavaColors.brandDeep),
          greaterThanOrEqualTo(4.5));
    });

    test('each status text is AA on its own wash', () {
      for (final s in KachavaColors.statuses) {
        expect(_contrast(s.text, s.wash), greaterThanOrEqualTo(4.5),
            reason: '${s.text}');
      }
      expect(KachavaColors.statuses, hasLength(4));
    });
  });

  group('MUJI theme', () {
    test('fonts: Zen Kaku display, Noto Sans body; 400/500 only', () {
      expect(KachavaTheme.displayFamily, 'Zen Kaku Gothic New');
      expect(KachavaTheme.sansFamily, 'Noto Sans');
      final t = theme.textTheme;
      expect(t.titleLarge!.fontFamily, KachavaTheme.displayFamily);
      expect(t.titleLarge!.fontWeight, FontWeight.w500);
      expect(t.titleLarge!.letterSpacing,
          closeTo(t.titleLarge!.fontSize! * 0.02, 0.001));
      expect(t.bodyLarge!.fontFamily, KachavaTheme.sansFamily);
      for (final s in [
        t.headlineMedium, t.titleLarge, t.titleMedium, t.bodyLarge, //
        t.bodyMedium, t.bodySmall, t.labelLarge, t.labelMedium, t.labelSmall,
      ]) {
        expect([FontWeight.w400, FontWeight.w500], contains(s!.fontWeight));
      }
    });

    test('klLabel: display 12px w500, tracked 0.14em, muted', () {
      const s = KachavaTheme.klLabel;
      expect(s.fontFamily, KachavaTheme.displayFamily);
      expect(s.fontSize, inInclusiveRange(11, 12));
      expect(s.fontWeight, FontWeight.w500);
      expect(s.letterSpacing, closeTo(s.fontSize! * 0.14, 0.001));
      expect(s.color, KachavaColors.muted);
    });

    test('scaffold is paper, primary is brand, no surface tint', () {
      expect(theme.scaffoldBackgroundColor, KachavaColors.paper);
      expect(theme.colorScheme.primary, KachavaColors.brand);
      expect(theme.colorScheme.onPrimary, KachavaColors.onBrand);
      expect(theme.colorScheme.surfaceTint, Colors.transparent);
    });

    test('card, buttons and bottom sheet: radius 2, elevation 0', () {
      expect(theme.cardTheme.elevation, 0);
      expect(_radiusOf(theme.cardTheme.shape as OutlinedBorder?), _radius2);
      for (final style in [
        theme.filledButtonTheme.style!,
        theme.outlinedButtonTheme.style!,
        theme.textButtonTheme.style!,
      ]) {
        expect(style.elevation?.resolve({}) ?? 0, 0);
        expect(_radiusOf(style.shape!.resolve({})), _radius2);
      }
      final filled = theme.filledButtonTheme.style!;
      expect(filled.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(44));
      expect(filled.backgroundColor!.resolve({}), KachavaColors.brand);
      expect(filled.backgroundColor!.resolve({WidgetState.hovered}),
          KachavaColors.brandDeep);
      final sheet = theme.bottomSheetTheme;
      expect(sheet.elevation, 0);
      expect(sheet.backgroundColor, KachavaColors.surface);
      expect(_radiusOf(sheet.shape as OutlinedBorder?),
          const BorderRadius.vertical(top: Radius.circular(2)));
    });

    test('inputs: surface fill, line border, ink focus 1.5px, 16px text', () {
      final d = theme.inputDecorationTheme;
      expect(d.fillColor, KachavaColors.surface);
      expect(d.enabledBorder!.borderSide.color, KachavaColors.line);
      expect(d.focusedBorder!.borderSide.color, KachavaColors.ink);
      expect(d.focusedBorder!.borderSide.width, 1.5);
      expect(theme.textTheme.bodyLarge!.fontSize, 16);
    });

    test('page transitions are quiet fades (220ms)', () {
      final builders = theme.pageTransitionsTheme.builders.values;
      expect(builders, isNotEmpty);
      for (final b in builders) {
        expect(b, isA<QuietFadeTransitionsBuilder>());
        expect(b.transitionDuration, KachavaTheme.motion);
      }
      expect(KachavaTheme.motion, const Duration(milliseconds: 220));
    });
  });

  testWidgets('status label is a radius-2 rectangle with a line, not a pill',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: StatusChip(status: RequestStatus.confirmed, l10n: L10n(Lang.en)),
      ),
    ));
    final box = tester.widget<Container>(find
        .descendant(
            of: find.byType(StatusChip), matching: find.byType(Container))
        .first);
    final deco = box.decoration! as BoxDecoration;
    expect(deco.borderRadius, _radius2);
    expect(deco.color, KachavaColors.ok.wash);
    expect(deco.border, isNotNull);
  });

  group('MUJI assets and meta', () {
    test('pubspec ships Zen Kaku and Noto Sans, never Libre', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: Zen Kaku Gothic New'));
      expect(pubspec, contains('family: Noto Sans'));
      expect(pubspec, isNot(contains('Libre')));
      final fonts = Directory('assets/fonts').listSync().map((f) => f.path);
      expect(fonts.where((p) => p.contains('Libre')), isEmpty);
    });

    test('browser chrome is paper (#F4F2EC)', () {
      final html = File('web/index.html').readAsStringSync();
      expect(html, contains('<meta name="theme-color" content="#F4F2EC">'));
      expect(html, isNot(contains('#F7F3EA')));
      final manifest = File('web/manifest.json').readAsStringSync();
      expect(manifest, contains('"theme_color": "#F4F2EC"'));
      expect(manifest, contains('"background_color": "#F4F2EC"'));
    });

    test('lib sweep: no white, shadows, heavy weights or stray hex', () {
      final banned = RegExp(r'Colors\.white|BoxShadow|FontWeight\.(w600|w700|'
          r'w800|w900|bold)|Color\(0x|BorderRadius\.circular\(\d');
      final hits = <String>[];
      for (final f
          in Directory('lib').listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart') ||
            f.path.endsWith('kachava_colors.dart')) {
          continue;
        }
        for (final (i, line) in f.readAsLinesSync().indexed) {
          if (banned.hasMatch(line)) hits.add('${f.path}:${i + 1}: $line');
        }
      }
      expect(hits, isEmpty);
    });
  });
}
