import 'package:flutter/material.dart';

import '../../../core/admin_list_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../confirm_dialog.dart';
import '../list/admin_detail_panel.dart';
import 'admin_form_parts.dart';

export 'admin_form_parts.dart';

/// Create/edit form inside the detail panel or mobile sheet: labelled
/// fields, inline validation, Save (spinner while saving) / Cancel, and a
/// "Discard changes?" guard when closing with unsaved edits (close button,
/// Esc, Cancel or the mobile back gesture).
///
/// With [tabs], every tab stays mounted (so all fields validate and save
/// together) and a failed validation jumps to the first invalid tab.
class AdminFormPanel extends StatefulWidget {
  const AdminFormPanel({
    super.key,
    required this.title,
    this.children = const [],
    this.tabs = const [],
    this.footerActions = const [],
    required this.onSave,
    required this.onClose,
    this.closeOnSave = true,
    this.actions = const [],
    this.failureMessage,
    this.isEs = false,
  });

  final String title;
  final List<Widget> children;
  final List<AdminFormTab> tabs;
  final List<AdminFormAction> footerActions;

  /// Header actions before the close button (e.g. a ⋮ menu).
  final List<Widget> actions;

  /// Persists the saved form values; throw to keep the form open and show
  /// "Couldn't save" (or [failureMessage]). Fields' `onSaved` run before it.
  final Future<void> Function() onSave;
  final VoidCallback onClose;
  final bool closeOnSave;

  /// One-line text for a failure (e.g. "Cover required"); `null` keeps the
  /// generic "Couldn't save".
  final String? Function(Object error)? failureMessage;
  final bool isEs;

  @override
  State<AdminFormPanel> createState() => _AdminFormPanelState();
}

class _AdminFormPanelState extends State<AdminFormPanel>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<GlobalKey<FormState>> _tabForms = [];
  TabController? _tabs;
  bool _dirty = false;
  bool _saving = false;
  String? _failure;

  AdminListStrings get _s => AdminListStrings(widget.isEs);

  @override
  void initState() {
    super.initState();
    _syncTabs();
  }

  @override
  void didUpdateWidget(AdminFormPanel old) {
    super.didUpdateWidget(old);
    if (old.tabs.length != widget.tabs.length) _syncTabs();
  }

  void _syncTabs() {
    _tabs?.dispose();
    final count = widget.tabs.length;
    _tabs = count == 0 ? null : TabController(length: count, vsync: this);
    _tabForms = [for (var i = 0; i < count; i++) GlobalKey<FormState>()];
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  List<FormState> get _forms => [
        for (final key in _tabs == null ? [_formKey] : _tabForms)
          if (key.currentState case final form?) form
      ];

  /// Validates every form; jumps to the first invalid tab.
  bool _validate() {
    final forms = _forms;
    final valid = [for (final f in forms) f.validate()];
    final firstInvalid = valid.indexOf(false);
    if (firstInvalid >= 0 && _tabs != null) _tabs!.animateTo(firstInvalid);
    return firstInvalid < 0;
  }

  Future<void> _submit(Future<void> Function() run,
      {required bool close}) async {
    if (!_validate()) return;
    for (final form in _forms) {
      form.save();
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await run();
      if (!mounted) return;
      _dirty = false;
      if (close) widget.onClose();
    } catch (error) {
      if (mounted) {
        setState(() =>
            _failure = widget.failureMessage?.call(error) ?? _s.saveError);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runAction(AdminFormAction action) async {
    final title = action.confirmTitle;
    if (title != null) {
      final ok = await showConfirmDialog(context,
          title: title,
          confirmLabel: action.label,
          cancelLabel: _s.cancel,
          destructive: action.destructive);
      if (!ok || !mounted) return;
    }
    await _submit(action.run, close: false);
  }

  Future<void> _requestClose() async {
    if (_saving) return;
    if (!_dirty) return widget.onClose();
    final discard = await showConfirmDialog(context,
        title: _s.discardChanges,
        confirmLabel: _s.discard,
        cancelLabel: _s.keepEditing,
        destructive: true);
    if (!mounted || !discard) return;
    _dirty = false;
    widget.onClose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: AdminDetailPanel(
        title: widget.title,
        onClose: _requestClose,
        actions: widget.actions,
        isEs: widget.isEs,
        body: _tabs == null ? _singleForm() : _tabbedForms(),
        footer: _footer(),
      ),
    );
  }

  Widget _fieldList(List<Widget> children, Key? key) => ListView(
        key: key,
        padding: const EdgeInsets.all(KachavaTokens.space6),
        children: children,
      );

  Widget _singleForm() => Form(
        key: _formKey,
        onChanged: _markDirty,
        child: _fieldList(widget.children, const Key('form-panel-fields')),
      );

  Widget _tabbedForms() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            key: const Key('form-panel-tabbar'),
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: KachavaTokens.text,
            unselectedLabelColor: KachavaTokens.textSecondary,
            indicatorColor: KachavaTokens.text,
            dividerColor: KachavaTokens.border,
            tabs: [for (final t in widget.tabs) Tab(text: t.label)],
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _tabs!,
              builder: (context, _) => IndexedStack(
                key: const Key('form-panel-tabs'),
                index: _tabs!.index,
                sizing: StackFit.expand,
                children: [
                  for (var i = 0; i < widget.tabs.length; i++) _tab(i),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _tab(int i) {
    final tab = widget.tabs[i];
    return Form(
      key: _tabForms[i],
      onChanged: _markDirty,
      child: tab.child ?? _fieldList(tab.children, Key('form-panel-tab-$i')),
    );
  }

  /// Failure line (when any) above the buttons; the buttons wrap on narrow
  /// screens (320px, longer Spanish labels) instead of overflowing.
  Widget _footer() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: KachavaTokens.space2),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    size: 18, color: KachavaTokens.error),
                const SizedBox(width: KachavaTokens.space2),
                Expanded(
                  child: Text(_failure!,
                      key: const Key('form-save-error'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KachavaTokens.space2,
            runSpacing: KachavaTokens.space2,
            children: [
              TextButton(
                key: const Key('form-cancel'),
                onPressed: _saving ? null : _requestClose,
                child: Text(_s.cancel),
              ),
              for (final action in widget.footerActions)
                OutlinedButton(
                  key: action.key,
                  onPressed: _saving ? null : () => _runAction(action),
                  child: Text(action.label),
                ),
              _saveButton(),
            ],
          ),
        ],
      );

  Widget _saveButton() => FilledButton(
        key: const Key('form-save'),
        onPressed: _saving
            ? null
            : () => _submit(widget.onSave, close: widget.closeOnSave),
        child: _saving
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: KachavaTokens.space2),
                Text(_s.save),
              ])
            : Text(_s.save),
      );
}
