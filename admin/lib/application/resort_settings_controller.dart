import 'package:flutter/foundation.dart';

import '../domain/admin_catalog_repositories.dart';
import '../domain/admin_settings.dart';

/// Load state of the resort settings.
enum ResortSettingsStatus { loading, ready, error }

/// A value another screen may need from Settings.
enum ResortSetting { checkInTime, checkOutTime, timeZone, airports, alertLead }

/// Shared, server-confirmed resort settings. The Settings screen edits them;
/// other screens ask [isMissing] to show a one-line "Set up in Settings"
/// link. Nothing has a default: a failed load is an error, not a guess.
class ResortSettingsController extends ChangeNotifier {
  ResortSettingsController(this._repository);

  final AdminSettingsRepository _repository;
  AdminSettings? _settings;
  Object? _error;
  bool _loading = true;
  bool _disposed = false;

  AdminSettings? get settings => _settings;
  Object? get error => _error;

  ResortSettingsStatus get status {
    if (_settings != null && !_loading) return ResortSettingsStatus.ready;
    if (_error != null) return ResortSettingsStatus.error;
    return ResortSettingsStatus.loading;
  }

  /// True only when the settings loaded and [setting] is not configured
  /// (unknown is not missing).
  bool isMissing(ResortSetting setting) {
    final s = _settings;
    if (s == null) return false;
    return switch (setting) {
      ResortSetting.checkInTime => s.checkInTime == null,
      ResortSetting.checkOutTime => s.checkOutTime == null,
      ResortSetting.timeZone => s.timeZone == null,
      ResortSetting.airports => s.airports.isEmpty,
      ResortSetting.alertLead => s.transportAlertLeadHours == null,
    };
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      _settings = await _repository.fetch();
    } catch (error) {
      _error = error;
    }
    _loading = false;
    _notify();
  }

  /// Saves and keeps the server answer; failures propagate unchanged.
  Future<AdminSettings> save(AdminSettings next) async {
    final saved = await _repository.update(next);
    _settings = saved;
    _error = null;
    _notify();
    return saved;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
