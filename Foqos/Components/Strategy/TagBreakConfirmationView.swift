import SwiftUI

/// Confirmation shown before a code spends one of its breaks, and before a
/// running break is ended early. Matches the sheets used elsewhere in the app
/// rather than a system alert.
struct TagBreakConfirmationView: View {
  @EnvironmentObject var themeManager: ThemeManager

  let item: PhysicalUnblockItem
  let isEnding: Bool
  /// Breaks this code has left once this one is spent.
  let breaksRemainingAfter: Int
  let onCancel: () -> Void
  let onConfirm: () -> Void

  private var durationText: String {
    DateFormatters.formatMinutes(item.resolvedBreakDurationInMinutes)
  }

  private var title: String {
    isEnding ? "End \(item.name) break?" : "\(item.name) break"
  }

  private var message: String {
    if isEnding {
      return "Your apps get blocked again right away. This break is already spent, so \(item.name) "
        + remainderText + "."
    }

    return "This unblocks your apps for \(durationText). You can lock back early from the "
      + "session screen. Afterwards \(item.name) " + remainderText + "."
  }

  private var remainderText: String {
    switch breaksRemainingAfter {
    case 0: return "has no breaks left this session"
    case 1: return "has 1 break left"
    default: return "has \(breaksRemainingAfter) breaks left"
    }
  }

  private var buttonTitle: String {
    isEnding ? "Lock back now" : "Start \(durationText) break"
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 22) {
        Spacer(minLength: 10)

        Image("CoffeeStickerIcon")
          .resizable()
          .scaledToFit()
          .frame(width: 104, height: 104)

        VStack(spacing: 10) {
          Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)

          Text(message)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 28)

        Spacer(minLength: 12)

        ActionButton(
          title: buttonTitle,
          backgroundColor: themeManager.themeColor,
          action: onConfirm
        )
      }
      .padding()
      .navigationTitle(isEnding ? "End Break" : "Take a Break")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: onCancel) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
        }
      }
    }
  }
}

#Preview {
  TagBreakConfirmationView(
    item: PhysicalUnblockItem(
      name: "Bathroom",
      type: .qrCode,
      codeValue: "bathroom",
      breakDurationInMinutes: 15,
      breakCount: 2
    ),
    isEnding: false,
    breaksRemainingAfter: 1,
    onCancel: {},
    onConfirm: {}
  )
  .environmentObject(ThemeManager.shared)
}
