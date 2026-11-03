import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../data/guest_api.dart';
import '../../domain/catalog.dart';
import '../../domain/forms.dart';
import '../../domain/requests.dart';
import '../../domain/resort_clock.dart';
import '../common/widgets.dart';
import 'form_scaffold.dart';

/// Items already chosen for a PREFERENCE service.
Set<String> savedChoices(PortalController c, CatalogService s) => {
      for (final b in c.stay?.bookings ?? const [])
        if (b.serviceId == s.id &&
            b.itemId != null &&
            bookingStatusOf(b.status) != RequestStatus.cancelled)
          b.itemId!,
    };

/// Saves new choices (one booking per chosen item, PREFERENCE usage).
Future<ApiResult<void>> saveChoices(
    PortalController c, CatalogService s, Set<String> selected) async {
  final day = c.stay?.checkIn ?? c.clock.today();
  final already = savedChoices(c, s);
  ApiResult<void> last = const ApiOk(null);
  for (final itemId in selected.difference(already)) {
    last = await c.createBooking({
      'serviceId': s.id,
      'itemId': itemId,
      'scheduledDate': ResortClock.isoDay(day),
    });
    if (last is ApiFailed) return last;
  }
  return last;
}

/// "Change until Nov 2, 18:00" from the admin change deadline.
String? changeDeadline(PortalController c, CatalogService s) {
  final hours = s.changeDeadlineHours;
  final checkIn = c.stay?.checkIn;
  if (hours == null || checkIn == null) return null;
  final at = checkIn.subtract(Duration(hours: hours));
  return c.l10n.changeUntil('${c.l10n.date(at)}, ${c.l10n.clock(at)}');
}

/// Choice cards with photo (radio or checkbox).
class PreferenceChoices extends StatelessWidget {
  const PreferenceChoices({
    super.key,
    required this.l10n,
    required this.service,
    required this.selected,
    required this.onChanged,
  });

  final L10n l10n;
  final CatalogService service;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (service.items.isEmpty) return OneLineState(message: l10n.noItems);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in service.items)
          ChoiceCard(
            key: Key('choice-${item.id}'),
            multiple: service.multipleChoice,
            selected: selected.contains(item.id),
            title: l10n.text(item.name),
            subtitle: l10n.text(item.description),
            leading: item.image == null
                ? null
                : ServicePhoto(image: item.image, l10n: l10n, radius: 8),
            onTap: () {
              if (service.multipleChoice) {
                final next = {...selected};
                next.contains(item.id)
                    ? next.remove(item.id)
                    : next.add(item.id);
                onChanged(next);
              } else {
                onChanged({item.id});
              }
            },
          ),
      ],
    );
  }
}

/// PREFERENCE service opened from Services: choose → "Save".
class PreferenceForm extends StatefulWidget {
  const PreferenceForm(
      {super.key,
      required this.controller,
      required this.service,
      required this.title});

  final PortalController controller;
  final CatalogService service;
  final String title;

  @override
  State<PreferenceForm> createState() => _PreferenceFormState();
}

class _PreferenceFormState extends State<PreferenceForm> {
  late Set<String> _selected = savedChoices(widget.controller, widget.service);
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    final l10n = widget.controller.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result =
        await saveChoices(widget.controller, widget.service, _selected);
    if (!mounted) return;
    if (result is ApiFailed<void>) {
      setState(() {
        _busy = false;
        _error = failureMessage(l10n, result);
      });
      return;
    }
    Navigator.of(context).pop();
    showPortalToast(context, l10n.choiceSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.controller.l10n;
    final deadline = changeDeadline(widget.controller, widget.service);
    return FormScaffold(
      l10n: l10n,
      title: widget.title,
      busy: _busy,
      error: _error,
      onRetry: _save,
      primaryLabel: l10n.save,
      onPrimary: _selected.isEmpty ? null : _save,
      children: [
        if (deadline != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(deadline,
                style: const TextStyle(
                    fontSize: 14, color: KachavaColors.tertiary)),
          ),
        PreferenceChoices(
          l10n: l10n,
          service: widget.service,
          selected: _selected,
          onChanged: (v) => setState(() => _selected = v),
        ),
      ],
    );
  }
}

/// 1.2 Preferences: diet & allergies (explicit "None"), then one page per
/// active PREFERENCE service. Each page is saved when leaving it.
class PreferencesWizard extends StatefulWidget {
  const PreferencesWizard({
    super.key,
    required this.controller,
    required this.services,
    required this.title,
  });

  final PortalController controller;
  final List<CatalogService> services;
  final String title;

  @override
  State<PreferencesWizard> createState() => _PreferencesWizardState();
}

class _PreferencesWizardState extends State<PreferencesWizard> {
  late final TextEditingController _diet;
  late final TextEditingController _allergies;
  late bool _none;
  late final List<Set<String>> _choices;
  int _page = 0;
  bool _busy = false;
  bool _showIssues = false;
  String? _error;

  int get _pages => 1 + widget.services.length;
  bool get _last => _page == _pages - 1;

  @override
  void initState() {
    super.initState();
    final stay = widget.controller.stay;
    final diet = stay?.dietary ?? '';
    _none = diet == noneValue;
    _diet = TextEditingController(text: _none ? '' : diet);
    _allergies =
        TextEditingController(text: (stay?.allergies ?? const []).join(', '));
    _choices = [
      for (final s in widget.services) savedChoices(widget.controller, s)
    ];
  }

  /// Stored when the guest has no diet or allergies.
  static const String noneValue = 'None';

  @override
  void dispose() {
    _diet.dispose();
    _allergies.dispose();
    super.dispose();
  }

  Future<void> _savePage() async {
    final l10n = widget.controller.l10n;
    if (_page == 0 &&
        !_none &&
        _diet.text.trim().isEmpty &&
        _allergies.text.trim().isEmpty) {
      setState(() => _showIssues = true);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ApiResult<void> result;
    if (_page == 0) {
      final allergies = _none
          ? const <String>[]
          : _allergies.text
              .split(',')
              .map((a) => a.trim())
              .where((a) => a.isNotEmpty)
              .toList();
      result = await widget.controller.savePreferences(
          _none
              ? noneValue
              : (_diet.text.trim().isEmpty ? noneValue : _diet.text.trim()),
          allergies);
    } else {
      final service = widget.services[_page - 1];
      result =
          await saveChoices(widget.controller, service, _choices[_page - 1]);
    }
    if (!mounted) return;
    if (result is ApiFailed<void>) {
      setState(() {
        _busy = false;
        _error = failureMessage(l10n, result);
      });
      return;
    }
    if (_last) {
      Navigator.of(context).pop();
      showPortalToast(context, l10n.preferencesSaved);
      return;
    }
    setState(() {
      _busy = false;
      _showIssues = false;
      _page++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.controller.l10n;
    final service = _page == 0 ? null : widget.services[_page - 1];
    final deadline =
        service == null ? null : changeDeadline(widget.controller, service);
    return FormScaffold(
      l10n: l10n,
      title: widget.title,
      page: _page,
      pages: _pages,
      busy: _busy,
      error: _error,
      onRetry: _savePage,
      onBack: _page == 0 ? null : () => setState(() => _page--),
      info: _page == 0 ? l10n.dietInfo : null,
      primaryLabel: _last ? l10n.save : l10n.nextPage,
      onPrimary: _savePage,
      children: service == null
          ? [
              SwitchListTile(
                key: const Key('diet-none'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.none, style: const TextStyle(fontSize: 16)),
                value: _none,
                onChanged: (v) => setState(() => _none = v),
              ),
              LabeledField(
                label: l10n.diet,
                issue: _showIssues ? l10n.issue(FormIssue.required) : null,
                child: TextField(
                    key: const Key('diet-field'),
                    controller: _diet,
                    enabled: !_none),
              ),
              LabeledField(
                label: l10n.allergies,
                child: TextField(
                    key: const Key('allergies-field'),
                    controller: _allergies,
                    enabled: !_none),
              ),
            ]
          : [
              Text(l10n.text(service.name),
                  style: Theme.of(context).textTheme.titleMedium),
              if (deadline != null)
                Text(deadline,
                    style: const TextStyle(
                        fontSize: 14, color: KachavaColors.tertiary)),
              const SizedBox(height: 8),
              PreferenceChoices(
                l10n: l10n,
                service: service,
                selected: _choices[_page - 1],
                onChanged: (v) => setState(() => _choices[_page - 1] = v),
              ),
            ],
    );
  }
}

/// 3.2 Rate your stay (optional).
class RatingForm extends StatefulWidget {
  const RatingForm({super.key, required this.controller, required this.title});
  final PortalController controller;
  final String title;

  @override
  State<RatingForm> createState() => _RatingFormState();
}

class _RatingFormState extends State<RatingForm> {
  int _rating = 0;
  final TextEditingController _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = widget.controller.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.controller.sendRating(_rating, _note.text);
    if (!mounted) return;
    if (result is ApiFailed<void>) {
      setState(() {
        _busy = false;
        _error = failureMessage(l10n, result);
      });
      return;
    }
    Navigator.of(context).pop();
    showPortalToast(context, l10n.ratingSent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.controller.l10n;
    return FormScaffold(
      l10n: l10n,
      title: widget.title,
      busy: _busy,
      error: _error,
      onRetry: _send,
      info: l10n.rateInfo,
      primaryLabel: l10n.send,
      onPrimary: _rating == 0 ? null : _send,
      children: [
        LabeledField(
          label: l10n.rating,
          child: Wrap(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  key: Key('star-$i'),
                  tooltip: l10n.stars(i),
                  constraints:
                      const BoxConstraints.tightFor(width: 48, height: 48),
                  isSelected: i <= _rating,
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(i <= _rating ? Icons.star : Icons.star_border,
                      color: KachavaColors.primary, size: 30),
                ),
            ],
          ),
        ),
        LabeledField(
          label: l10n.notes,
          child: TextField(controller: _note, maxLines: 3, maxLength: 500),
        ),
      ],
    );
  }
}
