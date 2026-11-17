import 'package:flutter/material.dart';

import '../../core/admin_theme.dart';
import '../../domain/admin_enums.dart';
import '../components/focus_ring.dart';
import '../requests/request_inbox_scope.dart';
import 'admin_nav_model.dart';

/// Menu badge counts: new guest requests and conversations awaiting reply.
int? navBadgeFor(BuildContext context, AdminNavItem item) {
  final watcher = RequestInboxScope.maybeOf(context)?.watcher;
  if (watcher == null) return null;
  return switch (item.id) {
    'requests' => watcher.requestCount,
    'messages' => watcher.messageCount,
    _ => null,
  };
}

/// Sidebar content shared by the desktop sidebar and the mobile drawer:
/// brand header, Dashboard row, section labels and chevron items, plus a
/// square "scroll down" button while the list overflows.
class AdminNavList extends StatefulWidget {
  const AdminNavList({
    super.key,
    required this.activeTab,
    required this.isEs,
    required this.onSelect,
  });

  final AdminWorkspaceTab activeTab;
  final bool isEs;
  final ValueChanged<AdminWorkspaceTab> onSelect;

  @override
  State<AdminNavList> createState() => _AdminNavListState();
}

class _AdminNavListState extends State<AdminNavList> {
  final ScrollController _scroll = ScrollController();
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateOverflow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverflow());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _updateOverflow() {
    if (!mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    final canScroll =
        p.hasContentDimensions && p.pixels < p.maxScrollExtent - 1;
    if (canScroll != _canScrollDown) setState(() => _canScrollDown = canScroll);
  }

  void _scrollDown() {
    final p = _scroll.position;
    final target = (p.pixels + p.viewportDimension * 0.8)
        .clamp(p.minScrollExtent, p.maxScrollExtent);
    _scroll.animateTo(target,
        duration: KachavaTokens.motion, curve: KachavaTokens.easeQuiet);
  }

  @override
  Widget build(BuildContext context) {
    final selected = AdminNavModel.itemForWorkspace(widget.activeTab);
    final watcher = RequestInboxScope.maybeOf(context)?.watcher;
    return ListenableBuilder(
      listenable: watcher ?? const AlwaysStoppedAnimation<int>(0),
      builder: (context, _) => _content(selected),
    );
  }

  Widget _content(AdminNavItem? selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminNavHeader(),
        Expanded(
          child: Stack(
            children: [
              NotificationListener<ScrollMetricsNotification>(
                onNotification: (_) {
                  _updateOverflow();
                  return false;
                },
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
                  children: [
                    for (final item in AdminNavModel.topItems)
                      _item(item, selected),
                    for (final section in AdminNavModel.visibleSections()) ...[
                      _SectionLabel(section.label(widget.isEs)),
                      for (final item in section.items) _item(item, selected),
                    ],
                  ],
                ),
              ),
              if (_canScrollDown) _scrollDownButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scrollDownButton() => Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: IconButton.outlined(
            key: const Key('sidebar-scroll-down'),
            tooltip: widget.isEs ? 'Desplazar abajo' : 'Scroll down',
            style: IconButton.styleFrom(
              backgroundColor: KachavaTokens.surface,
              foregroundColor: KachavaTokens.ink,
              side: const BorderSide(color: KachavaTokens.lineStrong),
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(KachavaTokens.radius))),
            ),
            onPressed: _scrollDown,
            icon: const Icon(Icons.arrow_downward, size: 20),
          ),
        ),
      );

  Widget _item(AdminNavItem item, AdminNavItem? selected) => AdminNavTile(
        item: item,
        isEs: widget.isEs,
        selected: item.id == selected?.id,
        badge: navBadgeFor(context, item),
        onTap: () => widget.onSelect(item.workspace!),
      );
}

/// "KACHAVA LUX" wordmark + "COMMAND CENTER" `klLabel`, hairline below.
class AdminNavHeader extends StatelessWidget {
  const AdminNavHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: KachavaTokens.line)),
      ),
      child: const Row(
        children: [
          // The wordmark is never ellipsized: it scales down only if the
          // sidebar is narrower than the mockup's 300px.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'KACHAVA LUX',
                maxLines: 1,
                softWrap: false,
                style: KachavaTextStyles.wordmark,
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'COMMAND CENTER',
            maxLines: 1,
            softWrap: false,
            style: KachavaAdminTheme.klLabel,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Semantics(
        header: true,
        child: Text(text.toUpperCase(), style: KachavaAdminTheme.klLabel),
      ),
    );
  }
}

/// One menu row: optional icon (Dashboard), label, muted chevron. Selected =
/// wash background + 1px brand rule on the left edge, square corners.
class AdminNavTile extends StatelessWidget {
  const AdminNavTile({
    super.key,
    required this.item,
    required this.isEs,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final AdminNavItem item;
  final bool isEs;
  final bool selected;
  final VoidCallback onTap;

  /// Count bubble (hidden when null or 0).
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: selected,
        button: true,
        child: FocusRing(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: Key('nav-tab-${item.workspace!.id}'),
              onTap: onTap,
              child: Ink(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: _decoration,
                child: _row(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration get _decoration => BoxDecoration(
        color: selected ? KachavaTokens.wash : null,
        border: Border(
          left: BorderSide(
              color: selected ? KachavaTokens.brand : Colors.transparent),
        ),
      );

  Widget _row(BuildContext context) {
    final isDashboard = AdminNavModel.topItems.any((i) => i.id == item.id);
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: KachavaTextStyles.navSize,
          fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          color: KachavaTokens.ink,
        );
    return Row(
      children: [
        if (isDashboard && item.icon != null) ...[
          Icon(item.icon, size: 20, color: KachavaTokens.ink),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(item.label(isEs),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
        if ((badge ?? 0) > 0)
          NavCountBadge(key: Key('nav-badge-${item.id}'), count: badge!),
        if (!isDashboard)
          const Icon(Icons.chevron_right, size: 18, color: KachavaTokens.muted),
      ],
    );
  }
}

/// Count of a menu item as a plain tabular number: pending when there is
/// something to attend, muted otherwise. No pill.
class NavCountBadge extends StatelessWidget {
  const NavCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: count > 0 ? KachavaTokens.pending : KachavaTokens.muted,
              fontFeatures: KachavaTextStyles.tabular,
            ),
      ),
    );
  }
}
