import FamilyControls
import SwiftData
import SwiftUI

private enum ProfileCreationDestination: Identifiable {
  case guided
  case advanced

  var id: String {
    switch self {
    case .guided:
      return "guided"
    case .advanced:
      return "advanced"
    }
  }
}

struct BlockedProfileListView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss

  @Query(sort: [
    SortDescriptor(\BlockedProfiles.order, order: .forward),
    SortDescriptor(\BlockedProfiles.createdAt, order: .reverse),
  ]) private var profiles: [BlockedProfiles]

  @Query(
    filter: #Predicate<BlockedProfileSession> { $0.endTime == nil },
    sort: \BlockedProfileSession.startTime,
    order: .reverse
  ) private var activeSessions: [BlockedProfileSession]

  @State private var profileCreationDestination: ProfileCreationDestination?

  @State private var profileToEdit: BlockedProfiles?
  @State private var showErrorAlert = false

  var body: some View {
    NavigationStack {
      Group {
        if profiles.isEmpty {
          ScrollView {
            VStack {
              Spacer(minLength: 70)

              Welcome(
                onGuidedTap: {
                  if canCreateProfiles {
                    profileCreationDestination = .guided
                  }
                },
                onAdvancedTap: {
                  if canCreateProfiles {
                    profileCreationDestination = .advanced
                  }
                }
              )

              Spacer(minLength: 70)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
          }
        } else {
          List {
            ForEach(profiles) { profile in
              ProfileRow(profile: profile, isActive: profile.id == activeSessionProfileId)
                .contentShape(Rectangle())
                .onTapGesture {
                  profileToEdit = profile
                }
            }
            .onDelete(perform: deleteProfiles)
          }
        }
      }
      .navigationTitle("Profiles")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
          if canCreateProfiles {
            Menu {
              Button {
                profileCreationDestination = .guided
              } label: {
                Label("Guided Setup", systemImage: "list.bullet.clipboard")
              }

              Button {
                profileCreationDestination = .advanced
              } label: {
                Label("Full Profile Editor", systemImage: "slider.horizontal.3")
              }
            } label: {
              Image(systemName: "plus")
            }
          }
        }
      }
      .sheet(item: $profileCreationDestination) { destination in
        switch destination {
        case .guided:
          GuidedBlockedProfileCreationView()
        case .advanced:
          BlockedProfileView()
        }
      }
      .sheet(item: $profileToEdit) { profile in
        BlockedProfileView(profile: profile)
      }
      .alert(
        "Cannot Delete Active Profile",
        isPresented: $showErrorAlert
      ) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(
          "You cannot delete a profile that is currently active. Please switch to a different profile first."
        )
      }
    }
  }

  private var activeSessionProfileId: UUID? {
    activeSessions.first?.blockedProfile.id
  }

  private var canCreateProfiles: Bool {
    return activeSessionProfileId == nil
  }

  private func deleteProfiles(at offsets: IndexSet) {
    let activeSession = BlockedProfileSession.mostRecentActiveSession(
      in: context)

    // Check if any of the profiles to delete are active
    for index in offsets {
      let profile = profiles[index]
      if profile.id == activeSession?.blockedProfile.id {
        showErrorAlert = true
        return
      }
    }

    // Delete the profiles and reorder
    do {
      for index in offsets {
        let profile = profiles[index]
        try BlockedProfiles.deleteProfile(profile, in: context)
      }

      // Reorder remaining profiles to fix gaps in ordering
      let remainingProfiles = try BlockedProfiles.fetchProfiles(in: context)
      try BlockedProfiles.reorderProfiles(remainingProfiles, in: context)
    } catch {
      print("Failed to delete or reorder profiles: \(error)")
    }
  }

}

#Preview {
  BlockedProfileListView()
    .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
