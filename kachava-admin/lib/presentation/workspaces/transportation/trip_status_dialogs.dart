import 'package:flutter/material.dart';

import '../../../core/transport_strings.dart';
import '../../../domain/admin_trip.dart';
import '../../../domain/transport_provider.dart';
import '../../components/components.dart';

/// "Send to provider": pick an active provider (the trip's one preselected).
Future<TripTransition?> showSendToProviderDialog(
  BuildContext context, {
  required List<TransportProvider> providers,
  required String? currentProviderId,
  required bool isEs,
}) {
  final s = TransportStrings(isEs);
  final active = providers.where((p) => p.isActive).toList();
  String? providerId =
      active.any((p) => p.id == currentProviderId) ? currentProviderId : null;
  return _showFormDialog(
    context,
    key: const Key('trip-send-dialog'),
    title: s.sendToProvider,
    confirmLabel: s.sendToProvider,
    isEs: isEs,
    fields: [
      if (active.isEmpty)
        Text(s.noActiveProviders, key: const Key('trip-send-no-providers'))
      else
        AdminDropdownFormField<String>(
          label: s.provider,
          isRequired: true,
          fieldKey: const Key('trip-send-provider'),
          initialValue: providerId,
          choices: [for (final p in active) AdminChoice(p.id, p.name)],
          onChanged: (v) => providerId = v,
          isEs: isEs,
        ),
    ],
    result: () => providerId == null
        ? null
        : TripTransition(to: 'SENT_TO_PROVIDER', providerId: providerId),
  );
}

/// "Confirm": driver name and phone (required) plus the vehicle.
Future<TripTransition?> showConfirmTripDialog(
  BuildContext context, {
  required AdminTrip trip,
  required bool isEs,
}) {
  final s = TransportStrings(isEs);
  var name = trip.driver?.name ?? '';
  var phone = trip.driver?.phone ?? '';
  var vehicle = trip.vehicle?.description ?? '';
  var plate = trip.vehicle?.plate ?? '';
  Widget text(String label, String key, String initial, bool required,
          ValueChanged<String> onChanged) =>
      AdminTextFormField(
        label: label,
        isRequired: required,
        initialValue: initial,
        fieldKey: Key(key),
        validator: AdminValidators.maxLength(200, isEs),
        onChanged: onChanged,
        isEs: isEs,
      );
  return _showFormDialog(
    context,
    key: const Key('trip-confirm-dialog'),
    title: s.confirm,
    confirmLabel: s.confirm,
    isEs: isEs,
    fields: [
      text(s.driverName, 'trip-driver-name', name, true, (v) => name = v),
      text(s.driverPhone, 'trip-driver-phone', phone, true, (v) => phone = v),
      text(s.vehicleDescription, 'trip-vehicle-description', vehicle, false,
          (v) => vehicle = v),
      text(s.plate, 'trip-vehicle-plate', plate, false, (v) => plate = v),
    ],
    result: () => TripTransition(
      to: 'CONFIRMED',
      driver: TripDriver(name: name.trim(), phone: phone.trim()),
      vehicle: vehicle.trim().isEmpty && plate.trim().isEmpty
          ? null
          : TripVehicle(description: vehicle.trim(), plate: plate.trim()),
    ),
  );
}

/// "Cancel trip": a required one-line reason.
Future<TripTransition?> showCancelTripDialog(BuildContext context,
    {required bool isEs}) {
  final s = TransportStrings(isEs);
  var reason = '';
  return _showFormDialog(
    context,
    key: const Key('trip-cancel-dialog'),
    title: s.cancelTrip,
    confirmLabel: s.cancelTrip,
    cancelLabel: s.back,
    destructive: true,
    isEs: isEs,
    fields: [
      AdminTextFormField(
        label: s.reason,
        isRequired: true,
        fieldKey: const Key('trip-cancel-reason'),
        validator: AdminValidators.maxLength(200, isEs),
        onChanged: (v) => reason = v,
        isEs: isEs,
      ),
    ],
    result: () => TripTransition(to: 'CANCELLED', reason: reason.trim()),
  );
}

/// A small form dialog: validates [fields] and resolves [result] on confirm
/// (`null` when dismissed).
Future<TripTransition?> _showFormDialog(
  BuildContext context, {
  required Key key,
  required String title,
  required String confirmLabel,
  required List<Widget> fields,
  required TripTransition? Function() result,
  required bool isEs,
  String? cancelLabel,
  bool destructive = false,
}) {
  final form = GlobalKey<FormState>();
  final scheme = Theme.of(context).colorScheme;
  return showDialog<TripTransition>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: key,
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: fields),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('trip-dialog-cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(cancelLabel ?? TransportStrings(isEs).cancel),
        ),
        FilledButton(
          key: const Key('trip-dialog-confirm'),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError)
              : null,
          onPressed: () {
            if (!(form.currentState?.validate() ?? false)) return;
            final move = result();
            if (move != null) Navigator.of(dialogContext).pop(move);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
