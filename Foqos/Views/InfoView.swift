import SwiftUI

private let foqosRepoURL = URL(string: "https://github.com/awaseem/foqos")!
private let foqosSiteURL = URL(string: "https://foqos.app")!
private let donateURL = URL(string: "https://www.buymeacoffee.com/ambitionsoftware")!

/// Credits and licensing for the app this one is built on. Foqos is MIT
/// licensed, which asks that its copyright and permission notice travel with
/// any copy, so the notice lives here where anyone can read it.
struct InfoView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          builtOnSection

          creatorSection

          licenseSection
        }
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
      }
      .navigationTitle("Info")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close", systemImage: "xmark") { dismiss() }
        }
      }
    }
  }

  private var builtOnSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Built on Foqos")
        .font(.title2.weight(.bold))

      Text(
        "This app is a personal build of Foqos, an open source focus app by Ali Waseem. "
          + "The blocking, scanning and session code is his work, reused under the MIT license "
          + "and changed to fit one particular routine."
      )
      .font(.body)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)

      Text(
        "It is not affiliated with, endorsed by, or supported by Foqos or its creator. "
          + "Please do not send bug reports about this build to them."
      )
      .font(.footnote)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var creatorSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Credit where it is due")
        .font(.headline)

      Text(
        "Foqos was created by Ali Waseem and is free and open source. If this app is useful "
          + "to you, the person to thank is him."
      )
      .font(.body)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)

      Link(destination: donateURL) {
        Text("Donate to the creator")
          .font(.headline)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(themeManager.themeColor, in: RoundedRectangle(cornerRadius: 14))
      }

      VStack(alignment: .leading, spacing: 8) {
        Link("Foqos on GitHub", destination: foqosRepoURL)
        Link("foqos.app", destination: foqosSiteURL)
      }
      .font(.subheadline)
      .tint(themeManager.themeColor)
    }
  }

  private var licenseSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("License")
        .font(.headline)

      Text("Foqos — MIT License\nCopyright (c) 2024 Ali Waseem")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)

      Text(
        "Permission is hereby granted, free of charge, to any person obtaining a copy of this "
          + "software and associated documentation files (the \"Software\"), to deal in the "
          + "Software without restriction, including without limitation the rights to use, copy, "
          + "modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, "
          + "and to permit persons to whom the Software is furnished to do so, subject to the "
          + "following conditions:\n\nThe above copyright notice and this permission notice "
          + "shall be included in all copies or substantial portions of the Software.\n\nTHE "
          + "SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, "
          + "INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A "
          + "PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT "
          + "HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION "
          + "OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE "
          + "SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
      )
      .font(.caption2)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)

      Text("Also includes CodeScanner by Paul Hudson, MIT licensed.")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }
  }
}

#Preview {
  InfoView()
    .environmentObject(ThemeManager.shared)
}
