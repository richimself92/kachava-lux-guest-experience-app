import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../core/i18n/l10n.dart';
import '../../domain/catalog.dart';
import '../../domain/journey.dart';
import '../../domain/trip.dart';
import '../common/labels.dart';
import '../forms/booking_form.dart';
import '../forms/order_form.dart';
import '../forms/preference_forms.dart';
import '../forms/trip_wizard.dart';

/// Numbered title of the journey task that holds [service] (open step
/// first), so a form reads "2.1 Dining" everywhere; else the service name.
String serviceTitle(PortalController c, CatalogService service) {
  final journey = c.journey;
  final l10n = c.l10n;
  if (journey != null) {
    final steps = [
      journey.step(journey.openStep),
      ...journey.steps.where((s) => s.number != journey.openStep),
    ];
    for (final step in steps) {
      for (final task in step.tasks) {
        if (task.section != null &&
            task.services.any((s) => s.id == service.id)) {
          return '${task.number} ${l10n.text(service.name)}';
        }
      }
    }
  }
  return l10n.text(service.name);
}

/// Primary action label by usage type.
String primaryLabel(L10n l10n, UsageType usage) => switch (usage) {
      UsageType.order => l10n.actionOrder,
      UsageType.booking => l10n.actionBook,
      UsageType.preference => l10n.actionChoose,
      UsageType.trip => l10n.actionPlanTrip,
      UsageType.unknown => l10n.unavailable,
    };

/// Why the primary action is disabled (one line), or null.
String? disabledReason(L10n l10n, CatalogService s) {
  if (s.usageType == UsageType.unknown) return l10n.unavailable;
  if ((s.usageType == UsageType.order || s.usageType == UsageType.preference) &&
      s.items.isEmpty) {
    return l10n.noItems;
  }
  return null;
}

/// Opens the form for [service] by usage type (Order · Book · Choose · Plan trip).
Future<void> openServiceForm(
    BuildContext context, PortalController c, CatalogService service,
    {String? title}) {
  final heading = title ?? serviceTitle(c, service);
  final Widget page = switch (service.usageType) {
    UsageType.order =>
      OrderForm(controller: c, service: service, title: heading),
    UsageType.preference =>
      PreferenceForm(controller: c, service: service, title: heading),
    UsageType.trip =>
      TripWizard(controller: c, service: service, title: heading),
    _ => BookingForm(controller: c, service: service, title: heading),
  };
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => page));
}

/// Opens a core journey task (1.1, 1.2, 3.1, 3.2).
Future<void> openCoreTask(
    BuildContext context, PortalController c, JourneyTask task) {
  final title = taskTitle(c.l10n, task);
  final Widget page = switch (task.core!) {
    CoreTask.flight => TripWizard(
        controller: c,
        service: task.services.first,
        title: title,
        presetType: TripType.arrival,
        core: CoreTask.flight),
    CoreTask.departure => TripWizard(
        controller: c,
        service: task.services.first,
        title: title,
        presetType: TripType.departure,
        core: CoreTask.departure),
    CoreTask.preferences =>
      PreferencesWizard(controller: c, services: task.services, title: title),
    CoreTask.rating => RatingForm(controller: c, title: title),
  };
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => page));
}
