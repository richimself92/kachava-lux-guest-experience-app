import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_i18n.dart';
import 'package:kachava_admin_dashboard/core/status_vocabulary.dart';
import 'package:kachava_admin_dashboard/core/theme/kachava_tokens.dart';
import 'package:kachava_admin_dashboard/presentation/components/status_chip.dart';

void main() {
  group('StatusVocabulary', () {
    test('maps wire enums to one EN/ES label and a token tone', () {
      final cases = {
        'PRE_ARRIVAL': ('Pre-arrival', 'Por llegar', StatusTone.info),
        'ACTIVE_STAY': ('In house', 'En estancia', StatusTone.success),
        'CHECKED_OUT': ('Checked out', 'Salida realizada', StatusTone.neutral),
        'OVERSTAY': ('Overstay', 'Estancia vencida', StatusTone.error),
        'MAINTENANCE': ('Maintenance', 'Mantenimiento', StatusTone.warning),
        'DISABLED': ('Disabled', 'Desactivado', StatusTone.neutral),
        'IN_PROGRESS': ('In progress', 'En curso', StatusTone.info),
        'ACTION_NEEDED': (
          'Action needed',
          'Acción pendiente',
          StatusTone.warning
        ),
        'URGENT': ('Urgent', 'Urgente', StatusTone.error),
      };
      for (final MapEntry(key: raw, value: (en, es, tone)) in cases.entries) {
        expect(StatusVocabulary.label(raw, isEs: false), en, reason: raw);
        expect(StatusVocabulary.label(raw, isEs: true), es, reason: raw);
        expect(StatusVocabulary.tone(raw), tone, reason: raw);
      }
    });

    test('accepts any casing and separators of the same status', () {
      expect(StatusVocabulary.label('in-progress', isEs: false), 'In progress');
      expect(StatusVocabulary.label('In Progress', isEs: false), 'In progress');
      expect(StatusVocabulary.label('checked_out', isEs: false), 'Checked out');
    });

    test('unknown enums are humanized, never shown raw', () {
      expect(StatusVocabulary.label('WAITING_FOR_PARTS', isEs: false),
          'Waiting for parts');
      expect(StatusVocabulary.label('', isEs: false), '—');
    });

    test('AdminI18n.statusLabel never returns a raw enum', () {
      expect(AdminI18n.statusLabel('CHECKED_OUT', false), 'Checked out');
      expect(AdminI18n.statusLabel('BOOKING', false), isNot('BOOKING'));
    });
  });

  testWidgets('StatusChip.fromStatus renders the vocabulary label, not raw',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      StatusChip.fromStatus('CHECKED_OUT', isEs: false),
      StatusChip.fromStatus('BOOKING', isEs: false),
      StatusChip.fromStatus('ACTIVE_STAY', isEs: true),
    ]))));
    expect(find.text('Checked out'), findsOneWidget);
    expect(find.text('CHECKED_OUT'), findsNothing);
    expect(find.text('BOOKING'), findsNothing);
    expect(find.text('En estancia'), findsOneWidget);
  });
}
