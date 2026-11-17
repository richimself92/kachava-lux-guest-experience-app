import 'package:flutter/material.dart';

import '../../core/theme/kachava_tokens.dart';
import 'focus_ring.dart';

/// Text-only switch (MUJI "Segmented"): the selected option is ink text
/// over a 1px ink rule; the others are muted. Each option is a 40px target
/// keyed `<key>-<value>` when [key] is a [ValueKey<String>].
class TextSegmented<T> extends StatelessWidget {
  const TextSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  /// Option value -> visible label, in display order.
  final Map<T, String> options;
  final T? selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: KachavaTokens.space4,
      children: [
        for (final e in options.entries) _option(context, e.key, e.value),
      ],
    );
  }

  Widget _option(BuildContext context, T value, String label) {
    final on = value == selected;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
        color: on ? KachavaTokens.ink : KachavaTokens.muted,
        fontWeight: on ? FontWeight.w500 : FontWeight.w400);
    return Semantics(
      selected: on,
      button: true,
      child: FocusRing(
        child: InkWell(
          key: _keyFor(value),
          onTap: () => onChanged(value),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: on ? KachavaTokens.ink : Colors.transparent),
              ),
            ),
            child: Text(label, style: style),
          ),
        ),
      ),
    );
  }

  Key? _keyFor(T value) {
    final k = key;
    if (k is ValueKey<String>) return Key('${k.value}-$value');
    return null;
  }
}
