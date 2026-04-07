import SwiftUI
import Defaults

// MARK: - Overlay View
// Spotlight-style floating input panel with Wispr Flow aesthetic.
// Layout: text input (top) / divider / profile picker + Improve button (bottom toolbar)

struct OverlayView: View {
    @ObservedObject var viewModel: OverlayViewModel
    @Default(.lastSelectedProfileId) private var selectedProfileId
    @Default(.targetPlatform) private var targetPlatform
    @FocusState private var inputFocused: Bool
    @State private var placeholderIndex = 0

    private static let placeholders = [
        "Write your prompt…",
        "What are you trying to say?",
        "Rough thoughts welcome here…",
        "Type it messy, we'll clean it up.",
        "Describe what you need…",
        "Start typing and let's improve it.",
        "What do you want to communicate?",
        "Paste or type something to improve…",
        "No judgment, just type.",
        "Your words, polished.",
        "Brain dump away…",
        "Even a half-baked idea works.",
        "Just get it out. We'll handle the rest.",
        "Write like nobody's watching.",
        "Ramble if you must.",
        "Good enough to start is good enough.",
        "What's on your mind?",
        "Say it however feels natural.",
        "First drafts belong here.",
        "Clarity is overrated — for now.",
        "Start anywhere. We'll fix the order.",
        "The messier, the better.",
        "Thinking out loud? Perfect.",
        "Something to say? Let's say it better.",
        "Drop your thoughts, pick up a polished prompt.",
    ]

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Text Input Area
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.promptText)
                    .font(.flourishInput)
                    .foregroundColor(.flourishTextPrimary)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .background(Color.flourishSurface)
                    .frame(minHeight: FS.overlayInputMinHeight, maxHeight: 320)
                    .padding(.horizontal, FS.overlayInputPaddingH - 5)
                    .padding(.top, FS.overlayInputPaddingV)
                    .focused($inputFocused)

                if viewModel.promptText.isEmpty {
                    Text(Self.placeholders[placeholderIndex])
                        .font(.flourishInput)
                        .foregroundColor(.flourishTextSecondary.opacity(0.5))
                        .padding(.horizontal, FS.overlayInputPaddingH)
                        .padding(.top, FS.overlayInputPaddingV)
                        .allowsHitTesting(false)
                }
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
                    TargetPlatformPickerView(selectedPlatform: $targetPlatform)
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
        .onAppear {
            inputFocused = true
            placeholderIndex = Int.random(in: 0..<Self.placeholders.count)
        }
        .onChange(of: viewModel.focusTrigger) { _ in
            inputFocused = true
            placeholderIndex = Int.random(in: 0..<Self.placeholders.count)
        }
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
