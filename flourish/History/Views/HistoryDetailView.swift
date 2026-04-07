import SwiftUI
import AppKit

// MARK: - History Detail View (right panel)

struct HistoryDetailView: View {
    let entry: HistoryEntry?

    var body: some View {
        if let entry = entry {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Original prompt section
                    PromptSection(
                        label: "Original Prompt",
                        text: entry.originalPrompt
                    )

                    Rectangle()
                        .fill(Color.flourishBorder)
                        .frame(height: FS.borderWidth)

                    // Improved prompt section
                    PromptSection(
                        label: "Improved Prompt",
                        text: entry.improvedPrompt
                    )

                    Rectangle()
                        .fill(Color.flourishBorder)
                        .frame(height: FS.borderWidth)

                    // Footer metadata
                    HStack(spacing: FS.lg) {
                        MetaChip(icon: "cpu", text: entry.provider.capitalized)
                        MetaChip(icon: "square.stack.3d.up", text: entry.modelId)
                        MetaChip(icon: "arrow.up", text: "\(entry.tokensIn) in")
                        MetaChip(icon: "arrow.down", text: "\(entry.tokensOut) out")
                        MetaChip(icon: "dollarsign.circle", text: entry.formattedCost)
                        Spacer()
                        Text(entry.formattedDate)
                            .font(.flourishMeta)
                            .foregroundColor(.flourishTextSecondary)
                    }
                    .padding(.horizontal, FS.xxl)
                    .padding(.vertical, FS.md)
                    .background(Color.flourishSurfaceRaised)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.flourishSurface)
        } else {
            // Empty state
            VStack(spacing: FS.sm) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundColor(.flourishTextSecondary)
                Text("Select a request to view details")
                    .font(.flourishBody)
                    .foregroundColor(.flourishTextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.flourishSurface)
        }
    }
}

// MARK: - Prompt Section

private struct PromptSection: View {
    let label: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(label)
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                CopyButton(text: text)
            }
            .padding(.horizontal, FS.xxl)
            .padding(.vertical, FS.md)
            .background(Color.flourishSurfaceRaised)

            Rectangle()
                .fill(Color.flourishBorder)
                .frame(height: FS.borderWidth)

            Text(text)
                .font(.flourishBody)
                .foregroundColor(.flourishTextPrimary)
                .textSelection(.enabled)
                .padding(FS.xxl)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(Color.flourishSurface)
        }
    }
}

// MARK: - Copy Button

private struct CopyButton: View {
    let text: String
    @State private var copied = false

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            withAnimation { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { copied = false }
            }
        } label: {
            HStack(spacing: FS.xs) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                Text(copied ? "Copied" : "Copy")
                    .font(.flourishMeta)
            }
            .foregroundColor(copied ? .flourishAccent : .flourishTextSecondary)
        }
        .buttonStyle(.plain)
        .pointerCursor()
    }
}

// MARK: - Meta Chip

private struct MetaChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.flourishMeta)
                .lineLimit(1)
        }
        .foregroundColor(.flourishTextSecondary)
    }
}
