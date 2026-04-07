import SwiftUI
import KeyboardShortcuts

// MARK: - Shortcut Tab

struct ShortcutTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FS.xxl) {
            VStack(alignment: .leading, spacing: FS.md) {
                SectionLabel("Global Keyboard Shortcut")

                KeyboardShortcuts.Recorder("Open flourish", name: .openOverlay)
                    .font(.flourishBody)

                Text("Click the field above and press your desired key combination.\nDefault: ⌃ Space (Control + Space)")
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("If ⌃ Space conflicts with your Input Source switching shortcut, remap it here or disable the system shortcut in System Settings → Keyboard → Shortcuts → Input Sources.")
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(FS.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
