import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/service_catalog_strings.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/catalog_rule_violation.dart';
import 'package:kachava_admin_dashboard/domain/json_draft.dart';

AdminApiException _apiError(int status, String message) => AdminApiException(
    statusCode: status,
    message: 'Admin API HTTP $status: '
        '{"success":false,"statusCode":$status,"error":"UnprocessableEntity",'
        '"message":"$message","path":"/api/v1/admin/services/s1"}');

void main() {
  group('JsonDraft', () {
    test('reads and writes nested paths on a private deep copy', () {
      final source = <String, dynamic>{
        'pricing': {
          'note': {'en': 'a'}
        },
        'tags': ['x'],
      };
      final draft = JsonDraft(source);
      expect(draft.text('pricing.note.en'), 'a');
      draft.set('pricing.note.es', 'b');
      draft.set('availability.minLeadHours', 4);
      (draft.get('tags') as List).add('y');
      expect(draft.text('pricing.note.es'), 'b');
      expect(draft.intOrNull('availability.minLeadHours'), 4);
      expect(source['pricing'], {
        'note': {'en': 'a'}
      });
      expect(source['tags'], ['x']);
      expect(draft.json['availability'], {'minLeadHours': 4});
    });

    test('typed readers are tolerant', () {
      final draft = JsonDraft({
        'a': 'x',
        'b': true,
        'c': ['p', 3]
      });
      expect(draft.intOrNull('a'), isNull);
      expect(draft.flag('b'), isTrue);
      expect(draft.flag('missing.deep'), isFalse);
      expect(draft.strings('c'), ['p', '3']);
      expect(draft.text('missing'), '');
    });

    test('remove drops a key', () {
      final draft = JsonDraft({'bar': {}, 'kind': 'BAR'});
      draft.remove('bar');
      expect(draft.json.containsKey('bar'), isFalse);
    });
  });

  group('CatalogRuleViolation', () {
    test('parses the 422 activation problems', () {
      final violation = CatalogRuleViolation.tryParse(_apiError(422,
          'Service cannot be active: cover image is required; name.es is required; shortDescription.en is required'));
      expect(violation?.problems, [
        'cover image is required',
        'name.es is required',
        'shortDescription.en is required',
      ]);
    });

    test('a 422 without details keeps the message', () {
      final violation = CatalogRuleViolation.tryParse(
          _apiError(422, 'The kind of a service cannot be changed'));
      expect(violation?.problems, ['The kind of a service cannot be changed']);
    });

    test('other errors are not rule violations', () {
      expect(CatalogRuleViolation.tryParse(_apiError(400, 'bad')), isNull);
      expect(CatalogRuleViolation.tryParse(StateError('x')), isNull);
    });

    test('short EN/ES labels for the activation rules', () {
      const s = ServiceCatalogStrings(false);
      const es = ServiceCatalogStrings(true);
      expect(s.problem('cover image is required'), 'Cover required');
      expect(es.problem('cover image is required'), 'Portada obligatoria');
      expect(s.problem('name.es is required'), 'Name ES required');
      expect(s.problem('shortDescription.en is required'),
          'Short text EN required');
      expect(es.problem('shortDescription.es is required'),
          'Texto corto ES obligatorio');
      expect(s.problem('Item cannot be active'), 'Item cannot be active');
      expect(s.problems(['cover image is required', 'name.es is required']),
          'Cover required · Name ES required');
    });
  });
}
