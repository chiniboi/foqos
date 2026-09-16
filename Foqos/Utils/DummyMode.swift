import Foundation

/// Screen Time (Apple's FamilyControls entitlement) is only available to paid
/// developer accounts, so a build signed with a free personal team cannot block
/// anything. Dummy mode keeps the whole app usable on such a build: the UI,
/// profiles, QR scanning and break timers all work, but restrictions are never
/// really applied.
///
/// Set this to false once the app is signed by a team that has the Family
/// Controls entitlement.
enum DummyMode {
  static let isEnabled = true

  /// Shown wherever the app would otherwise claim apps are blocked.
  static let banner = "Demo build - apps are not really blocked"
}
