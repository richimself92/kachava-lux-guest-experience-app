import 'package:flutter/foundation.dart';

import '../domain/admin_stay_entities.dart';

/// Staff session for `/api/v1/admin/*`: holds the bearer token issued by the
/// silent `POST /admin/auth/login` and the [staff] member it returned.
/// Listeners are notified when the session opens or expires.
class AdminSession extends ChangeNotifier {
  AdminSession({String? token, StaffMember? staff})
      : _token = token,
        _staff = staff;

  String? _token;
  StaffMember? _staff;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  /// The signed-in staff member, or null when the server did not identify one.
  StaffMember? get staff => _staff;

  void open(String token, {StaffMember? staff}) {
    _token = token;
    _staff = staff;
    notifyListeners();
  }

  /// Drops the token (e.g. after a 401). No-op when already signed out.
  void expire() {
    if (_token == null) return;
    _token = null;
    _staff = null;
    notifyListeners();
  }
}
