import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/portal_controller.dart';
import '../../core/i18n/l10n.dart';
import '../../core/pwa/install_prompt_port.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../domain/journey.dart';
import '../common/labels.dart';
import '../common/widgets.dart';
import '../shell/install_app_banner.dart';

/// Home: villa · dates · Wi-Fi strip, the numbered journey accordion and the
/// sticky "Next" / "Not now" pair.
class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.controller,
    required this.installPrompt,
    required this.onOpenTask,
  });

  final PortalController controller;
  final InstallPromptPort installPrompt;
  final ValueChanged<JourneyTask> onOpenTask;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int? _expanded;
  int? _lastOpenStep;
  final Set<int> _showAll = {};
  bool _wifiShown = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l10n = c.l10n;
    final journey = c.journey!;
    if (_lastOpenStep != journey.openStep) {
      _lastOpenStep = journey.openStep;
      _expanded = journey.openStep;
    }
    final next = journey.next;
    return Column(
      key: const Key('screen-home'),
      children: [
        Expanded(
          child: PageWidth(
            maxWidth: 720,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                InstallAppBanner(port: widget.installPrompt, i18n: l10n),
                _topStrip(l10n),
                const SizedBox(height: 12),
                if (journey.allSet)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(l10n.allSet,
                        key: const Key('journey-all-set'),
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                for (final step in journey.steps) _stepCard(l10n, step),
              ],
            ),
          ),
        ),
        if (next != null)
          StickyAction(
            secondary: TextButton(
              key: const Key('journey-not-now'),
              onPressed: () => c.skip(next),
              child: Text(l10n.notNow),
            ),
            child: FilledButton(
              key: const Key('journey-next'),
              onPressed: () => widget.onOpenTask(next),
              child: Text(l10n.next(next.number, taskName(l10n, next)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
    );
  }

  Widget _topStrip(L10n l10n) {
    final stay = widget.controller.stay!;
    final parts = [stay.villaName, stay.datesLabel]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(parts,
            key: const Key('home-strip'),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: KachavaColors.onSurface)),
        if (stay.wifiSsid.isNotEmpty)
          TextButton.icon(
            key: const Key('wifi-button'),
            onPressed: () => _copyWifi(l10n),
            icon: const Icon(Icons.wifi, size: 18),
            label: Text(_wifiShown
                ? '${stay.wifiSsid} · ${stay.wifiPassword}'
                : l10n.wifi),
          ),
      ],
    );
  }

  Future<void> _copyWifi(L10n l10n) async {
    final stay = widget.controller.stay!;
    setState(() => _wifiShown = true);
    final value =
        stay.wifiPassword.isNotEmpty ? stay.wifiPassword : stay.wifiSsid;
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      showPortalToast(context, l10n.wifiCopied);
    } on PlatformException {
      if (!mounted) return;
      showPortalToast(context, l10n.copyFailed, error: true);
    }
  }

  Widget _stepCard(L10n l10n, JourneyStep step) {
    final expanded = _expanded == step.number;
    final showAll = _showAll.contains(step.number);
    final rows = showAll || step.tasks.length <= journeyMaxRows
        ? step.tasks
        : step.tasks.take(journeyMaxRows).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: expanded,
              label: l10n.stepSemantics(
                  step.number, step.done, step.total, expanded),
              excludeSemantics: true,
              child: InkWell(
                key: Key('step-${step.number}'),
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    setState(() => _expanded = expanded ? null : step.number),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: _stepHeader(l10n, step, expanded),
                ),
              ),
            ),
            if (expanded) ...[
              for (final task in rows) _taskRow(l10n, task, step.locked),
              if (step.tasks.length > journeyMaxRows)
                TextButton(
                  key: Key('see-all-${step.number}'),
                  onPressed: () => setState(() => showAll
                      ? _showAll.remove(step.number)
                      : _showAll.add(step.number)),
                  child: Text(
                      showAll ? l10n.showLess : l10n.seeAll(step.tasks.length)),
                ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepHeader(L10n l10n, JourneyStep step, bool expanded) {
    return Row(
      children: [
        Icon(expanded ? Icons.expand_more : Icons.chevron_right,
            color: KachavaColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text('${step.number} ${l10n.stepTitle(step.number)}',
              style: const TextStyle(
                  fontFamily: KachavaTheme.serifFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.onSurface)),
        ),
        if (step.locked)
          Text(l10n.opens(step.opensOn),
              style: const TextStyle(
                  fontSize: 14, color: KachavaColors.onSurfaceVariant))
        else if (step.total > 0) ...[
          SizedBox(
            width: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: step.done / step.total,
                minHeight: 6,
                color: KachavaColors.primary,
                backgroundColor: KachavaColors.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(l10n.progress(step.done, step.total),
              key: Key('progress-${step.number}'),
              style: const TextStyle(
                  fontSize: 14, color: KachavaColors.onSurfaceVariant)),
        ],
      ],
    );
  }

  Widget _taskRow(L10n l10n, JourneyTask task, bool locked) {
    final title = taskTitle(l10n, task);
    final trailing = switch (task.state) {
      TaskState.done => taskSummary(l10n, task),
      TaskState.draft => l10n.draft,
      TaskState.skipped => l10n.skipped,
      TaskState.pending => task.section != null && task.services.length > 1
          ? '${task.services.length}'
          : '',
    };
    final stateWord = switch (task.state) {
      TaskState.done => l10n.done,
      TaskState.draft => l10n.draft,
      TaskState.skipped => l10n.skipped,
      TaskState.pending => l10n.pending,
    };
    return Semantics(
      button: true,
      enabled: !locked,
      label:
          '$title, $stateWord${trailing.isNotEmpty && trailing != stateWord ? ', $trailing' : ''}',
      excludeSemantics: true,
      child: InkWell(
        key: Key('task-${task.number}'),
        onTap: locked ? null : () => widget.onOpenTask(task),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _stateIcon(task),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          color: locked
                              ? KachavaColors.onSurfaceVariant
                              : KachavaColors.onSurface)),
                ),
                if (trailing.isNotEmpty)
                  Flexible(
                    child: Text(trailing,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontSize: 14,
                            color: KachavaColors.onSurfaceVariant)),
                  ),
                if (locked)
                  InfoTip(l10n.lockedInfo)
                else
                  const Icon(Icons.chevron_right,
                      color: KachavaColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stateIcon(JourneyTask task) {
    const size = 26.0;
    return switch (task.state) {
      TaskState.done => const Icon(Icons.check_circle,
          color: KachavaColors.confirmedGreen, size: size),
      TaskState.draft =>
        const Icon(Icons.timelapse, color: KachavaColors.primary, size: size),
      TaskState.skipped => const Icon(Icons.redo,
          color: KachavaColors.onSurfaceVariant, size: size),
      TaskState.pending => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: KachavaColors.primary, width: 1.5),
          ),
          child: Text('${task.slot}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.primary)),
        ),
    };
  }
}
