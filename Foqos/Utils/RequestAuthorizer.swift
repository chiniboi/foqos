import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

class RequestAuthorizer: ObservableObject {
  @Published var isAuthorized = false

  func refreshAuthorizationStatus() {
    if DummyMode.isEnabled {
      Task { @MainActor in self.isAuthorized = true }
      return
    }

    let isApproved = getAuthorizationStatus() == .approved

    Task { @MainActor in
      self.isAuthorized = isApproved
    }
  }

  func requestAuthorization() {
    if DummyMode.isEnabled {
      // Nothing to ask for: a demo build cannot hold the Screen Time entitlement.
      Task { @MainActor in self.isAuthorized = true }
      return
    }

    Task {
      do {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        print("Individual authorization successful")

        // Dispatch the update to the main thread
        await MainActor.run {
          self.isAuthorized = true
        }
      } catch {
        print("Error requesting authorization: \(error)")
        await MainActor.run {
          self.isAuthorized = false
        }
      }
    }
  }

  func getAuthorizationStatus() -> AuthorizationStatus {
    if DummyMode.isEnabled {
      return .approved
    }

    return AuthorizationCenter.shared.authorizationStatus
  }
}
