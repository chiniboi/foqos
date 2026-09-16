import SwiftData
import SwiftUI

/// Keeps a profile blocked for the whole session and lets individual NFC tags
/// buy their own breaks. Each tag carries its own break length and how many
/// breaks it is allowed per session, so a tag on the sofa can be worth a short
/// break while a tag in the car is worth a long one.
class NFCBreaksBlockingStrategy: BlockingStrategy {
  static var id: String = "NFCBreaksBlockingStrategy"

  var name: String = "NFC Breaks"
  var description: String =
    "Stays blocked for the whole session. Scan one of your NFC tags to take that tag's break, "
    + "then scan the same tag again to lock back early."
  var color: Color = .indigo
  var pickerCategory: BlockingStrategyPickerCategory = .mostPopular

  var usesNFC: Bool = true
  var startsManually: Bool = true
  var allowsTimedBreaks: Bool = true

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return NFCBreaksBlockingStrategy.id
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
        withTag: NFCBreaksBlockingStrategy.id,
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
