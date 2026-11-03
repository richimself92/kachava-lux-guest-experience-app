import 'package:flutter/material.dart';

import '../../core/theme/kachava_tokens.dart';

/// Small square photo for table rows; a neutral icon when there is none.
class CatalogThumb extends StatelessWidget {
  const CatalogThumb(
      {super.key, required this.url, this.label = '', this.size = 36});

  final String? url;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(Icons.image_outlined,
        size: size * 0.55, color: KachavaTokens.textSecondary);
    final source = url;
    return Semantics(
      image: source != null,
      label: label,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: KachavaTokens.surface,
          borderRadius: BorderRadius.circular(KachavaTokens.radiusSm),
        ),
        child: source == null || source.isEmpty
            ? placeholder
            : Image.network(source,
                fit: BoxFit.cover,
                cacheWidth: (size * 2).round(),
                errorBuilder: (_, __, ___) => placeholder),
      ),
    );
  }
}
