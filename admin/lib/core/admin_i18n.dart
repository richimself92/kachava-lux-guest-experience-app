import '../domain/admin_enums.dart';
import 'status_vocabulary.dart';

/// Supported admin locales (English default and Español).
enum AdminLocale { en, es }

/// Shared EN/ES helpers. Screen copy lives in each screen's strings class;
/// nothing here translates free text automatically.
class AdminI18n {
  const AdminI18n._();

  static bool currentIsEs = false;

  static String tr(bool isEs, String en, String es) => isEs ? es : en;

  /// Placeholder for a value the server did not send (never invented).
  static String orDash(String? value) =>
      (value ?? '').trim().isEmpty ? '—' : value!;

  /// Staff name, or "Unassigned" when the server has no known assignee.
  static String staffLabel(String? name, bool isEs) =>
      (name ?? '').trim().isEmpty
          ? tr(isEs, 'Unassigned', 'Sin asignar')
          : name!;

  /// Short status label from the single [StatusVocabulary]; unknown values
  /// are humanized (never a raw enum).
  static String statusLabel(String raw, [bool? isEs]) =>
      StatusVocabulary.label(raw, isEs: isEs ?? currentIsEs);

  static String tabLabel(AdminWorkspaceTab tab, bool isEs) =>
      isEs ? tab.labelEs : tab.label;

  static String tabShortLabel(AdminWorkspaceTab tab, bool isEs) =>
      tabLabel(tab, isEs);
}
