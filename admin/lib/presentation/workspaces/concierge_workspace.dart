import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_entities.dart';
import '../../domain/admin_enums.dart';
import '../components/components.dart';
import '../widgets/semantic_status_badge.dart' show AdminEmptyStateBox;

/// `admin-concierge` — shown as "Tasks": guest requests, stages and chat.
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
      padding: const EdgeInsets.all(KachavaTokens.space6),
      children: [
        PageHeader(
          title: AdminI18n.tr(isEs, 'Tasks', 'Tareas'),
          info: AdminI18n.tr(
            isEs,
            'Guest requests and maintenance, handled by the Resort Host team in four stages, with live chat.',
            'Solicitudes y mantenimiento, atendidos por el equipo de Resort Host en cuatro etapas, con chat en vivo.',
          ),
        ),
        const SizedBox(height: KachavaTokens.space4),
        _buildStageFilterRow(isEs),
        if (lightboxId != null) ...[
          const SizedBox(height: KachavaTokens.space4),
          _buildPhotoLightbox(context, lightboxId, isEs),
        ],
        const SizedBox(height: KachavaTokens.space4),
        if (tickets.isEmpty)
          AdminEmptyStateBox(
            message: AdminI18n.tr(
                isEs, 'No open requests.', 'No hay solicitudes abiertas.'),
          )
        else
          ...tickets.map((t) => _buildTicketCard(context, t, isEs)),
      ],
    );
  }

  Widget _buildStageFilterRow(bool isEs) {
    final ctrl = widget.controller;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.only(right: KachavaTokens.space2),
          child: ChoiceChip(
              label: Text(AdminI18n.tr(isEs, 'All', 'Todas')),
              selected: ctrl.conciergeStageFilter == null,
              onSelected: (_) => ctrl.setConciergeFilters(clearStage: true)),
        ),
        ...ConciergeStage.values.map((stage) => Padding(
            padding: const EdgeInsets.only(right: KachavaTokens.space2),
            child: ChoiceChip(
                key: Key('filter-stage-${stage.label}'),
                label: Text(AdminI18n.statusLabel(stage.label, isEs)),
                selected: ctrl.conciergeStageFilter == stage,
                onSelected: (_) => ctrl.setConciergeFilters(stage: stage)))),
      ]),
    );
  }

  Widget _buildPhotoLightbox(
      BuildContext context, String requestId, bool isEs) {
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final ticket = widget.controller.conciergeTickets.firstWhere(
      (t) => t.requestId == requestId,
      orElse: () => widget.controller.conciergeTickets.first,
    );
    return Container(
      key: const Key('maintenance-photo-lightbox'),
      padding: const EdgeInsets.all(KachavaTokens.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KachavaTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AdminI18n.tr(isEs, 'Photo', 'Foto'),
                    style: theme.textTheme.titleLarge),
              ),
              IconButton(
                key: const Key('close-photo-lightbox'),
                tooltip: AdminI18n.tr(isEs, 'Close', 'Cerrar'),
                onPressed: () => widget.controller.setLightboxTicket(null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          SelectableText(
              '${AdminI18n.tr(isEs, 'Path', 'Ruta')}: ${AdminI18n.orDash(ticket.photoStoragePath ?? '')}',
              style: secondary),
          const SizedBox(height: KachavaTokens.space1),
          SelectableText(
              'URL: ${AdminI18n.orDash(ticket.signedPhotoGetUrl ?? '')}',
              style: secondary),
        ],
      ),
    );
  }

  Widget _buildTicketCard(
      BuildContext context, AdminConciergeTicket ticket, bool isEs) {
    return Container(
      margin: const EdgeInsets.only(bottom: KachavaTokens.space4),
      padding: const EdgeInsets.all(KachavaTokens.space4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KachavaTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTicketHeader(context, ticket, isEs),
          const SizedBox(height: KachavaTokens.space3),
          _buildStageStepper(ticket, isEs),
          const SizedBox(height: KachavaTokens.space3),
          _buildChatMessagesList(context, ticket),
          const SizedBox(height: KachavaTokens.space2),
          _buildChatReplyInput(ticket, isEs),
        ],
      ),
    );
  }

  Widget _buildTicketHeader(
      BuildContext context, AdminConciergeTicket ticket, bool isEs) {
    final theme = Theme.of(context);
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            '${AdminI18n.orDash(ticket.title)} · ${AdminI18n.orDash(ticket.villaName)}',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: KachavaTokens.space1),
        Text(
            '${ticket.details} (${AdminI18n.staffLabel(ticket.assignedStaffName, isEs)})',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
    final actionsWrap = Wrap(
      spacing: KachavaTokens.space2,
      runSpacing: KachavaTokens.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (ticket.hasPhoto)
          OutlinedButton.icon(
            key: Key('open-photo-lightbox-${ticket.requestId}'),
            onPressed: () =>
                widget.controller.setLightboxTicket(ticket.requestId),
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(AdminI18n.tr(isEs, 'Photo', 'Foto')),
          ),
        StatusChip.fromStatus(ticket.stage.label),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 480
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              titleColumn,
              const SizedBox(height: KachavaTokens.space2),
              actionsWrap
            ])
          : Row(children: [
              Expanded(child: titleColumn),
              const SizedBox(width: KachavaTokens.space2),
              actionsWrap
            ]),
    );
  }

  Widget _buildStageStepper(AdminConciergeTicket ticket, bool isEs) {
    return Wrap(
      spacing: KachavaTokens.space2,
      runSpacing: KachavaTokens.space2,
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

  Widget _buildChatMessagesList(
      BuildContext context, AdminConciergeTicket ticket) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: ticket.messages.map((msg) {
        return Container(
          margin: const EdgeInsets.only(bottom: KachavaTokens.space2),
          padding: const EdgeInsets.all(KachavaTokens.space3),
          decoration: BoxDecoration(
            color: msg.isStaff
                ? theme.colorScheme.surfaceContainerLowest
                : KachavaTokens.surfaceHover,
            borderRadius: BorderRadius.circular(KachavaTokens.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${msg.senderName} (${msg.senderRole}) · ${msg.timestampLabel}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: KachavaTokens.space1),
              Text(msg.body, style: theme.textTheme.bodyMedium),
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
              hintText: AdminI18n.tr(
                  isEs, 'Reply as Resort Host', 'Responder como Resort Host'),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: KachavaTokens.space2),
        ElevatedButton(
          key: Key('chat-send-${ticket.requestId}'),
          onPressed: () => _submitReply(ticket.requestId, textCtrl),
          child: Text(AdminI18n.tr(isEs, 'Send', 'Enviar')),
        ),
      ],
    );
  }
}
