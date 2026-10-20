import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../core/responsive_breakpoints.dart';
import '../../domain/admin_enums.dart';

/// Sticky 64px Top Command Bar with Global Search, Quick Filter Chips, Test 10s Sound, EN|ES Toggle & Alert Bell.
class TopCommandBar extends StatelessWidget {
  const TopCommandBar({super.key, required this.controller});

  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AdminBreakpoints.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        border: Border(
            bottom: BorderSide(color: KachavaAdminColors.borderLimestone)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;
          final searchWidth = isCompact ? 44.0 : 185.0;
          final gap = isCompact ? 2.0 : 6.0;
          return Row(
            children: [
              _buildSearchField(searchWidth),
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

  Widget _buildSearchField(double width) {
    return SizedBox(
      width: width,
      height: 36,
      child: TextField(
        key: const Key('global-search-input'),
        onChanged: controller.setSearchQuery,
        decoration: InputDecoration(
          hintText: AdminI18n.searchHint(controller.isEs),
          hintStyle: const TextStyle(fontSize: 12),
          prefixIcon: const Icon(Icons.search, size: 15),
          filled: true,
          fillColor: KachavaAdminColors.surfaceContainer,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(fontSize: 12),
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

  Widget _buildFilterChip({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? KachavaAdminColors.zapotePrimary
                : KachavaAdminColors.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? KachavaAdminColors.zapotePrimary
                  : KachavaAdminColors.borderLimestone,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : KachavaAdminColors.obsidian,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required Key key,
    required String label,
    required bool isCompact,
    required VoidCallback onTap,
    Color bgColor = KachavaAdminColors.surfaceContainer,
    Color borderColor = KachavaAdminColors.borderLimestone,
    Color fgColor = KachavaAdminColors.obsidian,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: isCompact ? 5 : 9, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fgColor),
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
    return _buildActionPill(
      key: const Key('test-alert-sound-btn'),
      label: label,
      isCompact: isCompact,
      bgColor: ringing
          ? KachavaAdminColors.copalGold
          : KachavaAdminColors.surfaceContainer,
      borderColor: ringing
          ? KachavaAdminColors.obsidian
          : KachavaAdminColors.borderLimestone,
      fgColor: ringing
          ? KachavaAdminColors.obsidian
          : KachavaAdminColors.zapotePrimary,
      onTap: controller.triggerTestAlertSound,
    );
  }

  Widget _buildLocaleToggleButton(bool isCompact) {
    final isEs = controller.isEs;
    return Semantics(
      button: true,
      label: isEs ? 'ES | EN' : 'EN | ES',
      child: InkWell(
        key: const Key('admin-locale-toggle-btn'),
        onTap: controller.toggleLocale,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: KachavaAdminColors.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: KachavaAdminColors.borderLimestone),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLocaleSegment(!isEs ? '✓ EN' : 'EN', !isEs, isCompact),
              _buildLocaleSegment(isEs ? '✓ ES' : 'ES', isEs, isCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocaleSegment(String label, bool active, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 5 : 7, vertical: 4),
      decoration: BoxDecoration(
        color: active ? KachavaAdminColors.zapotePrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isCompact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : KachavaAdminColors.mutedBronze,
        ),
      ),
    );
  }

  Widget _buildNotificationBell(bool isCompact) {
    final unread = controller.unreadAlertsCount;
    return Semantics(
      button: true,
      label: 'Unread operational alerts: $unread',
      child: InkWell(
        key: const Key('top-bar-alert-bell'),
        onTap: () => controller.selectTab(AdminWorkspaceTab.adminOverview),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: isCompact ? 6 : 9, vertical: 6),
          decoration: BoxDecoration(
            color: KachavaAdminColors.criticalAllergySla.background,
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: KachavaAdminColors.criticalAllergySla.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active,
                  size: 14, color: Color(0xFF93000A)),
              const SizedBox(width: 3),
              Text(
                '$unread',
                key: const Key('unread-alerts-badge'),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF93000A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
