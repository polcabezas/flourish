import SwiftUI
import Defaults

// MARK: - Overlay View
// Spotlight-style floating input panel with Wispr Flow aesthetic.
// Layout: text input (top) / divider / profile picker + Improve button (bottom toolbar)

struct OverlayView: View {
    @ObservedObject var viewModel: OverlayViewModel
    @Default(.lastSelectedProfileId) private var selectedProfileId
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Text Input Area
            ZStack(alignment: .topLeading) {
                if viewModel.promptText.isEmpty {
                    Text("Write your prompt…")
                        .font(.flourishInput)
                        .foregroundColor(.flourishTextSecondary)
                        .padding(.horizontal, FS.overlayInputPaddingH)
                        .padding(.top, FS.overlayInputPaddingV)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.promptText)
                    .font(.flourishInput)
                    .foregroundColor(.flourishTextPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.flourishSurface)
                    .frame(minHeight: FS.overlayInputMinHeight)
                    .padding(.horizontal, FS.overlayInputPaddingH - 5)
                    .padding(.vertical, FS.overlayInputPaddingV - 2)
                    .focused($inputFocused)
            }
            .frame(minHeight: FS.overlayInputMinHeight)
            .background(Color.flourishSurface)

            // MARK: Divider
            Rectangle()
                .fill(Color.flourishBorder)
                .frame(height: FS.borderWidth)

            // MARK: Toolbar
            HStack(spacing: FS.sm) {
                ProfilePickerView(selectedProfileId: $selectedProfileId)
                Spacer()
                ProviderPickerView()
                ImproveButton {
                    Task { @MainActor in OverlayWindowController.shared.dismiss(paste: true) }
                }
            }
            .padding(.horizontal, FS.overlayToolbarPaddingH)
            .padding(.vertical, FS.overlayToolbarPaddingV)
            .background(Color.flourishSurfaceRaised)
        }
        .frame(width: FS.overlayWidth)
        .fixedSize(horizontal: true, vertical: false)
        .background(Color.flourishSurface)
        .clipShape(RoundedRectangle(cornerRadius: FS.radiusLg))
        .onAppear { inputFocused = true }
    }
}

// MARK: - Improve Button

private struct ImproveButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text("Improve →")
                .font(.flourishButton)
                .foregroundColor(.flourishButtonLabel)
                .padding(.horizontal, FS.lg)
                .padding(.vertical, FS.xs + 2)
                .background(isHovered ? Color(hex: "#2E2E20") : Color.flourishButtonBg)
                .cornerRadius(FS.radiusSm)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .pointerCursor()
    }
}
