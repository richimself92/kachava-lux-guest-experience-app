import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/portal_controller.dart';
import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../domain/catalog.dart';
import '../common/widgets.dart';
import 'service_actions.dart';

/// Bottom sheet on phones, 480px side panel from 640px. Esc / swipe closes.
Future<void> showServiceDetail(
    BuildContext context, PortalController c, CatalogService s) {
  final wide = MediaQuery.sizeOf(context).width >= 640;
  Widget sheet(BuildContext _) =>
      ServiceDetail(controller: c, service: s, hostContext: context);
  if (!wide) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: KachavaColors.surface,
      builder: (ctx) =>
          FractionallySizedBox(heightFactor: 0.92, child: sheet(ctx)),
    );
  }
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: c.l10n.close,
    pageBuilder: (ctx, _, __) => Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: KachavaColors.surface,
        child: SizedBox(
            width: 480,
            height: double.infinity,
            child: SafeArea(child: sheet(ctx))),
      ),
    ),
  );
}

class ServiceDetail extends StatefulWidget {
  const ServiceDetail({
    super.key,
    required this.controller,
    required this.service,
    required this.hostContext,
  });

  final PortalController controller;
  final CatalogService service;

  /// Context below the sheet, used to push the form after closing.
  final BuildContext hostContext;

  @override
  State<ServiceDetail> createState() => _ServiceDetailState();
}

class _ServiceDetailState extends State<ServiceDetail> {
  final PageController _pages = PageController();
  int _photo = 0;
  bool _more = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index, int count) {
    if (index < 0 || index >= count) return;
    _pages.animateToPage(index,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _primary() {
    final host = widget.hostContext;
    final c = widget.controller;
    final s = widget.service;
    Navigator.of(context).pop();
    openServiceForm(host, c, s);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.controller.l10n;
    final s = widget.service;
    final photos = s.photos;
    final reason = disabledReason(l10n, s);
    final summary = l10n.text(s.description).isNotEmpty
        ? l10n.text(s.description)
        : l10n.text(s.shortDescription);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _go(_photo + 1, photos.length),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _go(_photo - 1, photos.length),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          key: Key('service-detail-${s.id}'),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: l10n.close,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (photos.isNotEmpty) _gallery(l10n, photos),
                  const SizedBox(height: 12),
                  Text(l10n.text(s.name),
                      style: const TextStyle(
                          fontFamily: KachavaTheme.serifFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: KachavaColors.primary)),
                  const SizedBox(height: 8),
                  ServiceChips(l10n: l10n, service: s),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(summary,
                        maxLines: _more ? null : 3,
                        overflow: _more ? null : TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, color: KachavaColors.onSurface)),
                    if (!_more && summary.length > 140)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                            onPressed: () => setState(() => _more = true),
                            child: Text(l10n.more)),
                      ),
                  ],
                  ..._accordions(l10n, s),
                ],
              ),
            ),
            StickyAction(
              top: reason == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(reason,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14,
                              color: KachavaColors.onSurfaceVariant)),
                    ),
              child: FilledButton(
                key: const Key('detail-primary'),
                onPressed: reason == null ? _primary : null,
                child: Text(primaryLabel(l10n, s.usageType)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gallery(L10n l10n, List<CatalogImage> photos) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _photo = i),
                children: [
                  for (final p in photos) ServicePhoto(image: p, l10n: l10n)
                ],
              ),
              if (photos.length > 1)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: KachavaColors.onSurface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(l10n.photoOf(_photo + 1, photos.length),
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
        if (photos.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: l10n.back,
                onPressed:
                    _photo > 0 ? () => _go(_photo - 1, photos.length) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              for (var i = 0; i < photos.length; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _photo
                        ? KachavaColors.primary
                        : KachavaColors.outline,
                  ),
                ),
              IconButton(
                tooltip: l10n.nextPage,
                onPressed: _photo < photos.length - 1
                    ? () => _go(_photo + 1, photos.length)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }

  List<Widget> _accordions(L10n l10n, CatalogService s) {
    final info = s.guestInfo;
    final meeting = l10n.text(s.meetingPoint).isNotEmpty
        ? l10n.text(s.meetingPoint)
        : l10n.text(info.location);
    final rules = [
      l10n.text(info.restrictions),
      l10n.text(info.cancellationPolicy)
    ].where((t) => t.isNotEmpty).join('\n');
    final sections = [
      (l10n.includes, l10n.text(info.includes)),
      (l10n.bring, l10n.text(info.whatToBring)),
      (l10n.meetingPoint, meeting),
      (l10n.rules, rules),
    ].where((e) => e.$2.isNotEmpty);
    return [
      for (final (title, body) in sections)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          expandedAlignment: Alignment.centerLeft,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: [
            Text(body,
                style: const TextStyle(
                    fontSize: 15, color: KachavaColors.onSurface))
          ],
        ),
    ];
  }
}

/// Price chip + lead time chip.
class ServiceChips extends StatelessWidget {
  const ServiceChips({super.key, required this.l10n, required this.service});
  final L10n l10n;
  final CatalogService service;

  @override
  Widget build(BuildContext context) {
    final lead = l10n.leadTime(service.availability.minLeadHours);
    Widget chip(String text, {Key? key}) => Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: KachavaColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(text,
              style: const TextStyle(
                  fontSize: 14, color: KachavaColors.onSurface)),
        );
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        chip(l10n.price(service.pricing, service.itemPriceRange),
            key: Key('price-${service.id}')),
        if (lead.isNotEmpty) chip(lead),
      ],
    );
  }
}
