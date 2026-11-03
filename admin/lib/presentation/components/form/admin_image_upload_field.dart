import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/admin_list_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/uploads.dart';
import '../info_tooltip.dart';
import 'admin_form_fields.dart';

/// Image field: pick -> check type/size (JPEG/PNG/WebP, <= 5 MB) -> ask the
/// [signer] for a signed URL -> `PUT` with [transport] -> preview. The value
/// changes only after the upload succeeded.
class AdminImageUploadField extends StatelessWidget {
  const AdminImageUploadField({
    super.key,
    required this.id,
    required this.label,
    required this.folder,
    required this.signer,
    required this.transport,
    required this.picker,
    this.initialValue,
    this.isRequired = false,
    this.onSaved,
    this.onChanged,
    this.isEs = false,
  });

  /// Key suffix: `upload-<id>`, `upload-<id>-pick`, `upload-<id>-error`.
  final String id;
  final String label;

  /// Storage folder sent to the signer, e.g. `services`.
  final String folder;
  final UploadSigner signer;
  final SignedUploadTransport transport;
  final ImageFilePicker picker;
  final UploadedImage? initialValue;
  final bool isRequired;
  final FormFieldSetter<UploadedImage>? onSaved;
  final ValueChanged<UploadedImage?>? onChanged;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return FormField<UploadedImage>(
      key: Key('upload-$id'),
      initialValue: initialValue,
      onSaved: onSaved,
      validator: (value) =>
          isRequired && value == null ? AdminListStrings(isEs).required : null,
      builder: (field) => _UploadBody(field: field, config: this),
    );
  }
}

class _UploadBody extends StatefulWidget {
  const _UploadBody({required this.field, required this.config});

  final FormFieldState<UploadedImage> field;
  final AdminImageUploadField config;

  @override
  State<_UploadBody> createState() => _UploadBodyState();
}

class _UploadBodyState extends State<_UploadBody> {
  bool _busy = false;
  String? _error;
  Uint8List? _localPreview;

  AdminImageUploadField get _c => widget.config;
  AdminListStrings get _s => AdminListStrings(_c.isEs);

  Future<void> _pickAndUpload() async {
    final file = await _c.picker.pickImage();
    if (file == null || !mounted) return;
    final rejection = ImageUploadPolicy.check(file);
    if (rejection != null) {
      return setState(() => _error = rejection == ImageRejection.tooLarge
          ? _s.maxFileSize
          : _s.imageTypes);
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final signed = await _c.signer.sign(
          fileName: file.name,
          contentType: file.contentType,
          sizeBytes: file.sizeBytes,
          folder: _c.folder);
      await _c.transport.put(signed.uploadUrl, file.bytes, file.contentType);
      if (!mounted) return;
      final image = UploadedImage(
          storagePath: signed.storagePath, publicUrl: signed.publicUrl);
      _localPreview = file.bytes;
      widget.field.didChange(image);
      _c.onChanged?.call(image);
    } catch (_) {
      if (mounted) setState(() => _error = _s.uploadFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove() {
    _localPreview = null;
    widget.field.didChange(null);
    _c.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.field.value;
    final error = _error ?? widget.field.errorText;
    return Padding(
      padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AdminFieldLabel(_c.label, isRequired: _c.isRequired),
            InfoTooltip('${_s.imageTypes} · ${_s.maxFileSize}'),
          ]),
          Row(children: [
            _preview(value),
            const SizedBox(width: KachavaTokens.space4),
            Expanded(
              child: Wrap(
                spacing: KachavaTokens.space2,
                runSpacing: KachavaTokens.space2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: _actions(value),
              ),
            ),
          ]),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: KachavaTokens.space1),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    size: 16, color: KachavaTokens.error),
                const SizedBox(width: KachavaTokens.space1),
                Text(error,
                    key: Key('upload-${_c.id}-error'),
                    style: const TextStyle(
                        fontSize: 12, color: KachavaTokens.error)),
              ]),
            ),
        ],
      ),
    );
  }

  List<Widget> _actions(UploadedImage? value) {
    if (_busy) {
      return [
        const SizedBox.square(
            dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        Text(_s.uploading),
      ];
    }
    return [
      OutlinedButton.icon(
        key: Key('upload-${_c.id}-pick'),
        onPressed: _pickAndUpload,
        icon: const Icon(Icons.upload_outlined, size: 18),
        label: Text(value == null ? _s.upload : _s.replace),
      ),
      if (value != null)
        TextButton(
          key: Key('upload-${_c.id}-remove'),
          onPressed: _remove,
          child: Text(_s.remove),
        ),
    ];
  }

  Widget _preview(UploadedImage? value) {
    const size = 96.0;
    Widget broken(BuildContext _, Object __, StackTrace? ___) =>
        const Icon(Icons.broken_image_outlined);
    final image = value == null
        ? const Icon(Icons.image_outlined, color: KachavaTokens.textSecondary)
        : _localPreview != null
            ? Image.memory(_localPreview!,
                fit: BoxFit.cover, cacheWidth: 192, errorBuilder: broken)
            : Image.network(value.publicUrl,
                fit: BoxFit.cover, cacheWidth: 192, errorBuilder: broken);
    return Semantics(
      image: value != null,
      label: _c.label,
      child: Container(
        key: Key('upload-${_c.id}-preview'),
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: KachavaTokens.surface,
          borderRadius: BorderRadius.circular(KachavaTokens.radiusMd),
        ),
        child: Center(child: image),
      ),
    );
  }
}
