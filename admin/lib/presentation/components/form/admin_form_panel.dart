import 'package:flutter/material.dart';

import '../../../core/admin_list_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../confirm_dialog.dart';
import '../list/admin_detail_panel.dart';

/// Create/edit form inside the detail panel or mobile sheet: labelled
/// fields, inline validation, Save (spinner while saving) / Cancel, and a
/// "Discard changes?" guard when closing with unsaved edits (close button,
/// Esc, Cancel or the mobile back gesture).
class AdminFormPanel extends StatefulWidget {
  const AdminFormPanel({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
    required this.onClose,
    this.closeOnSave = true,
    this.isEs = false,
  });

  final String title;
  final List<Widget> children;

  /// Persists the saved form values; throw to keep the form open and show
  /// "Couldn't save". Fields' `onSaved` run before it.
  final Future<void> Function() onSave;
  final VoidCallback onClose;
  final bool closeOnSave;
  final bool isEs;

  @override
  State<AdminFormPanel> createState() => _AdminFormPanelState();
}

class _AdminFormPanelState extends State<AdminFormPanel> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _dirty = false;
  bool _saving = false;
  bool _saveFailed = false;

  AdminListStrings get _s => AdminListStrings(widget.isEs);

  Future<void> _save() async {
    final form = _formKey.currentState!;
    if (!form.validate()) return;
    form.save();
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await widget.onSave();
      if (!mounted) return;
      _dirty = false;
      if (widget.closeOnSave) widget.onClose();
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        isEs: widget.isEs,
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: ListView(
            key: const Key('form-panel-fields'),
            padding: const EdgeInsets.all(KachavaTokens.space6),
            children: widget.children,
          ),
        ),
        footer: _footer(),
      ),
    );
  }

  Widget _footer() => Row(children: [
        if (_saveFailed) ...[
          const Icon(Icons.error_outline, size: 18, color: KachavaTokens.error),
          const SizedBox(width: KachavaTokens.space2),
          Expanded(
            child: Text(_s.saveError,
                key: const Key('form-save-error'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ] else
          const Spacer(),
        TextButton(
          key: const Key('form-cancel'),
          onPressed: _saving ? null : _requestClose,
          child: Text(_s.cancel),
        ),
        const SizedBox(width: KachavaTokens.space2),
        FilledButton(
          key: const Key('form-save'),
          onPressed: _saving ? null : _save,
          child: _saving
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: KachavaTokens.space2),
                  Text(_s.save),
                ])
              : Text(_s.save),
        ),
      ]);
}
