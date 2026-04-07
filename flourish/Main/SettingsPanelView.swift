import SwiftUI
import AppKit
import Defaults
import LaunchAtLogin
import KeyboardShortcuts

// MARK: - Settings Panel View
// Inline settings — replaces the old TabView window.
// Sections: Shortcut · General

struct SettingsPanelView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Settings")
                    .font(.flourishTitle)
                    .foregroundColor(.flourishTextPrimary)
                    .padding(.horizontal, FS.xxl)
                    .padding(.top, FS.xxl)
                    .padding(.bottom, FS.lg)

                Rectangle()
                    .fill(Color.flourishBorder)
                    .frame(height: FS.borderWidth)

                // Sections
                ShortcutSection()

                SectionDivider()

                GeneralSection()

                Spacer(minLength: FS.xxl)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.flourishSurface)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Section Divider

private struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.flourishBorder)
            .frame(height: FS.borderWidth)
            .padding(.horizontal, FS.xxl)
            .padding(.vertical, FS.lg)
    }
}

// MARK: - Shortcut Section

private struct ShortcutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FS.md) {
            PanelSectionLabel("Shortcut")

            KeyboardShortcuts.Recorder("Open flourish", name: .openOverlay)
                .font(.flourishBody)

            Text("Click the field and press your desired key combination. Default: ⌃ Space")
                .font(.flourishMeta)
                .foregroundColor(.flourishTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("If ⌃ Space conflicts with Input Source switching, remap it here or disable the system shortcut in System Settings → Keyboard → Shortcuts → Input Sources.")
                .font(.flourishMeta)
                .foregroundColor(.flourishTextTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, FS.xxl)
        .padding(.top, FS.lg)
    }
}

// MARK: - General Section

private struct GeneralSection: View {
    @Default(.launchAtLogin) private var launchAtLogin
    @Default(.showDockIcon)  private var showDockIcon

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FS.md) {
            PanelSectionLabel("General")

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

            Divider()
                .padding(.vertical, FS.xs)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    flourishLogoSymbol(size: 20, color: .flourishAccent)
                    Text("flourish")
                        .font(.flourishBody)
                        .fontWeight(.medium)
                }
                Text("Version \(appVersion) (\(buildNumber)) · macOS 13+")
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextTertiary)
            }
        }
        .padding(.horizontal, FS.xxl)
        .padding(.top, 0)
    }
}

// MARK: - Panel Section Label

private struct PanelSectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.flourishMeta)
            .foregroundColor(.flourishTextTertiary)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}
