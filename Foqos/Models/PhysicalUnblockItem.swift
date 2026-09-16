import Foundation

/// Represents a physical NFC tag or QR code that can unblock a profile
/// Supports having multiple NFC tags and/or QR codes per profile
struct PhysicalUnblockItem: Codable, Hashable, Identifiable, Sendable {
  var id: UUID
  var name: String
  var type: PhysicalUnblockType
  var codeValue: String

  /// Break settings used by the NFC Breaks strategy. Optional so items saved
  /// before this existed keep decoding.
  var breakDurationInMinutes: Int?
  var breakCount: Int?

  enum PhysicalUnblockType: String, Codable, CaseIterable, Sendable {
    case nfc = "nfc"
    case qrCode = "qrCode"

    var displayName: String {
      switch self {
      case .nfc: return "NFC Tag"
      case .qrCode: return "QR Code"
      }
    }
  }

  init(
    id: UUID = UUID(),
    name: String,
    type: PhysicalUnblockType,
    codeValue: String,
    breakDurationInMinutes: Int? = nil,
    breakCount: Int? = nil
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.codeValue = codeValue
    self.breakDurationInMinutes = breakDurationInMinutes
    self.breakCount = breakCount
  }

  static func resolvedItems(
    physicalUnblockItems: [PhysicalUnblockItem]?,
    legacyNFCTagId: String? = nil,
    legacyQRCodeId: String? = nil
  ) -> [PhysicalUnblockItem]? {
    if let physicalUnblockItems {
      return normalizedItems(physicalUnblockItems)
    }

    var items: [PhysicalUnblockItem] = []

    if let legacyNFCTagId, !legacyNFCTagId.isEmpty {
      items.append(
        PhysicalUnblockItem(
          name: "NFC Tag",
          type: .nfc,
          codeValue: legacyNFCTagId
        )
      )
    }

    if let legacyQRCodeId, !legacyQRCodeId.isEmpty {
      items.append(
        PhysicalUnblockItem(
          name: "QR Code",
          type: .qrCode,
          codeValue: legacyQRCodeId
        )
      )
    }

    return normalizedItems(items)
  }

  static func normalizedItems(_ items: [PhysicalUnblockItem]?) -> [PhysicalUnblockItem]? {
    guard let items else { return nil }

    let normalizedItems = items.compactMap { item -> PhysicalUnblockItem? in
      let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
      let normalizedCodeValue = normalizedCodeValue(item.codeValue, type: item.type)

      guard !normalizedCodeValue.isEmpty else { return nil }

      return PhysicalUnblockItem(
        id: item.id,
        name: trimmedName.isEmpty ? item.type.displayName : trimmedName,
        type: item.type,
        codeValue: normalizedCodeValue,
        breakDurationInMinutes: item.breakDurationInMinutes,
        breakCount: item.breakCount
      )
    }

    return normalizedItems.isEmpty ? nil : normalizedItems
  }

  static func normalizedCodeValue(
    _ codeValue: String,
    type: PhysicalUnblockType
  ) -> String {
    let trimmedCodeValue = codeValue.trimmingCharacters(in: .whitespacesAndNewlines)

    guard type == .qrCode,
      var components = URLComponents(string: trimmedCodeValue),
      components.scheme != nil,
      components.host != nil
    else {
      return trimmedCodeValue
    }

    components.scheme = components.scheme?.lowercased()
    components.host = components.host?.lowercased()

    if components.path == "/" && components.query == nil && components.fragment == nil {
      components.path = ""
    }

    return components.string ?? trimmedCodeValue
  }
}

// MARK: - NFC Breaks settings

extension PhysicalUnblockItem {
  static let minimumBreakDurationInMinutes = 10
  static let maximumBreakDurationInMinutes = 120
  static let defaultBreakDurationInMinutes = 15

  static let minimumBreakCount = 1
  static let maximumBreakCount = 3
  static let defaultBreakCount = 1

  /// Minutes a single break from this tag lasts, clamped to what the UI offers.
  var resolvedBreakDurationInMinutes: Int {
    let minutes = breakDurationInMinutes ?? Self.defaultBreakDurationInMinutes
    return min(
      max(minutes, Self.minimumBreakDurationInMinutes),
      Self.maximumBreakDurationInMinutes
    )
  }

  /// How many breaks this tag is worth per session.
  var resolvedBreakCount: Int {
    let count = breakCount ?? Self.defaultBreakCount
    return min(max(count, Self.minimumBreakCount), Self.maximumBreakCount)
  }

  /// Every minute this tag can release over a session.
  var totalBreakAllowanceInMinutes: Int {
    resolvedBreakDurationInMinutes * resolvedBreakCount
  }
}
