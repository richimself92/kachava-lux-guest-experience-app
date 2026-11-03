import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../core/responsive_breakpoints.dart';
import '../../domain/admin_enums.dart';
import '../components/focus_ring.dart';

/// White 64px top bar: page title, search, quick filters, test chime,
/// EN|ES toggle and alert bell. Mobile adds the drawer menu button.
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
              if (constraints.maxWidth >= 600) ...[
                _buildTitle(isCompact ? 130 : 220),
                SizedBox(width: gap),
              ],
              _buildSearchField(isCompact ? 44.0 : 200.0),
              SizedBox(width: gap),
              Expanded(child: _buildQuickFiltersStrip()),
              SizedBox(width: gap),
              _buildTestSoundButton(isCompact),
              SizedBox(width: gap),
              _buildLocaleToggleButton(isCompact),
              SizedBox(width: gap),
              _buildNotificationBell(isCompact),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitle(double maxWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
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

  Widget _buildSearchField(double width) {
    return SizedBox(
      width: width,
      height: 36,
      child: TextField(
        key: const Key('global-search-input'),
        onChanged: controller.setSearchQuery,
        decoration: InputDecoration(
          hintText: AdminI18n.searchHint(controller.isEs),
          hintStyle:
              _text.bodyMedium?.copyWith(color: KachavaTokens.textSecondary),
          prefixIcon: const Icon(Icons.search,
              size: 18, color: KachavaTokens.textSecondary),
          filled: true,
          fillColor: KachavaTokens.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(KachavaTokens.radiusPill),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(KachavaTokens.radiusPill),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(KachavaTokens.radiusPill),
            borderSide: const BorderSide(color: KachavaTokens.focus, width: 2),
          ),
        ),
        style: _text.bodyMedium?.copyWith(color: KachavaTokens.text),
      ),
    );
  }

  Widget _buildQuickFiltersStrip() {
    final isEs = controller.isEs;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            key: const Key('quick-filter-all-villas'),
            label: AdminI18n.allVillas(isEs),
            selected: controller.villaFilter == 'All Villas' &&
                !controller.urgentOnly &&
                controller.lifecycleFilter == null,
            onTap: () => controller.setQuickFilter(
                villa: 'All Villas', urgentOnly: false, clearLifecycle: true),
          ),
          _buildFilterChip(
            key: const Key('quick-filter-urgent-only'),
            label: AdminI18n.urgentOnly(isEs),
            selected: controller.urgentOnly,
            onTap: () =>
                controller.toggleUrgentOnlyFilter(!controller.urgentOnly),
          ),
          _buildFilterChip(
            key: const Key('quick-filter-active-stay'),
            label: AdminI18n.activeStay(isEs),
            selected:
                controller.lifecycleFilter == StayLifecycleStatus.activeStay,
            onTap: () => controller.setQuickFilter(
                lifecycle: StayLifecycleStatus.activeStay),
          ),
          _buildFilterChip(
            key: const Key('quick-filter-pre-arrival'),
            label: AdminI18n.preArrival(isEs),
            selected:
                controller.lifecycleFilter == StayLifecycleStatus.preArrival,
            onTap: () => controller.setQuickFilter(
                lifecycle: StayLifecycleStatus.preArrival),
          ),
        ],
      ),
    );
  }

  /// Neutral pill: gray when idle, darker gray + bold when selected.
  ///
  /// The visible pill stays compact, but its tap target is at least 48dp
  /// (DESIGN.md) and keyboard focus draws the shared [FocusRing].
  Widget _pill({
    required Key key,
    required Widget child,
    required VoidCallback onTap,
    bool selected = false,
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
                  color: background ??
                      (selected
                          ? KachavaTokens.surfaceHover
                          : KachavaTokens.surface),
                  borderRadius: radius,
                  border: selected
                      ? Border.all(color: KachavaTokens.inputBorder)
                      : null,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: _pill(
        key: key,
        selected: selected,
        onTap: onTap,
        child: Text(
          label,
          style: _text.labelLarge?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: KachavaTokens.text,
          ),
        ),
      ),
    );
  }

  Widget _buildTestSoundButton(bool isCompact) {
    final isEs = controller.isEs, ringing = controller.isChimeRinging;
    final label = isCompact
        ? (ringing ? '🔇' : '🔔')
        : (ringing
            ? (isEs ? '🔇 Silenciar' : '🔇 Mute 10s')
            : (isEs ? '🔔 Probar 10s' : '🔔 Test 10s'));
    final pill = _pill(
      key: const Key('test-alert-sound-btn'),
      background: ringing ? KachavaTokens.warningBackground : null,
      padding:
          EdgeInsets.symmetric(horizontal: isCompact ? 6 : 12, vertical: 6),
      onTap: controller.triggerTestAlertSound,
      child: Text(
        label,
        style: _text.labelLarge?.copyWith(
          color: ringing ? KachavaTokens.warningForeground : KachavaTokens.text,
        ),
      ),
    );
    if (!isCompact) return pill;
    // Compact mode shows only an emoji, so the tooltip names the action.
    return Tooltip(
      message: ringing
          ? AdminI18n.tr(isEs, 'Mute test sound', 'Silenciar sonido de prueba')
          : AdminI18n.tr(
              isEs, 'Test alert sound (10s)', 'Probar sonido de alerta (10s)'),
      child: pill,
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
