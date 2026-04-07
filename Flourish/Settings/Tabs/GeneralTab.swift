import SwiftUI
import AppKit
import Defaults
import LaunchAtLogin

// MARK: - General Tab

struct GeneralTab: View {
    @Default(.launchAtLogin) private var launchAtLogin
    @Default(.showDockIcon)  private var showDockIcon

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FS.xxl) {
            // Launch at login
            VStack(alignment: .leading, spacing: FS.sm) {
                SectionLabel("System")
                LaunchAtLogin.Toggle {
                    Text("Launch flourish at login")
                        .font(.flourishBody)
                }
                .onChange(of: launchAtLogin) { newValue in
                    Defaults[.launchAtLogin] = newValue
                }
                .pointerCursor()

                Text("flourish runs quietly in the menu bar and is always ready when you need it.")
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Toggle(isOn: $showDockIcon) {
                    Text("Show dock icon")
                        .font(.flourishBody)
                }
                .onChange(of: showDockIcon) { newValue in
                    NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                }
                .pointerCursor()
            }

            Divider()

            // About
            VStack(alignment: .leading, spacing: FS.sm) {
                SectionLabel("About")
                HStack(spacing: FS.xl) {
                    VStack(alignment: .leading, spacing: FS.xs) {
                        Text("flourish")
                            .font(.flourishBody)
                            .fontWeight(.medium)
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.flourishMeta)
                            .foregroundColor(.flourishTextSecondary)
                        Text("Personal use — macOS 13+")
                            .font(.flourishMeta)
                            .foregroundColor(.flourishTextSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(FS.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
