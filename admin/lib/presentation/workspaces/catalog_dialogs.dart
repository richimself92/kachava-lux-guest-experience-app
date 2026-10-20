import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';

/// Opens the modal dialog to add a new Experience to the live catalog.
Future<void> showAddExperienceCatalogDialog(
  BuildContext context,
  AdminDashboardController controller,
) =>
    showDialog<void>(
      context: context,
      builder: (_) => _AddExperienceCatalogDialog(controller: controller),
    );

/// Opens the modal dialog to add a new Minibar/Larder product to the live catalog.
Future<void> showAddLarderCatalogDialog(
  BuildContext context,
  AdminDashboardController controller,
) =>
    showDialog<void>(
      context: context,
      builder: (_) => _AddLarderCatalogDialog(controller: controller),
    );

class _AddExperienceCatalogDialog extends StatefulWidget {
  const _AddExperienceCatalogDialog({required this.controller});
  final AdminDashboardController controller;

  @override
  State<_AddExperienceCatalogDialog> createState() =>
      _AddExperienceCatalogDialogState();
}

class _AddExperienceCatalogDialogState
    extends State<_AddExperienceCatalogDialog> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final String _category = 'Excursions';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    await widget.controller.addExperienceCatalogItem(
      title: title,
      category: _category,
      duration: _durationCtrl.text.trim().isEmpty
          ? 'Half-Day'
          : _durationCtrl.text.trim(),
      basePriceUSD: price,
      isIncluded: price == 0,
      description: _descCtrl.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = widget.controller.isEs;
    return AlertDialog(
      backgroundColor: KachavaAdminColors.surfacePaper,
      title: Text(AdminI18n.tr(
          isEs, 'New Experience in Catalog', 'Nueva Experiencia al Catálogo')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _catalogInput(
              key: const Key('catalog-exp-title-input'),
              ctrl: _titleCtrl,
              label: AdminI18n.tr(
                  isEs, 'Experience Title', 'Nombre de la Experiencia'),
              hint: AdminI18n.tr(isEs, 'e.g. Sian Ka\'an Sunset Tour',
                  'Ej. Expedición Sian Ka\'an'),
            ),
            const SizedBox(height: 10),
            _catalogInput(
              key: const Key('catalog-exp-duration-input'),
              ctrl: _durationCtrl,
              label: AdminI18n.tr(isEs, 'Duration', 'Duración'),
              hint: AdminI18n.tr(isEs, 'e.g. 4 Hours', 'Ej. 4 Horas'),
            ),
            const SizedBox(height: 10),
            _catalogInput(
              key: const Key('catalog-exp-price-input'),
              ctrl: _priceCtrl,
              label: AdminI18n.tr(isEs, 'Price (USD)', 'Precio (USD)'),
              hint: AdminI18n.tr(isEs, 'e.g. 350', 'Ej. 350'),
            ),
            const SizedBox(height: 10),
            _catalogInput(
              key: const Key('catalog-exp-desc-input'),
              ctrl: _descCtrl,
              label: AdminI18n.tr(isEs, 'Description', 'Descripción'),
              hint: AdminI18n.tr(isEs, 'e.g. Private guide & tasting',
                  'Ej. Guía privado y degustación'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AdminI18n.tr(isEs, 'Cancel', 'Cancelar')),
        ),
        ElevatedButton(
          key: const Key('confirm-add-catalog-experience-btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KachavaAdminColors.zapotePrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: Text(
              AdminI18n.tr(isEs, 'Save Experience', 'Guardar Experiencia')),
        ),
      ],
    );
  }
}

class _AddLarderCatalogDialog extends StatefulWidget {
  const _AddLarderCatalogDialog({required this.controller});
  final AdminDashboardController controller;

  @override
  State<_AddLarderCatalogDialog> createState() =>
      _AddLarderCatalogDialogState();
}

class _AddLarderCatalogDialogState extends State<_AddLarderCatalogDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    await widget.controller.addLarderCatalogItem(
      name: name,
      category: 'Minibar',
      price: price,
      storageType: 'MINIBAR',
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = widget.controller.isEs;
    return AlertDialog(
      backgroundColor: KachavaAdminColors.surfacePaper,
      title: Text(AdminI18n.tr(
          isEs, 'New Minibar / Larder Product', 'Nuevo Producto de Minibar')),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _catalogInput(
              key: const Key('catalog-larder-name-input'),
              ctrl: _nameCtrl,
              label: AdminI18n.tr(isEs, 'Product Name', 'Nombre del Producto'),
              hint: AdminI18n.tr(
                  isEs, 'e.g. Kombucha Hibiscus', 'Ej. Kombucha de Jamaica'),
            ),
            const SizedBox(height: 10),
            _catalogInput(
              key: const Key('catalog-larder-price-input'),
              ctrl: _priceCtrl,
              label: AdminI18n.tr(isEs, 'Price (USD)', 'Precio (USD)'),
              hint: AdminI18n.tr(isEs, 'e.g. 24', 'Ej. 24'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AdminI18n.tr(isEs, 'Cancel', 'Cancelar')),
        ),
        ElevatedButton(
          key: const Key('confirm-add-catalog-larder-btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KachavaAdminColors.zapotePrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: Text(AdminI18n.tr(isEs, 'Save Product', 'Guardar Producto')),
        ),
      ],
    );
  }
}

Widget _catalogInput({
  required Key key,
  required TextEditingController ctrl,
  required String label,
  required String hint,
}) =>
    TextField(
      key: key,
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
