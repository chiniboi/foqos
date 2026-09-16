import Foundation
import SwiftData

@Model
class BlockedProfileSession {
  @Attribute(.unique) var id: String
  var tag: String

  @Relationship var blockedProfile: BlockedProfiles

  var startTime: Date
  var endTime: Date?

  var breakStartTime: Date?
  var breakEndTime: Date?
  var usedBreakDurationInSeconds: TimeInterval = 0

  /// Breaks taken per physical unblock item, keyed by the item's id. Only the
  /// NFC Breaks strategy writes these; every other strategy leaves it empty.
  var tagBreakUsage: [String: Int] = [:]

  /// The item whose break is currently running, so only that tag can end it.
  var activeBreakTagID: String?

  var pauseStartTime: Date?
  var pauseEndTime: Date?

  var forceStarted: Bool = false

  init(
    tag: String,
    blockedProfile: BlockedProfiles,
    forceStarted: Bool = false
  ) {
    self.id = UUID().uuidString
    self.tag = tag
    self.blockedProfile = blockedProfile
    self.startTime = Date()
    self.forceStarted = forceStarted

    // Add this session to the profile's sessions array
    blockedProfile.sessions.append(self)
  }
}
