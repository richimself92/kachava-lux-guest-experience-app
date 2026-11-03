import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../domain/catalog.dart';
import '../common/widgets.dart';
import 'service_detail.dart';

enum WhenFilter { any, before, during }

/// Section opened from a Home row ("2.1 Dining"); Back returns to Home.
class ServicesFocus {
  const ServicesFocus({required this.section, required this.title});
  final String section;
  final String title;
}

/// Services: search, section chips, When chip and photo cards. Built only
/// from the ACTIVE catalog.
class ServicesTab extends StatefulWidget {
  const ServicesTab({
    super.key,
    required this.controller,
    required this.onAskHost,
    this.focus,
    this.onBack,
  });

  final PortalController controller;
  final VoidCallback onAskHost;
  final ServicesFocus? focus;
  final VoidCallback? onBack;

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  static const int _blockCards = 3;
  static const int _pageCards = 12;

  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _section;
  WhenFilter _when = WhenFilter.any;
  int _visible = _pageCards;

  @override
  void initState() {
    super.initState();
    _section = widget.focus?.section;
  }

  @override
  void didUpdateWidget(covariant ServicesTab old) {
    super.didUpdateWidget(old);
    if (widget.focus?.section != old.focus?.section && widget.focus != null) {
      _section = widget.focus!.section;
      _visible = _pageCards;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  void _clear() {
    _debounce?.cancel();
    _search.clear();
    setState(() {
      _query = '';
      _section = null;
      _when = WhenFilter.any;
      _visible = _pageCards;
    });
  }

  bool _matches(L10n l10n, CatalogService s) {
    if (_section != null && s.section != _section) return false;
    if (_when == WhenFilter.before && !s.availability.offeredWhen.before) {
      return false;
    }
    if (_when == WhenFilter.during && !s.availability.offeredWhen.during) {
      return false;
    }
    if (_query.isEmpty) return true;
    final hay = [l10n.text(s.name), l10n.text(s.shortDescription), ...s.tags]
        .join(' ')
        .toLowerCase();
    return hay.contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l10n = c.l10n;
    final catalog = [...c.catalog]..sort((a, b) {
        final r = sectionRank(a.section).compareTo(sectionRank(b.section));
        return r != 0 ? r : a.order.compareTo(b.order);
      });
    final sections = <String>[];
    for (final s in catalog) {
      if (!sections.contains(s.section)) sections.add(s.section);
    }
    final results = catalog.where((s) => _matches(l10n, s)).toList();

    return Column(
      key: const Key('screen-services'),
      children: [
        if (widget.focus != null)
          Material(
            color: KachavaColors.surface,
            child: Row(children: [
              IconButton(
                key: const Key('services-back'),
                tooltip: l10n.back,
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              Expanded(
                child: Text(widget.focus!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: KachavaTheme.serifFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: KachavaColors.primary)),
              ),
            ]),
          ),
        Expanded(
          child: PageWidth(
            child: LayoutBuilder(builder: (context, box) {
              final columns =
                  box.maxWidth < 640 ? 1 : (box.maxWidth < 1024 ? 2 : 3);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _filters(l10n, sections),
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(l10n.servicesCount(results.length),
                        key: const Key('services-count'),
                        style: const TextStyle(
                            fontSize: 14,
                            color: KachavaColors.onSurfaceVariant)),
                  ),
                  const SizedBox(height: 8),
                  ..._results(l10n, catalog, results, sections, columns,
                      box.maxWidth - 32),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _filters(L10n l10n, List<String> sections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('services-search'),
          controller: _search,
          onChanged: _onSearch,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.search,
            labelText: l10n.search,
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            SelectChip(
                l10n.all,
                _section == null,
                () => setState(() {
                      _section = null;
                      _visible = _pageCards;
                    }),
                key: const Key('chip-all')),
            for (final s in sections)
              SelectChip(
                  l10n.section(s),
                  _section == s,
                  () => setState(() {
                        _section = s;
                        _visible = _pageCards;
                      }),
                  key: Key('chip-$s')),
            WhenFilterButton(
              l10n: l10n,
              value: _when,
              onSelected: (v) => setState(() => _when = v),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _results(
      L10n l10n,
      List<CatalogService> catalog,
      List<CatalogService> results,
      List<String> sections,
      int columns,
      double width) {
    final c = widget.controller;
    if (catalog.isEmpty) {
      return c.catalogFailed
          ? [
              OneLineState(
                  message: l10n.loadFailed,
                  actionLabel: l10n.retry,
                  onAction: c.refresh)
            ]
          : [
              OneLineState(
                  key: const Key('services-empty'),
                  message: l10n.nothingYet,
                  actionLabel: l10n.askHost,
                  onAction: widget.onAskHost),
            ];
    }
    if (results.isEmpty) {
      return [
        OneLineState(
            key: const Key('services-no-results'),
            message: l10n.noResults,
            actionLabel: l10n.clear,
            onAction: _clear),
      ];
    }
    if (_section == null) {
      return [
        for (final s in sections)
          if (results.any((r) => r.section == s)) ...[
            Row(children: [
              Expanded(
                  child: Text(l10n.section(s),
                      style: Theme.of(context).textTheme.titleMedium)),
              if (results.where((r) => r.section == s).length > _blockCards)
                TextButton(
                  key: Key('see-all-$s'),
                  onPressed: () => setState(() => _section = s),
                  child: Text(
                      l10n.seeAll(results.where((r) => r.section == s).length)),
                ),
            ]),
            _grid(
                l10n,
                results.where((r) => r.section == s).take(_blockCards).toList(),
                columns,
                width),
            const SizedBox(height: 12),
          ],
      ];
    }
    final shown = results.take(_visible).toList();
    return [
      _grid(l10n, shown, columns, width),
      if (results.length > shown.length)
        TextButton(
          key: const Key('services-more'),
          onPressed: () => setState(() => _visible += _pageCards),
          child: Text(l10n.showMore((results.length - shown.length) < _pageCards
              ? results.length - shown.length
              : _pageCards)),
        ),
    ];
  }

  Widget _grid(
      L10n l10n, List<CatalogService> services, int columns, double width) {
    const gap = 12.0;
    final cardWidth = (width - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final s in services)
          SizedBox(
              width: cardWidth,
              child: ServiceCard(controller: widget.controller, service: s)),
      ],
    );
  }
}

/// Whole card is the target: photo, name, one line, price chip, lead time.
class ServiceCard extends StatelessWidget {
  const ServiceCard(
      {super.key, required this.controller, required this.service});
  final PortalController controller;
  final CatalogService service;

  @override
  Widget build(BuildContext context) {
    final l10n = controller.l10n;
    final name = l10n.text(service.name);
    return Semantics(
      button: true,
      label: name,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('service-card-${service.id}'),
          onTap: () => showServiceDetail(context, controller, service),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServicePhoto(image: service.cover, l10n: l10n),
                const SizedBox(height: 8),
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: KachavaTheme.serifFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: KachavaColors.onSurface)),
                if (l10n.text(service.shortDescription).isNotEmpty)
                  Text(l10n.text(service.shortDescription),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, color: KachavaColors.onSurfaceVariant)),
                const SizedBox(height: 6),
                ServiceChips(l10n: l10n, service: service),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "When: Any" chip (Any / Before / During).
class WhenFilterButton extends StatelessWidget {
  const WhenFilterButton(
      {super.key,
      required this.l10n,
      required this.value,
      required this.onSelected});

  final L10n l10n;
  final WhenFilter value;
  final ValueChanged<WhenFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = switch (value) {
      WhenFilter.any => l10n.whenAny,
      WhenFilter.before => l10n.whenBefore,
      WhenFilter.during => l10n.whenDuring,
    };
    return PopupMenuButton<WhenFilter>(
      key: const Key('chip-when'),
      tooltip: l10n.when,
      onSelected: onSelected,
      itemBuilder: (_) => [
        PopupMenuItem(value: WhenFilter.any, child: Text(l10n.whenAny)),
        PopupMenuItem(value: WhenFilter.before, child: Text(l10n.whenBefore)),
        PopupMenuItem(value: WhenFilter.during, child: Text(l10n.whenDuring)),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: KachavaColors.outlineStrong),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text('${l10n.when}: $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14)),
          ),
          const Icon(Icons.arrow_drop_down),
        ]),
      ),
    );
  }
}
