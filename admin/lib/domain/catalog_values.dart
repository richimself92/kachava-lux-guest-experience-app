import 'json_read.dart';

/// EN/ES copy typed by staff. Spanish is never machine-generated.
class LocalizedText {
  const LocalizedText({this.en = '', this.es = ''});

  factory LocalizedText.fromJson(Object? json) {
    if (json is! Map) return const LocalizedText();
    final map = Map<String, dynamic>.from(json);
    return LocalizedText(
        en: JsonRead.text(map, 'en'), es: JsonRead.text(map, 'es'));
  }

  final String en;
  final String es;

  bool get isEmpty => en.isEmpty && es.isEmpty;

  /// Both languages present (required to activate a service).
  bool get isComplete => en.isNotEmpty && es.isNotEmpty;

  String of({required bool isEs}) => isEs ? es : en;

  Map<String, dynamic> toJson() => {'en': en, 'es': es};

  @override
  bool operator ==(Object other) =>
      other is LocalizedText && other.en == en && other.es == es;

  @override
  int get hashCode => Object.hash(en, es);
}

/// An uploaded image in Cloud Storage plus its EN/ES alt text.
class CatalogImage {
  const CatalogImage({
    required this.storagePath,
    required this.url,
    this.alt = const LocalizedText(),
    this.usageRightsConfirmed = false,
  });

  /// `null` when the server sent no `storagePath`/`url` pair.
  static CatalogImage? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    final path = JsonRead.text(map, 'storagePath');
    final url = JsonRead.text(map, 'url');
    if (path.isEmpty || url.isEmpty) return null;
    return CatalogImage(
      storagePath: path,
      url: url,
      alt: LocalizedText.fromJson(map['alt']),
      usageRightsConfirmed: JsonRead.flag(map, 'usageRightsConfirmed'),
    );
  }

  final String storagePath;
  final String url;
  final LocalizedText alt;
  final bool usageRightsConfirmed;

  Map<String, dynamic> toJson() => {
        'storagePath': storagePath,
        'url': url,
        'alt': alt.toJson(),
        'usageRightsConfirmed': usageRightsConfirmed,
      };
}

/// Who created/changed a record and when (server-owned, read-only).
class AuditInfo {
  const AuditInfo({
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory AuditInfo.fromJson(Map<String, dynamic> json) => AuditInfo(
        createdAt: JsonRead.textOrNull(json, 'createdAt'),
        createdBy: JsonRead.textOrNull(json, 'createdBy'),
        updatedAt: JsonRead.textOrNull(json, 'updatedAt'),
        updatedBy: JsonRead.textOrNull(json, 'updatedBy'),
      );

  final String? createdAt;
  final String? createdBy;
  final String? updatedAt;
  final String? updatedBy;
}
