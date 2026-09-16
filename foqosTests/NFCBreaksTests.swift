import SwiftData
import XCTest

@testable import foqos

@MainActor
final class NFCBreaksTests: XCTestCase {
  private enum SchedulerError: LocalizedError {
    case unavailable

    var errorDescription: String? {
      return "Device Activity is unavailable"
    }
  }

  private let kitchenTag = PhysicalUnblockItem(
    name: "Kitchen",
    type: .nfc,
    codeValue: "04AABBCC11223344",
    breakDurationInMinutes: 15,
    breakCount: 2
  )

  private let carTag = PhysicalUnblockItem(
    name: "Car",
    type: .nfc,
    codeValue: "04DDEEFF55667788",
    breakDurationInMinutes: 120,
    breakCount: 1
  )

  override func setUp() {
    super.setUp()
    SharedData.flushActiveSession()
  }

  override func tearDown() {
    SharedData.flushActiveSession()
    super.tearDown()
  }

  // MARK: - Per-tag settings

  func testSettingsFallBackToDefaultsWhenUnset() {
    let item = PhysicalUnblockItem(name: "Sofa", type: .nfc, codeValue: "AA")

    XCTAssertEqual(
      item.resolvedBreakDurationInMinutes,
      PhysicalUnblockItem.defaultBreakDurationInMinutes
    )
    XCTAssertEqual(item.resolvedBreakCount, PhysicalUnblockItem.defaultBreakCount)
  }

  func testSettingsClampToWhatTheUIOffers() {
    let tooLong = PhysicalUnblockItem(
      name: "Car",
      type: .nfc,
      codeValue: "AA",
      breakDurationInMinutes: 600,
      breakCount: 9
    )
    let tooShort = PhysicalUnblockItem(
      name: "Sofa",
      type: .nfc,
      codeValue: "BB",
      breakDurationInMinutes: 1,
      breakCount: 0
    )

    XCTAssertEqual(tooLong.resolvedBreakDurationInMinutes, 120)
    XCTAssertEqual(tooLong.resolvedBreakCount, 3)
    XCTAssertEqual(tooShort.resolvedBreakDurationInMinutes, 10)
    XCTAssertEqual(tooShort.resolvedBreakCount, 1)
  }

  func testNormalizingItemsKeepsBreakSettings() {
    let normalized = PhysicalUnblockItem.normalizedItems([kitchenTag])?.first

    XCTAssertEqual(normalized?.breakDurationInMinutes, 15)
    XCTAssertEqual(normalized?.breakCount, 2)
  }

  // MARK: - Taking a break with a tag

  func testBreakRunsForTheScannedTagsDuration() throws {
    let context = try makeContext()
    let session = try makeActiveSession(context: context)
    var scheduledDuration: TimeInterval?

    try StrategyManager().startTagBreak(
      context: context,
      session: session,
      item: carTag,
      scheduleBreak: { _, duration in scheduledDuration = duration }
    )

    XCTAssertEqual(scheduledDuration, 120 * 60)
    XCTAssertTrue(session.isBreakActive)
    XCTAssertEqual(session.activeBreakTagID, carTag.id.uuidString)
    XCTAssertEqual(session.breaksUsed(for: carTag), 1)
    XCTAssertEqual(session.breaksRemaining(for: carTag), 0)
  }

  func testEachTagKeepsItsOwnCount() throws {
    let context = try makeContext()
    let session = try makeActiveSession(context: context)
    let manager = StrategyManager()

    try manager.startTagBreak(
      context: context,
      session: session,
      item: kitchenTag,
      scheduleBreak: { _, _ in }
    )
    session.endBreak()

    XCTAssertEqual(session.breaksRemaining(for: kitchenTag), 1)
    XCTAssertEqual(session.breaksRemaining(for: carTag), 1)
    XCTAssertNil(session.activeBreakTagID, "Ending a break should release the tag")
  }

  func testTagRefusesMoreBreaksThanItIsWorth() throws {
    let context = try makeContext()
    let session = try makeActiveSession(context: context)
    let manager = StrategyManager()

    for _ in 0..<2 {
      try manager.startTagBreak(
        context: context,
        session: session,
        item: kitchenTag,
        scheduleBreak: { _, _ in }
      )
      session.endBreak()
    }

    XCTAssertThrowsError(
      try manager.startTagBreak(
        context: context,
        session: session,
        item: kitchenTag,
        scheduleBreak: { _, _ in }
      )
    ) { error in
      XCTAssertEqual(
        error as? BreakSessionError,
        BreakSessionError.tagExhausted(tagName: "Kitchen")
      )
    }

    // The other tag is untouched by the kitchen tag running out.
    XCTAssertEqual(session.breaksRemaining(for: carTag), 1)
  }

  func testBreakIsNotConsumedWhenItCannotBeScheduled() throws {
    let context = try makeContext()
    let session = try makeActiveSession(context: context)

    XCTAssertThrowsError(
      try StrategyManager().startTagBreak(
        context: context,
        session: session,
        item: kitchenTag,
        scheduleBreak: { _, _ in throw SchedulerError.unavailable }
      )
    )

    XCTAssertFalse(session.isBreakActive)
    XCTAssertEqual(session.breaksUsed(for: kitchenTag), 0)
  }

  // MARK: - Helpers

  private func makeContext() throws -> ModelContext {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: BlockedProfileSession.self,
      BlockedProfiles.self,
      configurations: configuration
    )
    return ModelContext(container)
  }

  private func makeActiveSession(context: ModelContext) throws -> BlockedProfileSession {
    let items = [kitchenTag, carTag]
    let profile = BlockedProfiles(
      name: "Night",
      blockingStrategyId: NFCBreaksBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: items.reduce(0) { $0 + $1.totalBreakAllowanceInMinutes },
      allowMultipleBreaks: true,
      physicalUnblockItems: items
    )
    context.insert(profile)

    let session = BlockedProfileSession.createSession(
      in: context,
      withTag: NFCBreaksBlockingStrategy.id,
      withProfile: profile,
      forceStart: false
    )
    try context.save()
    return session
  }
}
