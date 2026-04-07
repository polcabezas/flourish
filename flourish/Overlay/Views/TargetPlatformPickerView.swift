import SwiftUI
import Defaults

// MARK: - Target Platform Picker View
// Native macOS popup button for target platform selection.

struct TargetPlatformPickerView: View {
    @Binding var selectedPlatform: TargetPlatform

    var body: some View {
        Picker("", selection: $selectedPlatform) {
            ForEach(TargetPlatform.allCases) { platform in
                Text(platform.displayName).tag(platform)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .fixedSize()
    }
}
