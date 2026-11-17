import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `/` focuses search; PageUp/PageDown page the list. Disabled while typing
/// in a text field so the keys still reach it.
class AdminListShortcuts extends StatelessWidget {
  const AdminListShortcuts({
    super.key,
    required this.searchFocus,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final FocusNode searchFocus;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.slash):
            _ListKeyIntent(_ListKey.search),
        SingleActivator(LogicalKeyboardKey.pageUp):
            _ListKeyIntent(_ListKey.previous),
        SingleActivator(LogicalKeyboardKey.pageDown):
            _ListKeyIntent(_ListKey.next),
      },
      child: Actions(
        actions: {
          _ListKeyIntent: _ListKeyAction((key) => switch (key) {
                _ListKey.search => searchFocus.requestFocus(),
                _ListKey.previous => onPrevious(),
                _ListKey.next => onNext(),
              }),
        },
        child: child,
      ),
    );
  }
}

enum _ListKey { search, previous, next }

class _ListKeyIntent extends Intent {
  const _ListKeyIntent(this.key);

  final _ListKey key;
}

class _ListKeyAction extends Action<_ListKeyIntent> {
  _ListKeyAction(this._run);

  final void Function(_ListKey key) _run;

  /// Not while a text field has focus (the key belongs to the text).
  @override
  bool isEnabled(_ListKeyIntent intent) {
    final focused = FocusManager.instance.primaryFocus?.context;
    return focused == null ||
        focused.findAncestorWidgetOfExactType<EditableText>() == null;
  }

  @override
  Object? invoke(_ListKeyIntent intent) {
    _run(intent.key);
    return null;
  }
}
