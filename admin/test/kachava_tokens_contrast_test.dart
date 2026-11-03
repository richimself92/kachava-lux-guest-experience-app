import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/theme/kachava_tokens.dart';

void main() {
  group('KachavaTokens contrast (WCAG AA)', () {
    test('test_contrastRatio_blackOnWhite_is21', () {
      expect(contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
          closeTo(21.0, 0.01));
      expect(contrastRatio(const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)),
          closeTo(1.0, 0.001));
    });

    test('test_textColors_meetAA_onBackgroundAndSurface', () {
      for (final fg in [KachavaTokens.text, KachavaTokens.textSecondary]) {
        for (final bg in [KachavaTokens.background, KachavaTokens.surface]) {
          expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('test_statusTones_foregroundMeetsAA_onItsBackground', () {
      for (final tone in StatusTone.values) {
        expect(contrastRatio(tone.foreground, tone.background),
            greaterThanOrEqualTo(4.5),
            reason: tone.name);
      }
    });

    test('test_inputBorder_and_onPrimary_contrast', () {
      expect(contrastRatio(KachavaTokens.inputBorder, KachavaTokens.background),
          greaterThanOrEqualTo(3.0));
      expect(contrastRatio(KachavaTokens.onPrimary, KachavaTokens.primary),
          greaterThanOrEqualTo(4.5));
    });

    test('test_selectedNav_brownText_meetsAA_onBrownTint', () {
      expect(
          contrastRatio(KachavaTokens.primary, KachavaTokens.primarySelected),
          greaterThanOrEqualTo(4.5));
    });

    test('test_radii_matchDesignMd', () {
      // DESIGN.md: --kl-radius-sm 4, md 8, lg 12; corner radii restrained 4–12px.
      expect(KachavaTokens.radiusSm, 4);
      expect(KachavaTokens.radiusMd, 8);
      expect(KachavaTokens.radiusLg, 12);
      expect(KachavaTokens.radiusTile, inInclusiveRange(4, 12));
    });
  });
}
