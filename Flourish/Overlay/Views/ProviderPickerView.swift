import SwiftUI
import Defaults

// MARK: - Provider Picker View
// Inline menu for selecting the active LLM provider from the overlay toolbar.
// Binds directly to Defaults[.activeProvider] so the choice persists across
// sessions and is immediately picked up by OverlayWindowController.runLLM.

struct ProviderPickerView: View {
    @Default(.activeProvider) private var activeProvider

    var body: some View {
        Picker("", selection: $activeProvider) {
            ForEach(LLMProvider.allCases) { provider in
                Text(provider.displayName).tag(provider.rawValue)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .fixedSize()
    }
}
