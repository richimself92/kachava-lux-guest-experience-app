import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kachava_guest_portal/domain/entities/experience_entities.dart';

import 'villa_102_experiences_seed.dart';
import 'villa_102_larder_seed.dart';

/// Serves the Villa 102 test catalogs as `GET /catalog/{experiences,larder}`
/// envelopes; returns `null` for any other request.
http.Response? villa102CatalogResponse(http.BaseRequest request) {
  final path = request.url.path;
  if (!path.contains('/catalog/')) return null;
  final data = path.endsWith('/larder')
      ? Villa102LarderSeed.buildLarderItems().map(_larderJson).toList()
      : Villa102ExperiencesSeed.buildExperiences()
          .map(_experienceJson)
          .toList();
  return http.Response(
    jsonEncode({'success': true, 'data': data}),
    200,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

Map<String, Object?> _larderJson(LarderItem i) => {
      'id': i.id,
      'name': i.name,
      'origin': i.origin,
      'description': i.description,
      'price': i.priceUsd,
      'category': i.category,
      'tag': i.tag,
      'storageType': i.storageType,
      'dietary': i.dietaryBadge,
    };

Map<String, Object?> _experienceJson(ExperienceItem e) => {
      'id': e.id,
      'title': e.title,
      'subtitle': e.subtitle,
      'duration': e.duration,
      'location': e.location,
      'priceText': e.priceText,
      'priceUSD': e.priceUsd,
      'isIncluded': e.isIncluded,
      'category': e.category,
      'description': e.description,
      'amenities': e.amenities,
      'actionScreen': e.targetScreenWireId,
    };
