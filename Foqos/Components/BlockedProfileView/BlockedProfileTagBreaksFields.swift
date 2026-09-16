import SwiftUI

/// Break settings for the NFC Breaks strategy. Every registered NFC tag carries
/// its own break length and how many of those breaks it is worth per session,
/// so a tag by the sofa can be short while a tag in the car is long.
struct BlockedProfileTagBreaksFields: View {
  @EnvironmentObject private var themeManager: ThemeManager

  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  private let durationRange =
    Double(PhysicalUnblockItem.minimumBreakDurationInMinutes)
    ... Double(PhysicalUnblockItem.maximumBreakDurationInMinutes)

  private let countRange =
    PhysicalUnblockItem.minimumBreakCount ... PhysicalUnblockItem.maximumBreakCount

  private var tagIndices: [Int] {
    draft.physicalUnblockItems.indices.filter {
      draft.physicalUnblockItems[$0].type == .nfc
    }
  }

  var body: some View {
    if tagIndices.isEmpty {
      VStack(alignment: .leading, spacing: 6) {
        Text("No NFC tags yet")
          .font(.subheadline)
          .fontWeight(.semibold)

        Text(
          "Go back to Physical Unlocks and add the tags you want to use, then give each one its own break here."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 4)
    } else {
      VStack(alignment: .leading, spacing: 18) {
        ForEach(Array(tagIndices.enumerated()), id: \.element) { position, index in
          tagRow(at: index)

          if position < tagIndices.count - 1 {
            Divider()
          }
        }
      }
    }
  }

  @ViewBuilder
  private func tagRow(at index: Int) -> some View {
    if index < draft.physicalUnblockItems.count {
      let item = draft.physicalUnblockItems[index]

      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text(item.name)
            .fontWeight(.semibold)

          Spacer()

          Text(DateFormatters.formatMinutes(item.resolvedBreakDurationInMinutes))
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
        }

        Slider(
          value: durationBinding(at: index),
          in: durationRange,
          step: 5
        )
        .tint(themeManager.themeColor)
        .accessibilityLabel("\(item.name) break duration")
        .accessibilityValue(DateFormatters.formatMinutes(item.resolvedBreakDurationInMinutes))

        HStack {
          Text("10m")
          Spacer()
          Text("2h")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)

        Stepper(value: countBinding(at: index), in: countRange) {
          HStack {
            Text("Breaks per session")

            Spacer()

            Text("\(item.resolvedBreakCount)")
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)
              .contentTransition(.numericText())
          }
        }
      }
      .disabled(disabled)
    }
  }

  private func durationBinding(at index: Int) -> Binding<Double> {
    Binding(
      get: {
        guard index < draft.physicalUnblockItems.count else {
          return Double(PhysicalUnblockItem.defaultBreakDurationInMinutes)
        }

        return Double(draft.physicalUnblockItems[index].resolvedBreakDurationInMinutes)
      },
      set: { newValue in
        guard index < draft.physicalUnblockItems.count else { return }

        draft.physicalUnblockItems[index].breakDurationInMinutes = Int(newValue)
      }
    )
  }

  private func countBinding(at index: Int) -> Binding<Int> {
    Binding(
      get: {
        guard index < draft.physicalUnblockItems.count else {
          return PhysicalUnblockItem.defaultBreakCount
        }

        return draft.physicalUnblockItems[index].resolvedBreakCount
      },
      set: { newValue in
        guard index < draft.physicalUnblockItems.count else { return }

        draft.physicalUnblockItems[index].breakCount = newValue
      }
    )
  }
}
