import 'package:flutter/widgets.dart';

/// One tab of a tabbed `AdminFormPanel`. [children] scroll in a padded
/// list; a raw [child] fills the tab (e.g. a nested table).
class AdminFormTab {
  const AdminFormTab(
      {required this.label, this.children = const [], this.child});

  final String label;
  final List<Widget> children;
  final Widget? child;
}

/// A secondary footer action (e.g. "Activate") that runs through the same
/// validate -> save fields -> await pipeline as Save, after an optional
/// one-line confirmation. The panel stays open.
class AdminFormAction {
  const AdminFormAction({
    required this.label,
    required this.run,
    this.confirmTitle,
    this.destructive = false,
    this.key,
  });

  final String label;
  final Future<void> Function() run;
  final String? confirmTitle;
  final bool destructive;
  final Key? key;
}
