import 'package:flutter/material.dart';

import '../../../core/admin_list_strings.dart';
import '../../../core/stay_strings.dart';
import '../../../domain/admin_catalog_repositories.dart';
import '../../../domain/admin_villa.dart';
import '../../components/components.dart';

/// Nights of a new reservation: ISO `checkIn` and exclusive `checkOut`.
typedef StayRange = ({String checkIn, String checkOut});

/// Villa picker of a new reservation. Disabled with a one-line hint until
/// [range] is set; then it lists only the villas the server reports free for
/// those nights. A new range reloads the list and clears a selection that is
/// no longer offered ([onChanged] receives `null`).
class AvailableVillaField extends StatefulWidget {
  const AvailableVillaField({
    super.key,
    required this.repository,
    required this.range,
    required this.onChanged,
    required this.isEs,
  });

  final VillaRepository repository;

  /// Valid nights to check, or `null` while the dates are incomplete.
  final StayRange? range;
  final ValueChanged<String?> onChanged;
  final bool isEs;

  @override
  State<AvailableVillaField> createState() => _AvailableVillaFieldState();
}

class _AvailableVillaFieldState extends State<AvailableVillaField> {
  List<AdminVilla>? _villas;
  bool _failed = false;
  String? _selected;

  /// Only the answer of the latest request is applied.
  int _request = 0;

  StayStrings get _s => StayStrings(widget.isEs);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AvailableVillaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) _load();
  }

  /// Resets synchronously (no setState: also runs from didUpdateWidget).
  void _load() {
    final request = ++_request;
    _villas = null;
    _failed = false;
    final range = widget.range;
    if (range == null) return _keepOnly(const []);
    _fetch(range, request);
  }

  Future<void> _fetch(StayRange range, int request) async {
    try {
      final villas =
          await widget.repository.available(range.checkIn, range.checkOut);
      if (!mounted || request != _request) return;
      setState(() => _villas = villas);
      _keepOnly(villas);
    } catch (error) {
      debugPrint('Available villas unavailable: $error');
      if (mounted && request == _request) setState(() => _failed = true);
    }
  }

  void _keepOnly(List<AdminVilla> villas) {
    if (_selected == null || villas.any((v) => v.id == _selected)) return;
    _selected = null;
    widget.onChanged(null);
  }

  void _select(String? id) {
    setState(() => _selected = id);
    widget.onChanged(id);
  }

  @override
  Widget build(BuildContext context) {
    final villas = _villas ?? const <AdminVilla>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: ValueKey('${widget.range}|${_villas?.length}|$_selected'),
          child: AdminDropdownFormField<String>(
            label: _s.villa,
            isRequired: true,
            fieldKey: const Key('reservation-villa'),
            initialValue: _selected,
            choices: [for (final v in villas) AdminChoice(v.id, v.name)],
            onChanged: villas.isEmpty ? null : _select,
            isEs: widget.isEs,
          ),
        ),
        if (_stateLine() case final line?) line,
      ],
    );
  }

  Widget? _stateLine() {
    if (widget.range == null) {
      return AdminStateLine(
          key: const Key('reservation-villa-hint'), message: _s.pickDatesFirst);
    }
    if (_failed) {
      final list = AdminListStrings(widget.isEs);
      return AdminStateLine(
          message: list.loadError,
          actionLabel: list.retry,
          onAction: () => setState(_load),
          isError: true);
    }
    if (_villas?.isEmpty ?? false) {
      return AdminStateLine(
          key: const Key('reservation-no-villas'),
          message: _s.noVillasForDates);
    }
    return null;
  }
}
