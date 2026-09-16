import Foundation

enum SessionTimeCalculator {
  static let countdownReloadDelay: TimeInterval = 30
  static let countdownResetGracePeriod: TimeInterval = 90

  private static let timerStrategyIds: Set<String> = [
    NFCTimerBlockingStrategy.id,
    QRTimerBlockingStrategy.id,
    ShortcutTimerBlockingStrategy.id,
  ]

  static func elapsedFocusTime(
    for session: BlockedProfileSession,
    at date: Date = Date()
  ) -> TimeInterval {
    let rawElapsedTime = date.timeIntervalSince(session.startTime)
    let breakDuration = calculateBreakDuration(for: session, at: date)
    return max(0, rawElapsedTime - breakDuration)
  }

  static func displayedTime(
    for session: BlockedProfileSession,
    elapsedFocusTime: TimeInterval? = nil,
    at date: Date = Date()
  ) -> TimeInterval {
    if let expectedEndTime = expectedEndTime(for: session) {
      return max(0, expectedEndTime.timeIntervalSince(date))
    }

    return elapsedFocusTime ?? self.elapsedFocusTime(for: session, at: date)
  }

  static func isCountdownExpired(
    for session: BlockedProfileSession,
    at date: Date = Date()
  ) -> Bool {
    guard let expectedEndTime = expectedEndTime(for: session) else {
      return false
    }

    return expectedEndTime.addingTimeInterval(countdownResetGracePeriod) <= date
  }

  static func isCountdownReloadDue(
    for session: BlockedProfileSession,
    at date: Date = Date()
  ) -> Bool {
    guard let expectedEndTime = expectedEndTime(for: session) else {
      return false
    }

    return expectedEndTime.addingTimeInterval(countdownReloadDelay) <= date
  }

  static func expectedEndTime(for session: BlockedProfileSession) -> Date? {
    if let pauseStartTime = session.pauseStartTime, session.isPauseActive {
      return pauseStartTime.addingTimeInterval(pauseDurationInSeconds(for: session.blockedProfile))
    }

    if let breakStartTime = session.breakStartTime, session.isBreakActive {
      // Tag breaks last exactly as long as the scanned tag is worth.
      if let item = session.activeBreakItem(
        in: session.blockedProfile.physicalUnblockItems ?? []
      ) {
        return breakStartTime.addingTimeInterval(
          TimeInterval(item.resolvedBreakDurationInMinutes * 60)
        )
      }

      if session.blockedProfile.allowMultipleBreaks {
        let remainingAllowanceAtBreakStart = session.remainingBreakAllowance(at: breakStartTime)
        return breakStartTime.addingTimeInterval(remainingAllowanceAtBreakStart)
      }

      return breakStartTime.addingTimeInterval(session.totalBreakAllowanceInSeconds)
    }

    return expectedSessionEndTime(for: session)
  }

  static func expectedSessionEndTime(for session: BlockedProfileSession) -> Date? {
    if isScheduledSession(session), let schedule = session.blockedProfile.schedule {
      let durationInSeconds = schedule.totalDurationInSeconds
      guard durationInSeconds > 0 else { return nil }
      return session.startTime.addingTimeInterval(TimeInterval(durationInSeconds))
    }

    if isTimerSession(session), let timerDuration = timerDurationInSeconds(for: session) {
      return session.startTime.addingTimeInterval(timerDuration)
    }

    // A profile with a schedule always has an end in sight, even when the
    // session was started by hand, so the clock can count down to it.
    return scheduledBlockEndTime(for: session)
  }

  /// The next time this profile's schedule lets go, counted from the session start.
  static func scheduledBlockEndTime(for session: BlockedProfileSession) -> Date? {
    guard let schedule = session.blockedProfile.schedule, schedule.isActive else {
      return nil
    }

    let calendar = Calendar.current
    let start = session.startTime

    guard
      let sameDayEnd = calendar.date(
        bySettingHour: schedule.endHour,
        minute: schedule.endMinute,
        second: 0,
        of: start
      )
    else {
      return nil
    }

    if sameDayEnd > start {
      return sameDayEnd
    }

    // The block runs past midnight, so it ends tomorrow.
    return calendar.date(byAdding: .day, value: 1, to: sameDayEnd)
  }

  static func isTimerSession(_ session: BlockedProfileSession) -> Bool {
    Self.timerStrategyIds.contains(session.tag)
      || Self.timerStrategyIds.contains(session.blockedProfile.blockingStrategyId ?? "")
  }

  static func timerDurationInSeconds(for session: BlockedProfileSession) -> TimeInterval? {
    guard let strategyData = session.blockedProfile.strategyData else {
      return nil
    }

    let timerData = StrategyTimerData.toStrategyTimerData(from: strategyData)
    return TimeInterval(timerData.durationInMinutes * 60)
  }

  private static func isScheduledSession(_ session: BlockedProfileSession) -> Bool {
    session.blockedProfile.schedule?.isActive == true && UUID(uuidString: session.tag) != nil
  }

  private static func pauseDurationInSeconds(for profile: BlockedProfiles) -> TimeInterval {
    guard let strategyData = profile.strategyData else {
      return TimeInterval(15 * 60)
    }

    let pauseData = StrategyPauseTimerData.toStrategyPauseTimerData(from: strategyData)
    return TimeInterval(pauseData.pauseDurationInMinutes * 60)
  }

  private static func calculateBreakDuration(
    for session: BlockedProfileSession,
    at date: Date
  ) -> TimeInterval {
    if session.blockedProfile.allowMultipleBreaks {
      return session.usedBreakDurationIncludingActiveBreak(at: date)
    }

    guard let breakStartTime = session.breakStartTime else {
      return 0
    }

    if let breakEndTime = session.breakEndTime {
      return max(0, breakEndTime.timeIntervalSince(breakStartTime))
    }

    if session.isBreakActive {
      return max(0, date.timeIntervalSince(breakStartTime))
    }

    return 0
  }
}
