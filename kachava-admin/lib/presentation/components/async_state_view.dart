import 'package:flutter/material.dart';

/// Which branch an [AsyncStateView] renders.
enum AsyncViewState { loading, empty, error, data }

/// Loading / empty / error / data switcher with one-line messages.
class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.state,
    required this.builder,
    this.emptyMessage = '',
    this.errorMessage = '',
    this.emptyActionLabel,
    this.onEmptyAction,
    this.retryLabel = 'Retry',
    this.onRetry,
  });

  final AsyncViewState state;
  final WidgetBuilder builder;
  final String emptyMessage;
  final String errorMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => switch (state) {
        AsyncViewState.loading => const Center(
            key: Key('async-state-loading'),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )),
        AsyncViewState.empty => _line(context, const Key('async-state-empty'),
            emptyMessage, emptyActionLabel, onEmptyAction),
        AsyncViewState.error => _line(context, const Key('async-state-error'),
            errorMessage, retryLabel, onRetry),
        AsyncViewState.data => builder(context),
      };

  Widget _line(BuildContext context, Key key, String message, String? action,
      VoidCallback? onAction) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          if (action != null && onAction != null)
            OutlinedButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}
