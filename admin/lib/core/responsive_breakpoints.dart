/// Responsive viewport classifications for the Kachava Lux Admin Dashboard.
enum AdminViewportSize {
  /// Mobile smartphone browser (< 600px) — Roaming Majordomo View.
  mobile,

  /// Tablet browser (600px – 1023px) — Hybrid 2-pane layout with compact rail.
  tablet,

  /// Desktop & Widescreen browser (>= 1024px) — 3-pane Command Center.
  desktop,
}

/// Breakpoint resolver matching UI/UX Section 6.1.
class AdminBreakpoints {
  const AdminBreakpoints._();

  static const double mobileMaxWidth = 600.0;
  static const double desktopMinWidth = 1024.0;
  static const double leftRailDesktopWidth = 260.0;
  static const double leftRailTabletWidth = 72.0;
  static const double inspectorDrawerWidth = 420.0;
  static const double topBarHeight = 64.0;

  /// Resolves the [AdminViewportSize] from a given screen [width].
  static AdminViewportSize resolve(double width) {
    if (width < mobileMaxWidth) {
      return AdminViewportSize.mobile;
    }
    if (width < desktopMinWidth) {
      return AdminViewportSize.tablet;
    }
    return AdminViewportSize.desktop;
  }
}
