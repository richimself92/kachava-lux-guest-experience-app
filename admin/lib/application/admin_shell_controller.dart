import 'package:flutter/foundation.dart';

import '../core/admin_i18n.dart';
import '../domain/admin_enums.dart';
import '../domain/staff_member.dart';
import 'list_query_store.dart';

/// A record another screen asked to open (e.g. a notification's target).
class AdminOpenRequest {
  const AdminOpenRequest(this.tab, this.id, {this.section});

  final AdminWorkspaceTab tab;
  final String id;

  /// Sub-tab of the target screen (e.g. Guests › `messages`).
  final String? section;
}

/// Shell state: language, active workspace, per-list queries, the staff
/// roster and cross-screen "open this record" requests. Holds no business
/// data: every screen reads its own server-paged list.
class AdminShellController extends ChangeNotifier {
  AdminShellController({StaffDirectoryRepository? staff}) : _staff = staff;

  final StaffDirectoryRepository? _staff;
  AdminLocale _locale = AdminLocale.en;
  AdminWorkspaceTab _activeTab = AdminWorkspaceTab.adminOverview;
  List<StaffMember> _staffDirectory = const [];
  AdminOpenRequest? _pending;
  bool _disposed = false;

  /// Per-screen list search/filters/sort/page, kept while navigating.
  final ListQueryStore listQueries = ListQueryStore();

  AdminLocale get locale => _locale;
  bool get isEs => _locale == AdminLocale.es;
  AdminWorkspaceTab get activeTab => _activeTab;
  List<StaffMember> get staffDirectory => _staffDirectory;

  /// Best effort: without it owner pickers offer no names.
  Future<void> loadStaff() async {
    final staff = _staff;
    if (staff == null) return;
    try {
      final list = await staff.list();
      _update(() => _staffDirectory = list);
    } catch (error) {
      debugPrint('Staff roster unavailable: $error');
    }
  }

  void toggleLocale() => _update(() {
        _locale = isEs ? AdminLocale.en : AdminLocale.es;
        AdminI18n.currentIsEs = isEs;
      });

  void selectTab(AdminWorkspaceTab tab) => _update(() {
        _activeTab = tab;
        _pending = null;
      });

  /// Selects [tab] and asks it to open record [id] (optionally in [section]).
  void openRecord(AdminWorkspaceTab tab, String id, {String? section}) =>
      _update(() {
        _activeTab = tab;
        _pending = AdminOpenRequest(tab, id, section: section);
      });

  /// The pending request for [tab] (consumed: returned once).
  AdminOpenRequest? takeOpenRequest(AdminWorkspaceTab tab) {
    final pending = _pending;
    if (pending == null || pending.tab != tab) return null;
    _pending = null;
    return pending;
  }

  /// The pending request for [tab] without consuming it.
  AdminOpenRequest? peekOpenRequest(AdminWorkspaceTab tab) =>
      _pending?.tab == tab ? _pending : null;

  void _update(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
