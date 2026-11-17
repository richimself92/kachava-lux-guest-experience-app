import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/theme/kachava_tokens.dart';

void main() {
  group('KachavaTokens contrast (WCAG AA, MUJI palette)', () {
    test('test_contrastRatio_blackOnWhite_is21', () {
      expect(contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
          closeTo(21.0, 0.01));
      expect(contrastRatio(const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)),
          closeTo(1.0, 0.001));
    });

    test('test_inkAndMuted_meetAA_onPaperAndSurface', () {
      for (final fg in [KachavaTokens.ink, KachavaTokens.muted]) {
        for (final bg in [KachavaTokens.paper, KachavaTokens.surface]) {
          expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('test_textOnBrand_meetsAA_onBrandAndBrandDeep', () {
      for (final bg in [KachavaTokens.brand, KachavaTokens.brandDeep]) {
        expect(contrastRatio(KachavaTokens.onBrand, bg),
            greaterThanOrEqualTo(4.5));
      }
    });

    test('test_statusTones_textMeetsAA_onItsWash', () {
      for (final tone in StatusTone.values) {
        expect(contrastRatio(tone.foreground, tone.wash),
            greaterThanOrEqualTo(4.5),
            reason: tone.name);
      }
    });

    test('test_statusTones_mapToMujiStatusColors', () {
      expect(StatusTone.success.foreground, KachavaTokens.ok);
      expect(StatusTone.info.foreground, KachavaTokens.info);
      expect(StatusTone.warning.foreground, KachavaTokens.pending);
      expect(StatusTone.error.foreground, KachavaTokens.danger);
      expect(StatusTone.onHold.foreground, KachavaTokens.plum);
      expect(StatusTone.warning.wash, KachavaTokens.pendingWash);
      expect(StatusTone.warning.line, KachavaTokens.pendingLine);
      // Neutral: muted text on surface (muted on wash is only 4.47:1).
      expect(StatusTone.neutral.foreground, KachavaTokens.muted);
      expect(StatusTone.neutral.wash, KachavaTokens.surface);
      expect(StatusTone.neutral.line, KachavaTokens.line);
    });

    test('test_lineStrong_isTheStrongestHairline_ratioRecorded', () {
      // Client value kept as specified: 1.76:1 on surface (not 3:1); inputs
      // rely on the ink 1.5px focus border instead.
      final strong =
          contrastRatio(KachavaTokens.lineStrong, KachavaTokens.surface);
      final line = contrastRatio(KachavaTokens.line, KachavaTokens.surface);
      expect(strong, closeTo(1.76, 0.01));
      expect(strong, greaterThan(line));
      expect(contrastRatio(KachavaTokens.ink, KachavaTokens.surface),
          greaterThanOrEqualTo(4.5));
    });

    test('test_inkText_meetsAA_onWash', () {
      expect(contrastRatio(KachavaTokens.ink, KachavaTokens.wash),
          greaterThanOrEqualTo(4.5));
    });

    test('test_radius_isSquare2_andMotionIsQuietFade', () {
      expect(KachavaTokens.radius, 2);
      expect(KachavaTokens.radiusRound, greaterThan(100));
      expect(KachavaTokens.motion, const Duration(milliseconds: 220));
      expect(KachavaTokens.easeQuiet, const Cubic(0.2, 0, 0, 1));
    });

    test('test_fonts_areZenKakuDisplayAndNotoSansBody', () {
      expect(KachavaTokens.fontDisplay, 'Zen Kaku Gothic New');
      expect(KachavaTokens.fontSans, 'Noto Sans');
    });
  });
}
