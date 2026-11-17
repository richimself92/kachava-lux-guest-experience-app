import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/admin_list_strings.dart';
import '../../../core/theme/kachava_tokens.dart';

/// One tab of an [AdminDetailPanel].
class AdminPanelTab {
  const AdminPanelTab({required this.label, required this.builder});

  final String label;
  final WidgetBuilder builder;
}

/// Right-side detail panel (desktop, 420px) or full-screen sheet body
/// (mobile): title, close (Esc), optional tabs, body and footer.
///
/// Takes focus when shown so Esc works right away.
class AdminDetailPanel extends StatefulWidget {
  const AdminDetailPanel({
    super.key,
    required this.title,
    required this.onClose,
    this.body,
    this.tabs = const [],
    this.actions = const [],
    this.footer,
    this.isEs = false,
  }) : assert(body != null || tabs.length > 0, 'Provide body or tabs');

  static const double width = 420;

  final String title;
  final VoidCallback onClose;
  final Widget? body;
  final List<AdminPanelTab> tabs;
  final List<Widget> actions;
  final Widget? footer;
  final bool isEs;

  @override
  State<AdminDetailPanel> createState() => _AdminDetailPanelState();
}

class _AdminDetailPanelState extends State<AdminDetailPanel> {
  final FocusNode _focus = FocusNode(debugLabel: 'detail-panel');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focus.hasFocus) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        const Divider(),
        if (widget.tabs.isEmpty)
          Expanded(child: widget.body!)
        else
          Expanded(child: _tabs()),
        if (widget.footer != null) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: KachavaTokens.space6,
                vertical: KachavaTokens.space3),
            child: widget.footer,
          ),
        ],
      ],
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
      },
      child: Focus(
        focusNode: _focus,
        child: Material(
          key: const Key('detail-panel'),
          color: KachavaTokens.surface,
          child: content,
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(KachavaTokens.space6,
            KachavaTokens.space2, KachavaTokens.space2, KachavaTokens.space2),
        child: Row(children: [
          Expanded(
            child: Text(widget.title,
                key: const Key('detail-panel-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          ...widget.actions,
          IconButton(
            key: const Key('detail-panel-close'),
            tooltip: AdminListStrings(widget.isEs).close,
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
        ]),
      );

  Widget _tabs() => Builder(builder: _tabsIn);

  Widget _tabsIn(BuildContext context) => DefaultTabController(
        length: widget.tabs.length,
        child: Column(children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: KachavaTokens.ink,
            unselectedLabelColor: KachavaTokens.muted,
            // Text-only tabs: selected = ink text over a 1px ink rule.
            indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: KachavaTokens.ink, width: 1)),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: KachavaTokens.line,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            labelStyle: Theme.of(context).textTheme.labelLarge,
            unselectedLabelStyle: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w400),
            tabs: [for (final t in widget.tabs) Tab(text: t.label)],
          ),
          Expanded(
            child: TabBarView(children: [
              for (final t in widget.tabs) Builder(builder: t.builder),
            ]),
          ),
        ]),
      );
}
