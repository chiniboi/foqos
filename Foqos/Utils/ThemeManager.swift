import SwiftUI
import WidgetKit

class ThemeManager: ObservableObject {
  static let shared = ThemeManager()

  // Single source of truth for all theme colors
  /// Each colour carries a darker shade for light backgrounds and a brighter one
  /// for dark, so the palette keeps its contrast either way.
  static let availableColors: [(name: String, color: Color)] = [
    ("Loki Green", .adaptive(light: "#3a7a33", dark: "#8ad44b")),
    ("Deep Forest", .adaptive(light: "#2d3a2a", dark: "#7f9b73")),
    ("Fresh Lime", .adaptive(light: "#5fa32a", dark: "#a3ec06")),
    ("Electric Lime", .adaptive(light: "#71b505", dark: "#c6f950")),
    ("Sun Yellow", .adaptive(light: "#c79a00", dark: "#ffdd1e")),
  ]

  private static let defaultColorName = "Loki Green"

  @AppStorage(
    "foqosThemeColorName", store: UserDefaults(suiteName: "group.com.chini.foqos"))
  private var themeColorName: String = defaultColorName

  var selectedColorName: String {
    get { themeColorName }
    set {
      themeColorName = newValue
      objectWillChange.send()
      WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")
    }
  }

  var themeColor: Color {
    Self.availableColors.first(where: { $0.name == themeColorName })?.color
      ?? Self.availableColors.first!.color
  }

  func setTheme(named name: String) {
    selectedColorName = name
  }
}

extension Color {
  /// A colour that changes with the appearance, given two hex shades.
  static func adaptive(light: String, dark: String) -> Color {
    #if canImport(UIKit)
      return Color(
        uiColor: UIColor { traits in
          UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        }
      )
    #else
      return Color(hex: light)
    #endif
  }

  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }

  func toHex() -> String? {
    let uiColor = UIColor(self)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
      return nil
    }

    let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0

    return String(format: "#%06x", rgb)
  }
}
