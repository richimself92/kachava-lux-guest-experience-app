import 'json_read.dart';

/// A localized name of a folio service.
class FolioName {
  const FolioName(this.en, this.es);

  factory FolioName.fromJson(Object? json) {
    if (json is! Map) return const FolioName('', '');
    final map = Map<String, dynamic>.from(json);
    return FolioName(JsonRead.text(map, 'en'), JsonRead.text(map, 'es'));
  }

  final String en;
  final String es;

  String of(bool isEs) => isEs && es.isNotEmpty ? es : en;
}

/// One acquired service (order, booking or trip) of the stay.
class FolioService {
  const FolioService({
    required this.type,
    required this.id,
    required this.name,
    required this.status,
    required this.date,
    required this.totalUSD,
  });

  factory FolioService.fromJson(Map<String, dynamic> json) => FolioService(
        type: JsonRead.text(json, 'type'),
        id: JsonRead.text(json, 'id'),
        name: FolioName.fromJson(json['name']),
        status: JsonRead.text(json, 'status'),
        date: JsonRead.textOrNull(json, 'date'),
        totalUSD: JsonRead.doubleOrNull(json, 'totalUSD'),
      );

  /// `ORDER`, `BOOKING` or `TRIP`.
  final String type;
  final String id;
  final FolioName name;
  final String status;
  final String? date;
  final double? totalUSD;
}

/// One folio charge.
class FolioCharge {
  const FolioCharge({
    required this.id,
    required this.title,
    required this.amountUSD,
    required this.isComplimentary,
    required this.status,
  });

  factory FolioCharge.fromJson(Map<String, dynamic> json) => FolioCharge(
        id: JsonRead.text(json, 'folioItemId'),
        title: JsonRead.text(json, 'title'),
        amountUSD: JsonRead.doubleOrNull(json, 'chargedAmountUSD') ?? 0,
        isComplimentary: JsonRead.flag(json, 'isComplimentary'),
        status: JsonRead.text(json, 'status'),
      );

  final String id;
  final String title;
  final double amountUSD;
  final bool isComplimentary;
  final String status;
}

/// "Stay summary" (`GET /admin/stays/:id/folio`): services, the latest
/// rating and the charges. Payments never appear: no PMS is integrated.
class StayFolio {
  const StayFolio({
    required this.services,
    required this.rating,
    required this.ratingNote,
    required this.charges,
    required this.totalUSD,
  });

  factory StayFolio.fromJson(Map<String, dynamic> json) {
    final rating = JsonRead.object(json, 'rating');
    final charges = JsonRead.object(json, 'charges');
    return StayFolio(
      services: [
        for (final s in JsonRead.objects(json, 'services'))
          FolioService.fromJson(s),
      ],
      rating: JsonRead.intOrNull(rating, 'rating'),
      ratingNote: JsonRead.text(rating, 'note'),
      charges: [
        for (final c in JsonRead.objects(charges, 'items'))
          FolioCharge.fromJson(c),
      ],
      totalUSD: JsonRead.doubleOrNull(charges, 'totalUSD') ?? 0,
    );
  }

  final List<FolioService> services;

  /// 1-5, `null` when the guest gave none.
  final int? rating;
  final String ratingNote;
  final List<FolioCharge> charges;
  final double totalUSD;

  List<FolioService> get trips =>
      services.where((s) => s.type == 'TRIP').toList();
}
