import 'package:flutter/material.dart';
import '../../application/admin_shell_controller.dart';
import '../../application/notification_bell_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/ops_strings.dart';
import '../../core/admin_theme.dart';
import '../../core/responsive_breakpoints.dart';
import '../../domain/admin_enums.dart';
import '../components/focus_ring.dart';
import 'admin_refresh_button.dart';

/// Paper 64px top bar: page title, EN|ES toggle, Refresh, alert bell and
/// the Settings gear. No global search or filters: each list has its own toolbar.
/// Mobile adds the drawer menu button.
class TopCommandBar extends StatelessWidget {
  static final TextTheme _text = KachavaTextStyles.textTheme(inputSize: 14);

  const TopCommandBar({
    super.key,
    required this.controller,
    required this.bell,
    this.showMenuButton = false,
    this.onRefresh,
  });

  final AdminShellController controller;

  /// Unread notification counters (refreshed by real-time signals).
  final NotificationBellController bell;

  /// Shows the menu button that opens the mobile navigation drawer.
  final bool showMenuButton;

  /// Refreshes the bell and every open screen (shows the Refresh button).
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AdminBreakpoints.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: KachavaTokens.paper,
        border: Border(bottom: BorderSide(color: KachavaTokens.line)),
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
                  icon: const Icon(Icons.menu, color: KachavaTokens.ink),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              Expanded(child: _buildTitle()),
              SizedBox(width: gap),
              _buildLocaleToggleButton(isCompact),
              SizedBox(width: gap),
              if (onRefresh != null)
                AdminRefreshButton(
                    onRefresh: onRefresh!, isEs: controller.isEs),
              ListenableBuilder(
                listenable: bell,
                builder: (context, _) => _buildNotificationBell(isCompact),
              ),
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
        backgroundColor: selected ? KachavaTokens.wash : null,
      ),
      icon: const Icon(Icons.settings_outlined, color: KachavaTokens.ink),
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
          style: _text.titleLarge?.copyWith(color: KachavaTokens.ink),
        ),
      ),
    );
  }

  /// Quiet square control (no fill unless [background]); hover is wash.
  ///
  /// The visible control stays compact, but its tap target is at least 48dp
  /// (DESIGN.md) and keyboard focus draws the shared [FocusRing].
  Widget _pill({
    required Key key,
    required Widget child,
    required VoidCallback onTap,
    Color? background,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  }) {
    final radius = BorderRadius.circular(KachavaTokens.radius);
    return FocusRing(
      borderRadius: KachavaTokens.radius,
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
                  color: background,
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
      // Text-only switch: the selected language is ink with an ink rule.
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: active ? KachavaTokens.ink : Colors.transparent),
        ),
      ),
      child: Text(
        label,
        style: _text.labelMedium?.copyWith(
          color: active ? KachavaTokens.ink : KachavaTokens.muted,
        ),
      ),
    );
  }

  Widget _buildNotificationBell(bool isCompact) {
    final unread = bell.unread;
    // Plain tabular count: danger/pending when something needs attention.
    final tone = bell.counts.urgentUnread > 0
        ? StatusTone.error
        : unread > 0
            ? StatusTone.warning
            : StatusTone.neutral;
    final label = '${OpsStrings(controller.isEs).bellLabelPrefix}: $unread';
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: _pill(
          key: const Key('top-bar-alert-bell'),
          padding:
              EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10, vertical: 6),
          onTap: () =>
              controller.selectTab(AdminWorkspaceTab.adminNotifications),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none, size: 16, color: tone.foreground),
              const SizedBox(width: 4),
              Text(
                '$unread',
                key: const Key('unread-alerts-badge'),
                style: _text.labelMedium?.copyWith(
                    color: tone.foreground,
                    fontFeatures: KachavaTextStyles.tabular),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
