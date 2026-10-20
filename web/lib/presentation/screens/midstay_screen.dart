import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Screen 10: Proactive Mid-Stay Check-In (`midstay`).
class MidStayScreen extends StatefulWidget {
  const MidStayScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  State<MidStayScreen> createState() => _MidStayScreenState();
}

class _MidStayScreenState extends State<MidStayScreen> {
  int _pulseRating = 5;
  String _sentimentId = 'tuned';
  bool _priorityCallback = true;
  final TextEditingController _notesController = TextEditingController(
    text: '',
  );

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitMidStay() async {
    await widget.controller.submitMidStayCheckIn(
      rating: _pulseRating,
      sentimentId: _sentimentId,
      housekeepingWindow: widget.controller.preferences.housekeepingCadence,
      focusAreas: const ['Pool Terrace Plunge Heat', 'Villa Climate'],
      notes: _notesController.text,
      requestPriorityCallback: _priorityCallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final guestName = widget.controller.stay.primaryGuestName;
    final i18n = widget.controller.i18n;
    final submitted = widget.controller.latestMidStayCheckIn;
    return ListView(
      key: const Key('screen-midstay'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 84),
      children: [
        Text(
          i18n.t('MID-STAY CHECK-IN', 'CALIFICA TU ESTANCIA'),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: KachavaColors.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          i18n.t('How Is Your Stay Going, $guestName?',
              '¿Cómo va tu estancia, $guestName?'),
          style: const TextStyle(
            fontFamily: KachavaTheme.serifFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: KachavaColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        if (submitted != null)
          _buildSubmittedSummaryCard(submitted)
        else ...[
          _buildRatingRow(),
          const SizedBox(height: 12),
          _buildSentimentCards(),
          const SizedBox(height: 12),
          _buildRefinementCard(),
          const SizedBox(height: 14),
          ElevatedButton(
            key: const Key('midstay-submit-btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KachavaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _submitMidStay,
            child: Text(i18n.t('SHARE WITH HOST ADMIN (< 7 MIN SLA) →',
                'COMPARTIR CON HOST ADMIN →')),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmittedSummaryCard(dynamic submitted) {
    final i18n = widget.controller.i18n;
    final stars = '★' * (submitted.rating as int);
    return Card(
      key: const Key('midstay-submitted-summary-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t(
                '✓ Stay Feedback Survey Submitted',
                '✓ Encuesta de Estancia Enviada',
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: KachavaColors.confirmedGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${i18n.t("Rating", "Calificación")}: ${submitted.rating} $stars',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: KachavaColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${i18n.t("Sentiment", "Experiencia")}: ${submitted.sentimentId}',
              style: const TextStyle(fontSize: 12),
            ),
            if ((submitted.notes as String).trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${i18n.t("Note", "Comentario")}: ${submitted.notes}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow() {
    final i18n = widget.controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t('SATISFACTION RATING (1–5)',
                  'CALIFICACIÓN GENERAL (1 A 5 ESTRELLAS)'),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.secondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [1, 2, 3, 4, 5].map((score) {
                final selected = _pulseRating == score;
                return ChoiceChip(
                  key: Key('midstay-rating-$score'),
                  label: Text('$score ★', style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  onSelected: (_) => setState(() => _pulseRating = score),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentCards() {
    final i18n = widget.controller.i18n;
    final sentiments = i18n.isEs
        ? const {
            'transcendent': 'Excelente, todo perfecto',
            'serene': 'Muy agradable y tranquilo',
            'tuned': 'Hay un detalle por mejorar',
            'direct': 'Necesito atención inmediata de HOST ADMIN',
          }
        : const {
            'transcendent': 'Transcendent & Flawless',
            'serene': 'Serene & Delightful',
            'tuned': 'A Detail Could Be Tuned',
            'direct': 'Need Direct Assistance (< 7 Min Callback)',
          };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: sentiments.entries.map((entry) {
            final isSelected = _sentimentId == entry.key;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: isSelected
                    ? KachavaColors.primary
                    : KachavaColors.secondary,
              ),
              title: Text(entry.value,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
              onTap: () => setState(() => _sentimentId = entry.key),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRefinementCard() {
    final i18n = widget.controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t('PERSONAL COMMENTS & CALLBACK', 'COMENTARIOS Y ATENCIÓN'),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.secondary),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('midstay-notes-input'),
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: i18n.t(
                    'Personal Note to HOST ADMIN', 'Nota para HOST ADMIN'),
                hintText: i18n.t(
                  'e.g. Warm plunge pool by 2 degrees for evening swim',
                  'Ej. Templado de alberca o cualquier comentario sobre tu estancia',
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                i18n.t(
                  'Priority Host Callback (< 7 Min SLA)',
                  'Solicitar llamada prioritaria de HOST ADMIN',
                ),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              value: _priorityCallback,
              onChanged: (v) => setState(() => _priorityCallback = v),
            ),
          ],
        ),
      ),
    );
  }
}
