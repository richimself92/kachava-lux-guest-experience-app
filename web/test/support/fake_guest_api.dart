import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/core/platform/photo_picker.dart';
import 'package:kachava_guest_portal/core/pwa/install_prompt_port.dart';
import 'package:kachava_guest_portal/core/storage/device_prefs.dart';
import 'package:kachava_guest_portal/core/storage/guest_id_store.dart';
import 'package:kachava_guest_portal/data/guest_api.dart';
import 'package:kachava_guest_portal/domain/catalog.dart';
import 'package:kachava_guest_portal/domain/json_read.dart';
import 'package:kachava_guest_portal/domain/resort_clock.dart';
import 'package:kachava_guest_portal/domain/stay.dart';
import 'package:kachava_guest_portal/domain/trip.dart';
import 'package:kachava_guest_portal/main.dart';

import 'fixtures.dart';

/// In-memory backend: serves JSON like the real API and records writes.
class FakeGuestApi implements GuestApi {
  FakeGuestApi({Json? stay, List<Json>? catalog, List<Json>? trips})
      : stayJsonValue = stay ?? stayJson(),
        catalogJson = catalog ?? [],
        tripsJson = trips ?? [];

  Json stayJsonValue;
  List<Json> catalogJson;
  List<Json> tripsJson;
  FailureKind? stayFailure;
  FailureKind? catalogFailure;
  FailureKind? writeFailure;
  Completer<void>? stayGate;
  final List<(String, Object?)> writes = [];
  int stayFetches = 0;

  ApiResult<T> _fail<T>(FailureKind kind) => ApiFailed<T>(kind);

  @override
  Future<ApiResult<GuestStay>> fetchStay(String guestUuid) async {
    stayFetches++;
    if (stayGate != null) await stayGate!.future;
    if (stayFailure != null) return _fail(stayFailure!);
    return ApiOk(GuestStay.fromJson(guestUuid, stayJsonValue));
  }

  @override
  Future<ApiResult<List<CatalogService>>> fetchCatalog() async {
    if (catalogFailure != null) return _fail(catalogFailure!);
    return ApiOk(catalogJson.map(CatalogService.fromJson).toList());
  }

  @override
  Future<ApiResult<List<GuestTrip>>> fetchTrips(String guestUuid) async =>
      ApiOk(tripsJson.map(GuestTrip.fromJson).toList());

  Future<ApiResult<T>> _write<T>(String name, Object? body, T value) async {
    writes.add((name, body));
    if (writeFailure != null) return _fail(writeFailure!);
    return ApiOk(value);
  }

  @override
  Future<ApiResult<void>> saveOrder(String guestUuid, Json payload) =>
      _write('order', payload, null);

  @override
  Future<ApiResult<void>> saveJourney(String guestUuid,
      {Set<String>? skippedTaskIds, Set<String>? completedTaskIds}) async {
    final body = {
      if (skippedTaskIds != null) 'skippedTaskIds': skippedTaskIds.toList(),
      if (completedTaskIds != null)
        'completedTaskIds': completedTaskIds.toList(),
    };
    final r = await _write('journey', body, null);
    if (r is ApiOk) stayJsonValue = {...stayJsonValue, ...body};
    return r;
  }

  @override
  Future<ApiResult<void>> cancelBooking(
      String guestUuid, String bookingId) async {
    final r = await _write('cancelBooking', bookingId, null);
    if (r is ApiOk) {
      stayJsonValue = {
        ...stayJsonValue,
        'experienceBookings': [
          for (final b in asJsonList(stayJsonValue['experienceBookings']))
            b['bookingId'] == bookingId ? {...b, 'status': 'CANCELLED'} : b,
        ],
      };
    }
    return r;
  }

  @override
  Future<ApiResult<void>> changeBooking(
          String guestUuid, String bookingId, Json change) =>
      _write('changeBooking', {'bookingId': bookingId, ...change}, null);

  @override
  Future<ApiResult<void>> cancelTrip(String guestUuid, String tripId) async {
    final r = await _write('cancelTrip', tripId, null);
    if (r is ApiOk) {
      tripsJson = [
        for (final t in tripsJson)
          t['id'] == tripId ? {...t, 'status': 'CANCELLED'} : t,
      ];
    }
    return r;
  }

  @override
  Future<ApiResult<void>> createBooking(String guestUuid, Json payload) =>
      _write('booking', payload, null);

  @override
  Future<ApiResult<GuestTrip>> createTrip(
      String guestUuid, Json payload) async {
    final r = await _write('trip', payload, null);
    if (r is ApiFailed) return ApiFailed((r as ApiFailed).kind);
    final trip =
        tripJson('new${tripsJson.length}', type: payload['type'] as String);
    tripsJson = [...tripsJson, trip];
    return ApiOk(GuestTrip.fromJson(trip));
  }

  @override
  Future<ApiResult<void>> savePreferences(String guestUuid,
      {required String dietary, required List<String> allergies}) async {
    final r = await _write(
        'preferences', {'dietary': dietary, 'allergies': allergies}, null);
    if (r is ApiOk) {
      stayJsonValue = {
        ...stayJsonValue,
        'personalization': {'dietary': dietary, 'dietaryAllergies': allergies},
      };
    }
    return r;
  }

  @override
  Future<ApiResult<void>> sendRating(
          String guestUuid, int rating, String note) =>
      _write('rating', {'rating': rating, 'note': note}, null);

  @override
  Future<ApiResult<String>> startHostThread(String guestUuid,
          {required String text, String? photoStoragePath}) =>
      _write('thread', {'text': text, 'photo': photoStoragePath}, 'req_1');

  @override
  Future<ApiResult<void>> sendHostMessage(
          String guestUuid, String threadId, String text,
          {String? photoStoragePath}) =>
      _write(
          'message',
          {
            'thread': threadId,
            'text': text,
            if (photoStoragePath != null) 'photo': photoStoragePath,
          },
          null);

  @override
  Future<ApiResult<String>> uploadPhoto(String guestUuid, PickedPhoto photo,
          {String? threadId}) =>
      _write('upload', photo.fileName,
          '/private/stays/s1/concierge/${threadId ?? 'x'}/${photo.fileName}');

  @override
  void dispose() {}
}

class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker([this.photo]);
  final PickedPhoto? photo;

  @override
  Future<PickedPhoto?> pick() async => photo;
}

final PickedPhoto samplePhoto = PickedPhoto(
  fileName: 'leak.jpg',
  contentType: 'image/jpeg',
  bytes: Uint8List.fromList(List.filled(32, 7)),
);

class FakeInstallPrompt extends ChangeNotifier implements InstallPromptPort {
  FakeInstallPrompt(
      {this.isStandalone = false,
      this.isIos = false,
      this.canPromptNative = false});

  @override
  bool isStandalone, isIos, canPromptNative;
  @override
  bool isDismissed = false;
  int promptCalls = 0;

  @override
  void dismiss() {
    isDismissed = true;
    notifyListeners();
  }

  @override
  Future<bool> promptNative() async {
    promptCalls++;
    canPromptNative = false;
    notifyListeners();
    return true;
  }
}

/// Resort clock pinned to a wall time (UTC+0 value = resort wall time).
ResortClock clockAt(DateTime wall) =>
    ResortClock(() => wall.add(const Duration(hours: 5)));

Uri portalUri([String? id = guestUuid]) => Uri.parse(
    'https://guest.kachavalux.com/${id == null ? '' : '?guestId=$id'}');

/// Pumps the whole app on a phone-sized view.
Future<FakeGuestApi> pumpPortal(
  WidgetTester tester, {
  FakeGuestApi? api,
  Size size = const Size(390, 844),
  DevicePrefs? prefs,
  GuestIdStore? store,
  Uri? uri,
  PhotoPicker? picker,
  InstallPromptPort? install,
  DateTime? now,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fake = api ?? FakeGuestApi();
  await tester.pumpWidget(KachavaGuestPortalApp(
    key: UniqueKey(),
    api: fake,
    prefs: prefs ?? MemoryDevicePrefs(),
    guestIdStore: store ?? MemoryGuestIdStore(),
    initialUri: uri ?? portalUri(),
    photoPicker: picker ?? FakePhotoPicker(),
    installPrompt: install ?? FakeInstallPrompt(),
    clock: clockAt(now ?? DateTime.utc(2026, 11, 1, 10)),
    pollInterval: const Duration(days: 1),
  ));
  await tester.pumpAndSettle();
  return fake;
}

/// Unmounts the app so the poll timer is cancelled before the test ends.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}
