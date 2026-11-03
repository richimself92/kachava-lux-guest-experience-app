import 'package:flutter/material.dart';

import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_enums.dart';
import '../components/focus_ring.dart';
import 'admin_nav_model.dart';

/// Sidebar content shared by the desktop sidebar and the mobile drawer:
/// brand header, Dashboard row, section labels and chevron items, plus a
/// circular "scroll down" button while the list overflows.
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
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final selected = AdminNavModel.itemForWorkspace(widget.activeTab);
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
                    _item(AdminNavModel.dashboard, selected),
                    for (final section in AdminNavModel.visibleSections()) ...[
                      _SectionLabel(section.label(widget.isEs)),
                      for (final item in section.items) _item(item, selected),
                    ],
                  ],
                ),
              ),
              if (_canScrollDown)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: IconButton.outlined(
                      key: const Key('sidebar-scroll-down'),
                      tooltip: widget.isEs ? 'Desplazar abajo' : 'Scroll down',
                      style: IconButton.styleFrom(
                        backgroundColor: KachavaTokens.background,
                        foregroundColor: KachavaTokens.text,
                        side: const BorderSide(color: KachavaTokens.border),
                      ),
                      onPressed: _scrollDown,
                      icon: const Icon(Icons.arrow_downward, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _item(AdminNavItem item, AdminNavItem? selected) => AdminNavTile(
        item: item,
        isEs: widget.isEs,
        selected: item.id == selected?.id,
        onTap: () => widget.onSelect(item.workspace!),
      );
}

/// "KACHAVA LUX" + gray "COMMAND CENTER" pill with a hairline below.
class AdminNavHeader extends StatelessWidget {
  const AdminNavHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: KachavaTokens.border)),
      ),
      child: Row(
        children: [
          // The wordmark is never ellipsized: it scales down only if the
          // sidebar is narrower than the mockup's 300px.
          const Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'KACHAVA LUX',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: KachavaTokens.text),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: KachavaTokens.surface,
              borderRadius: BorderRadius.circular(KachavaTokens.radiusPill),
            ),
            child: const Text(
              'COMMAND CENTER',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                  color: KachavaTokens.text),
            ),
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
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: KachavaTokens.textSecondary),
        ),
      ),
    );
  }
}

/// One menu row: optional icon (Dashboard), label, gray chevron. Selected =
/// light-gray rounded background + bold text (never brown).
class AdminNavTile extends StatelessWidget {
  const AdminNavTile({
    super.key,
    required this.item,
    required this.isEs,
    required this.selected,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool isEs;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDashboard = item.id == AdminNavModel.dashboard.id;
    final radius = BorderRadius.circular(KachavaTokens.radiusLg);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: selected,
        button: true,
        child: FocusRing(
          borderRadius: KachavaTokens.radiusLg,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: Key('nav-tab-${item.workspace!.id}'),
              borderRadius: radius,
              onTap: onTap,
              child: Ink(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected ? KachavaTokens.surface : null,
                  borderRadius: radius,
                ),
                child: Row(
                  children: [
                    if (isDashboard && item.icon != null) ...[
                      Icon(item.icon, size: 22, color: KachavaTokens.text),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        item.label(isEs),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          height: 22 / 15,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                          color: KachavaTokens.text,
                        ),
                      ),
                    ),
                    if (!isDashboard)
                      const Icon(Icons.chevron_right,
                          size: 20, color: KachavaTokens.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
