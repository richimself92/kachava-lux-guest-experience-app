import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../core/responsive_breakpoints.dart';
import '../../domain/admin_enums.dart';
import '../components/focus_ring.dart';

/// White 64px top bar: page title, EN|ES toggle, alert bell and the
/// Settings gear. No global search or filters: each list has its own toolbar.
/// Mobile adds the drawer menu button.
class TopCommandBar extends StatelessWidget {
  static const TextTheme _text = KachavaAdminTheme.textTheme;

  const TopCommandBar({
    super.key,
    required this.controller,
    this.showMenuButton = false,
  });

  final AdminDashboardController controller;

  /// Shows the menu button that opens the mobile navigation drawer.
  final bool showMenuButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AdminBreakpoints.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: KachavaTokens.background,
        border: Border(bottom: BorderSide(color: KachavaTokens.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;
          final gap = isCompact ? 2.0 : 8.0;
          return Row(
            children: [
              if (showMenuButton)
                IconButton(
                  key: const Key('mobile-nav-menu-button'),
                  tooltip: AdminI18n.tr(controller.isEs, 'Menu', 'Menú'),
                  icon: const Icon(Icons.menu, color: KachavaTokens.text),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              Expanded(child: _buildTitle()),
              SizedBox(width: gap),
              _buildLocaleToggleButton(isCompact),
              SizedBox(width: gap),
              _buildNotificationBell(isCompact),
              _buildSettingsButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsButton() {
    final selected = controller.activeTab == AdminWorkspaceTab.adminSettings;
    return IconButton(
      key: const Key('top-bar-settings'),
      tooltip:
          AdminI18n.tabLabel(AdminWorkspaceTab.adminSettings, controller.isEs),
      isSelected: selected,
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        backgroundColor: selected ? KachavaTokens.surface : null,
      ),
      icon: const Icon(Icons.settings_outlined, color: KachavaTokens.text),
      onPressed: () => controller.selectTab(AdminWorkspaceTab.adminSettings),
    );
  }

  Widget _buildTitle() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          AdminI18n.tabLabel(controller.activeTab, controller.isEs),
          key: const Key('top-bar-page-title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 20,
              height: 28 / 20,
              fontWeight: FontWeight.w500,
              color: KachavaTokens.text),
        ),
      ),
    );
  }

  /// Neutral gray pill (or [background]).
  ///
  /// The visible pill stays compact, but its tap target is at least 48dp
  /// (DESIGN.md) and keyboard focus draws the shared [FocusRing].
  Widget _pill({
    required Key key,
    required Widget child,
    required VoidCallback onTap,
    Color? background,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  }) {
    final radius = BorderRadius.circular(KachavaTokens.radiusPill);
    return FocusRing(
      borderRadius: KachavaTokens.radiusPill,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: key,
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Ink(
                padding: padding,
                decoration: BoxDecoration(
                  color: background ?? KachavaTokens.surface,
                  borderRadius: radius,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocaleToggleButton(bool isCompact) {
    final isEs = controller.isEs;
    return Semantics(
      button: true,
      label: isEs ? 'ES | EN' : 'EN | ES',
      child: _pill(
        key: const Key('admin-locale-toggle-btn'),
        padding: const EdgeInsets.all(2),
        onTap: controller.toggleLocale,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLocaleSegment(!isEs ? '✓ EN' : 'EN', !isEs, isCompact),
            _buildLocaleSegment(isEs ? '✓ ES' : 'ES', isEs, isCompact),
          ],
        ),
      ),
    );
  }

  Widget _buildLocaleSegment(String label, bool active, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 5 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? KachavaTokens.background : Colors.transparent,
        borderRadius: BorderRadius.circular(KachavaTokens.radiusPill),
      ),
      child: Text(
        label,
        style: _text.labelMedium?.copyWith(
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? KachavaTokens.text : KachavaTokens.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNotificationBell(bool isCompact) {
    final unread = controller.unreadAlertsCount;
    final tone = unread > 0 ? StatusTone.error : StatusTone.neutral;
    final label = AdminI18n.tr(
        controller.isEs,
        'Unread operational alerts: $unread',
        'Alertas operativas sin leer: $unread');
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: _pill(
          key: const Key('top-bar-alert-bell'),
          background: tone.background,
          padding:
              EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10, vertical: 6),
          onTap: () => controller.selectTab(AdminWorkspaceTab.adminOverview),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none, size: 16, color: tone.foreground),
              const SizedBox(width: 4),
              Text(
                '$unread',
                key: const Key('unread-alerts-badge'),
                style: _text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: tone.foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
