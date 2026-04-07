import SwiftUI
import Defaults

// MARK: - Profile Picker View
// Native macOS popup button (NSPopUpButton) for guideline profile selection.

struct ProfilePickerView: View {
    @Binding var selectedProfileId: String
    @Default(.profiles) private var profiles

    var body: some View {
        Picker("", selection: $selectedProfileId) {
            ForEach(profiles) { profile in
                Text(profile.name).tag(profile.id.uuidString)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .fixedSize()
    }
}
