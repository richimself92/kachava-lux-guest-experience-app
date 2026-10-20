import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../domain/entities/concierge_folio_entities.dart';

/// Screen 9: 24/7 Dedicated Concierge & 4-Stage Tracker (`concierge`).
class ConciergeScreen extends StatefulWidget {
  const ConciergeScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  State<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends State<ConciergeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final String _selectedCategory = 'Maintenance';
  bool _attachPhoto = false;

  @override
  void dispose() {
    _titleController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final text = _titleController.text.trim();
    if (text.isEmpty) return;
    await widget.controller.createConciergeRequest(
      title: text,
      category: _selectedCategory,
      details: text,
      photoUrl: _attachPhoto
          ? 'https://storage.googleapis.com/kachava-lux/villa102/issue.jpg'
          : null,
    );
    if (!mounted) return;
    _titleController.clear();
    setState(() => _attachPhoto = false);
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    widget.controller.sendChatMessage(text);
    _chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('screen-concierge'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 84),
      children: [
        _buildMajordomoHeaderCard(),
        const SizedBox(height: 12),
        _buildCreateTicketCard(),
        const SizedBox(height: 12),
        _buildRequestsTrackerSection(),
        const SizedBox(height: 12),
        _buildLiveChatThreadCard(),
      ],
    );
  }

  Widget _buildMajordomoHeaderCard() {
    final i18n = widget.controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
                backgroundColor: KachavaColors.primary,
                child: Icon(Icons.support_agent, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.controller.stay.privateHostName,
                      style: const TextStyle(
                          fontFamily: KachavaTheme.serifFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: KachavaColors.primary)),
                  Text(
                      i18n.t('24/7 Dedicated Concierge · Available on WhatsApp',
                          'Atención 24/7 y Chat · Disponible en WhatsApp'),
                      style: const TextStyle(
                          fontSize: 11.5, color: KachavaColors.confirmedGreen)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTicketCard() {
    final i18n = widget.controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                i18n.t('CREATE SERVICE OR MAINTENANCE REQUEST',
                    'CREAR SOLICITUD DE SERVICIO O MANTENIMIENTO'),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: KachavaColors.secondary)),
            const SizedBox(height: 8),
            TextField(
              key: const Key('concierge-request-input'),
              controller: _titleController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitRequest(),
              decoration: InputDecoration(
                  hintText: i18n.t(
                      'Describe your request...', 'Describe tu solicitud...')),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  key: const Key('concierge-attach-photo-chip'),
                  label: Text(i18n.t('Attach Photo', 'Adjuntar Foto'),
                      style: const TextStyle(fontSize: 11)),
                  selected: _attachPhoto,
                  onSelected: (v) => setState(() => _attachPhoto = v),
                ),
                ElevatedButton(
                  key: const Key('concierge-submit-request-btn'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: KachavaColors.primary,
                      foregroundColor: Colors.white),
                  onPressed: _submitRequest,
                  child:
                      Text(i18n.t('Send to HOST ADMIN', 'Enviar a HOST ADMIN')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTrackerSection() {
    final i18n = widget.controller.i18n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(i18n.t('REQUEST STATUS TRACKER', 'SEGUIMIENTO DE SOLICITUDES'),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: KachavaColors.secondary)),
        const SizedBox(height: 8),
        ...widget.controller.conciergeRequests.map(_buildRequestCard),
      ],
    );
  }

  Widget _buildRequestCard(ConciergeRequest req) {
    final i18n = widget.controller.i18n;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(i18n.translateContent(req.title),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: KachavaColors.primary))),
                const SizedBox(width: 8),
                Text(i18n.optionLabel(req.stage.label),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: KachavaColors.confirmedGreen)),
              ],
            ),
            const SizedBox(height: 8),
            _buildStageProgressBar(req.currentStep),
            const SizedBox(height: 6),
            Text(
              i18n.t(
                  'Assigned to: ${req.assignedTo} · Requested -> Assigned -> In Progress -> Completed',
                  'Atendido por: ${req.assignedTo} · Solicitado -> Asignado -> En Proceso -> Completado'),
              style: const TextStyle(
                  fontSize: 10, color: KachavaColors.mutedMetadata),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageProgressBar(int currentStep) {
    return Row(
      children: List.generate(4, (i) {
        final color = i < currentStep
            ? KachavaColors.primary
            : KachavaColors.surfaceContainerHighest;
        return Expanded(
          child: Container(
              height: 5,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4))),
        );
      }),
    );
  }

  Widget _buildLiveChatThreadCard() {
    final i18n = widget.controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                i18n.t(
                    'LIVE CHAT WITH HOST ADMIN', 'CHAT EN VIVO CON HOST ADMIN'),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: KachavaColors.secondary)),
            const SizedBox(height: 8),
            ...widget.controller.chatMessages.map(_buildChatBubble),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('concierge-chat-input'),
                    controller: _chatController,
                    style: const TextStyle(fontSize: 15),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendChat(),
                    decoration: InputDecoration(
                        hintText: i18n.t('Message HOST ADMIN...',
                            'Mensaje a HOST ADMIN...')),
                  ),
                ),
                IconButton(
                    key: const Key('concierge-chat-send-btn'),
                    tooltip: 'Send message to concierge',
                    onPressed: _sendChat,
                    icon: const Icon(Icons.send, color: KachavaColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final i18n = widget.controller.i18n;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: msg.isFromHost
            ? KachavaColors.surfaceContainerLow
            : KachavaColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg.senderName,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.primary)),
          const SizedBox(height: 3),
          Text(i18n.translateContent(msg.text),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: KachavaColors.onSurface)),
        ],
      ),
    );
  }
}
