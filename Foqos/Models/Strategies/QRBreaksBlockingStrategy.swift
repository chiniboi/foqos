import SwiftData
import SwiftUI

/// Keeps a profile blocked for the whole session and lets individual QR codes
/// buy their own breaks. Each code carries its own break length and how many
/// breaks it is allowed per session, so a sticker on the sofa can be worth a
/// short break while one in the car is worth a long one.
class QRBreaksBlockingStrategy: BlockingStrategy {
  static var id: String = "QRBreaksBlockingStrategy"

  var name: String = "QR Breaks"
  var description: String =
    "Stays blocked for the whole session. Scan one of your QR codes to take that code's break, "
    + "and lock back early whenever you want."
  var color: Color = .indigo
  var pickerCategory: BlockingStrategyPickerCategory = .mostPopular

  var usesQRCode: Bool = true
  var startsManually: Bool = true
  var allowsTimedBreaks: Bool = true
  // The session only ends on its schedule: breaks are the way out, not stopping.
  var allowsManualStop: Bool = false

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return QRBreaksBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    self.appBlocker
      .activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))

    let activeSession =
      BlockedProfileSession
      .createSession(
        in: context,
        withTag: QRBreaksBlockingStrategy.id,
        withProfile: profile,
        forceStart: forceStart ?? false
      )

    self.onSessionCreation?(.started(activeSession))

    return nil
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    DeviceActivityCenterUtil.removeBreakTimerActivity(for: session.blockedProfile)

    session.endSession()
    try? context.save()
    self.appBlocker.deactivateRestrictions()

    self.onSessionCreation?(.ended(session.blockedProfile))

    return nil
  }
}
