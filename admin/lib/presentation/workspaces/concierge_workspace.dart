import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../domain/admin_entities.dart';
import '../../domain/admin_enums.dart';
import '../widgets/semantic_status_badge.dart';

/// Tab 5: `admin-concierge` — 24/7 Concierge Dispatch, 4-Stage Lifecycle & Live Host Chat (FR-18).
class ConciergeWorkspace extends StatefulWidget {
  const ConciergeWorkspace({super.key, required this.controller});
  final AdminDashboardController controller;

  @override
  State<ConciergeWorkspace> createState() => _ConciergeWorkspaceState();
}

class _ConciergeWorkspaceState extends State<ConciergeWorkspace> {
  final Map<String, TextEditingController> _replyControllers = {};

  TextEditingController _controllerFor(String requestId) =>
      _replyControllers.putIfAbsent(requestId, () => TextEditingController());

  void _pruneStaleControllers() {
    final activeIds =
        widget.controller.conciergeTickets.map((t) => t.requestId).toSet();
    final staleIds =
        _replyControllers.keys.where((id) => !activeIds.contains(id)).toList();
    for (final id in staleIds) {
      _replyControllers.remove(id)?.dispose();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _replyControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pruneStaleControllers();
    final tickets = widget.controller.filteredConciergeTickets;
    final lightboxId = widget.controller.activeLightboxTicketId;
    final isEs = widget.controller.isEs;
    return ListView(
      key: const Key('workspace-admin-concierge'),
      padding: const EdgeInsets.all(20),
      children: [
        AdminSectionHeader(
          eyebrow: AdminI18n.tr(
            isEs,
            '24/7 CONCIERGE DISPATCH & LIVE CHAT · FR-18',
            'CONCIERGE 24/7 Y CHAT EN VIVO · FR-18',
          ),
          title: AdminI18n.conciergeTitle(isEs),
        ),
        const SizedBox(height: 14),
        _buildStageFilterRow(isEs),
        if (lightboxId != null) ...[
          const SizedBox(height: 14),
          _buildPhotoLightbox(lightboxId),
        ],
        const SizedBox(height: 16),
        if (tickets.isEmpty)
          AdminEmptyStateBox(
            message: AdminI18n.tr(
              isEs,
              'No active 24/7 concierge or chat requests yet. Guest messages and maintenance tickets will appear here live.',
              'No hay solicitudes de concierge ni mensajes de chat activos. Los mensajes del huésped aparecerán aquí en vivo.',
            ),
          )
        else
          ...tickets.map((t) => _buildTicketCard(t, isEs)),
      ],
    );
  }

  Widget _buildStageFilterRow(bool isEs) {
    final ctrl = widget.controller;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
              label: Text(AdminI18n.tr(isEs, 'All Stages', 'Todas las Etapas')),
              selected: ctrl.conciergeStageFilter == null,
              onSelected: (_) => ctrl.setConciergeFilters(clearStage: true)),
        ),
        ...ConciergeStage.values.map((stage) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
                key: Key('filter-stage-${stage.label}'),
                label: Text(AdminI18n.statusLabel(stage.label, isEs)),
                selected: ctrl.conciergeStageFilter == stage,
                onSelected: (_) => ctrl.setConciergeFilters(stage: stage)))),
      ]),
    );
  }

  Widget _buildPhotoLightbox(String requestId) {
    final ticket = widget.controller.conciergeTickets.firstWhere(
      (t) => t.requestId == requestId,
      orElse: () => widget.controller.conciergeTickets.first,
    );
    return Container(
      key: const Key('maintenance-photo-lightbox'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KachavaAdminColors.obsidian,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'FIREBASE CLOUD STORAGE · V4 SIGNED GET PHOTO INSPECTOR',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: KachavaAdminColors.copalGold),
                ),
              ),
              IconButton(
                key: const Key('close-photo-lightbox'),
                tooltip: 'Close photo inspector',
                onPressed: () => widget.controller.setLightboxTicket(null),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          Text('Path: ${ticket.photoStoragePath ?? "N/A"}',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 4),
          Text('Signed V4 URL: ${ticket.signedPhotoGetUrl ?? "N/A"}',
              style: const TextStyle(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTicketCard(AdminConciergeTicket ticket, bool isEs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KachavaAdminColors.borderLimestone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTicketHeader(ticket, isEs),
          const SizedBox(height: 10),
          _buildStageStepper(ticket, isEs),
          const SizedBox(height: 12),
          _buildChatMessagesList(ticket),
          const SizedBox(height: 10),
          _buildChatReplyInput(ticket, isEs),
        ],
      ),
    );
  }

  Widget _buildTicketHeader(AdminConciergeTicket ticket, bool isEs) {
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${ticket.title} · ${ticket.villaName}',
            style: const TextStyle(
                fontFamily: 'Libre Baskerville',
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${ticket.details} (${ticket.assignedStaffName})',
            style: const TextStyle(
                fontSize: 12, color: KachavaAdminColors.neutralMuted)),
      ],
    );
    final actionsWrap = Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (ticket.hasPhoto)
          OutlinedButton.icon(
            key: Key('open-photo-lightbox-${ticket.requestId}'),
            onPressed: () =>
                widget.controller.setLightboxTicket(ticket.requestId),
            icon: const Icon(Icons.photo_camera_outlined, size: 15),
            label: Text(AdminI18n.tr(isEs, 'Inspect Photo', 'Ver Foto')),
          ),
        SemanticStatusBadge(label: ticket.stage.label),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 480
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleColumn, const SizedBox(height: 8), actionsWrap])
          : Row(children: [
              Expanded(child: titleColumn),
              const SizedBox(width: 8),
              actionsWrap
            ]),
    );
  }

  Widget _buildStageStepper(AdminConciergeTicket ticket, bool isEs) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: ConciergeStage.values
          .map((stage) => ChoiceChip(
                key: Key('stage-btn-${ticket.requestId}-${stage.label}'),
                label: Text(
                    '${stage.step}. ${AdminI18n.statusLabel(stage.label, isEs)}'),
                selected: ticket.stage == stage,
                onSelected: (_) =>
                    widget.controller.advanceConciergeTicketStage(
                  requestId: ticket.requestId,
                  targetStage: stage,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildChatMessagesList(AdminConciergeTicket ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: ticket.messages.map((msg) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: msg.isStaff
                ? KachavaAdminColors.canvasLow
                : KachavaAdminColors.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${msg.senderName} (${msg.senderRole}) · ${msg.timestampLabel}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: KachavaAdminColors.mutedBronze)),
              const SizedBox(height: 3),
              Text(msg.body,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submitReply(
      String requestId, TextEditingController textCtrl) async {
    final msg = textCtrl.text.trim();
    if (msg.isEmpty) return;
    textCtrl.clear();
    await widget.controller
        .sendConciergeHostReply(requestId: requestId, messageText: msg);
  }

  Widget _buildChatReplyInput(AdminConciergeTicket ticket, bool isEs) {
    final textCtrl = _controllerFor(ticket.requestId);
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: Key('chat-input-${ticket.requestId}'),
            controller: textCtrl,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submitReply(ticket.requestId, textCtrl),
            decoration: InputDecoration(
              hintText: AdminI18n.tr(isEs, 'Reply as HOST ADMIN...',
                  'Responder como HOST ADMIN...'),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 14.5),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          key: Key('chat-send-${ticket.requestId}'),
          style: ElevatedButton.styleFrom(
              backgroundColor: KachavaAdminColors.zapotePrimary,
              foregroundColor: Colors.white),
          onPressed: () => _submitReply(ticket.requestId, textCtrl),
          child: Text(AdminI18n.tr(isEs, 'Send Reply', 'Enviar')),
        ),
      ],
    );
  }
}
