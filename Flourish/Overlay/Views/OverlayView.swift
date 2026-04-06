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
                        .padding(.top, FS.overlayInputPaddingV + FS.xl)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.promptText)
                    .font(.flourishInput)
                    .foregroundColor(.flourishTextPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.flourishSurface)
                    .frame(minHeight: FS.overlayInputMinHeight, maxHeight: 200)
                    .padding(.horizontal, FS.overlayInputPaddingH - 5)
                    .padding(.top, FS.overlayInputPaddingV + FS.xl)
                    .padding(.bottom, FS.overlayInputPaddingV - 2)
                    .focused($inputFocused)
            }
            .frame(minHeight: FS.overlayInputMinHeight)
            .background(Color.flourishSurface)

            // MARK: Divider
            Rectangle()
                .fill(Color.flourishBorder)
                .frame(height: FS.borderWidth)

            // MARK: Toolbar
            VStack(spacing: 0) {
                HStack(spacing: FS.sm) {
                    ProfilePickerView(selectedProfileId: $selectedProfileId)
                    Spacer()
                    ImproveButton {
                        Task { @MainActor in OverlayWindowController.shared.dismiss(paste: true) }
                    }
                }
                .padding(.horizontal, FS.overlayToolbarPaddingH)
                .padding(.top, FS.overlayToolbarPaddingV)
                .padding(.bottom, FS.sm)

                HintsRow(draftRestored: viewModel.draftRestored, draftSavedAt: viewModel.draftSavedAt)
                    .padding(.horizontal, FS.overlayToolbarPaddingH)
                    .padding(.bottom, FS.md)
            }
            .background(Color.flourishSurfaceRaised)
        }
        .frame(width: FS.overlayWidth)
        .fixedSize(horizontal: true, vertical: false)
        .background(Color.flourishSurface)
        .clipShape(RoundedRectangle(cornerRadius: FS.radiusLg))
        .onAppear { inputFocused = true }
        .onChange(of: viewModel.focusTrigger) { _ in inputFocused = true }
    }
}

// MARK: - Hints Row

private struct HintsRow: View {
    let draftRestored: Bool
    let draftSavedAt: Date?

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            if draftRestored {
                HStack(spacing: 4) {
                    Text("Draft restored")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextTertiary)
                    if let date = draftSavedAt {
                        Text("· saved at \(Self.timeFormatter.string(from: date))")
                            .font(.flourishMeta)
                            .foregroundColor(.flourishTextTertiary.opacity(0.6))
                    }
                }
            }
            Spacer()
            HStack(spacing: FS.sm) {
                HintItem(key: "↑↓", label: "history")
                hintDot
                HintItem(key: "↩", label: "improve")
                hintDot
                HintItem(key: "esc", label: "close")
            }
        }
    }

    private var hintDot: some View {
        Text("·")
            .font(.flourishMeta)
            .foregroundColor(.flourishTextTertiary.opacity(0.4))
    }
}

private struct HintItem: View {
    let key: String
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.flourishMeta)
                .foregroundColor(.flourishTextTertiary)
            Text(label)
                .font(.flourishMeta)
                .foregroundColor(.flourishTextTertiary.opacity(0.6))
        }
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
