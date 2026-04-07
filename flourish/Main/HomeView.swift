import SwiftUI
import Defaults

// MARK: - Home View
// Welcome screen + chronological history of prompt improvements.
// Mirrors Wispr Flow's Home layout: stats header → hero card → today/yesterday groups.

struct HomeView: View {
    @State private var entries: [HistoryEntry] = []
    @State private var showClearConfirm = false

    // Stats derived from history
    private var thisWeekCount: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.createdAt >= cutoff }.count
    }

    private var totalCount: Int { entries.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // ── Hero Card ─────────────────────────────────────────────────
                HeroCard()
                    .padding(.horizontal, FS.xxl)
                    .padding(.top, FS.xxl)
                    .padding(.bottom, FS.xl)

                // ── History Groups ────────────────────────────────────────────
                if entries.isEmpty {
                    EmptyHistoryView()
                        .padding(.top, FS.xxl)
                } else {
                    // Stats + Clear history row
                    HStack {
                        StatBadge(icon: "flame.fill", value: "\(thisWeekCount) this week", color: .orange)
                        StatBadge(icon: "pencil", value: "\(totalCount) total", color: .flourishAccent)
                        Spacer()
                        Button("Clear history") { showClearConfirm = true }
                            .font(.flourishMeta)
                            .foregroundColor(.flourishTextTertiary)
                            .buttonStyle(.plain)
                            .pointerCursor()
                            .confirmationDialog(
                                "Clear all history?",
                                isPresented: $showClearConfirm,
                                titleVisibility: .visible
                            ) {
                                Button("Clear All", role: .destructive) { clearAll() }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("This will permanently delete all \(totalCount) improvement\(totalCount == 1 ? "" : "s").")
                            }
                    }
                    .padding(.horizontal, FS.xxl)
                    .padding(.bottom, FS.xs)

                    HistoryGroups(entries: entries, onDelete: deleteEntry)
                }

                Spacer(minLength: FS.xxl)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.flourishSurface)
        .onAppear { loadEntries() }
    }

    private func loadEntries() {
        entries = (try? HistoryStore.shared.fetchAll()) ?? []
    }

    private func deleteEntry(_ entry: HistoryEntry) {
        guard let id = entry.id else { return }
        try? HistoryStore.shared.delete(id: id)
        withAnimation { entries.removeAll { $0.id == id } }
    }

    private func clearAll() {
        try? HistoryStore.shared.deleteAll()
        withAnimation { entries = [] }
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let icon:  String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            Text(value)
                .font(.flourishMeta)
                .foregroundColor(.flourishTextSecondary)
        }
        .padding(.trailing, FS.sm)
    }
}

// MARK: - Hero Card

private struct HeroCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Dark background
            RoundedRectangle(cornerRadius: FS.radiusLg)
                .fill(Color.flourishSurfaceHero)

            // Subtle accent — large faded f mark in corner
            flourishFShape(color: Color.white.opacity(0.04))
                .frame(width: 140, height: 215)
                .offset(x: -10, y: 30)
                .clipped()

            VStack(alignment: .leading, spacing: FS.sm) {
                Text("Improve anything you write")
                    .font(.flourishHeading)
                    .foregroundColor(.white)
                Text("Press your shortcut from any app — flourish improves your prompt instantly.")
                    .font(.flourishBody)
                    .foregroundColor(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Task { @MainActor in OverlayWindowController.shared.show() }
                } label: {
                    Text("Open Overlay →")
                        .font(.flourishButton)
                        .foregroundColor(Color.flourishSurfaceHero)
                        .padding(.horizontal, FS.lg)
                        .padding(.vertical, FS.xs + 2)
                        .background(Color.white)
                        .cornerRadius(FS.radiusSm)
                }
                .buttonStyle(.plain)
                .pointerCursor()
                .padding(.top, FS.xs)
            }
            .padding(FS.xl)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: FS.heroCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: FS.radiusLg))
    }
}

// MARK: - History Groups

private struct HistoryGroups: View {
    let entries: [HistoryEntry]
    let onDelete: (HistoryEntry) -> Void

    private var grouped: [(String, [HistoryEntry])] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        var todayItems:     [HistoryEntry] = []
        var yesterdayItems: [HistoryEntry] = []
        var olderItems:     [HistoryEntry] = []

        for e in entries {
            let day = cal.startOfDay(for: e.createdAt)
            if day == today { todayItems.append(e) }
            else if day == yesterday { yesterdayItems.append(e) }
            else { olderItems.append(e) }
        }

        var groups: [(String, [HistoryEntry])] = []
        if !todayItems.isEmpty     { groups.append(("TODAY", todayItems)) }
        if !yesterdayItems.isEmpty { groups.append(("YESTERDAY", yesterdayItems)) }
        if !olderItems.isEmpty     { groups.append(("EARLIER", olderItems)) }
        return groups
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(grouped, id: \.0) { groupName, groupEntries in
                // Section label
                Text(groupName)
                    .font(.flourishCaption)
                    .foregroundColor(.flourishTextTertiary)
                    .padding(.horizontal, FS.xxl)
                    .padding(.top, FS.lg)
                    .padding(.bottom, FS.xs)

                // Column headers
                HistoryColumnHeader()

                Rectangle()
                    .fill(Color.flourishBorder)
                    .frame(height: FS.borderWidth)

                // Rows
                ForEach(groupEntries, id: \.id) { entry in
                    HomeHistoryRow(entry: entry, onDelete: { onDelete(entry) })
                    Rectangle()
                        .fill(Color.flourishBorder)
                        .frame(height: FS.borderWidth)
                        .padding(.leading, FS.xxl)
                }
            }
        }
    }
}

// MARK: - Two-Column Layout (1/3 + 2/3)
// Custom Layout so proportions are computed from the proposed width directly —
// no GeometryReader or state required.

private struct TwoColumnLayout: Layout {
    // Width reserved for the divider between the two columns (can be 0).
    let dividerWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 3 else { return .zero }
        let width = proposal.width ?? 300
        let avail = width - dividerWidth
        let heights = [
            subviews[0].sizeThatFits(ProposedViewSize(width: avail / 3,       height: nil)).height,
            subviews[1].sizeThatFits(ProposedViewSize(width: dividerWidth,     height: nil)).height,
            subviews[2].sizeThatFits(ProposedViewSize(width: avail * 2 / 3,   height: nil)).height,
        ]
        return CGSize(width: width, height: heights.max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 3 else { return }
        let avail  = bounds.width - dividerWidth
        let origW  = avail / 3
        let imprW  = avail * 2 / 3
        let height = bounds.height

        subviews[0].place(at: CGPoint(x: bounds.minX,                      y: bounds.minY),
                          anchor: .topLeading,
                          proposal: ProposedViewSize(width: origW,          height: height))
        subviews[1].place(at: CGPoint(x: bounds.minX + origW,              y: bounds.minY),
                          anchor: .topLeading,
                          proposal: ProposedViewSize(width: dividerWidth,   height: height))
        subviews[2].place(at: CGPoint(x: bounds.minX + origW + dividerWidth, y: bounds.minY),
                          anchor: .topLeading,
                          proposal: ProposedViewSize(width: imprW,          height: height))
    }
}

// MARK: - Column Header

private struct HistoryColumnHeader: View {
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Mirror time column
            Color.clear.frame(width: 52 + FS.xxl)

            // 1/3 + 2/3 labels aligned with data rows (same dividerWidth)
            TwoColumnLayout(dividerWidth: FS.borderWidth) {
                Text("ORIGINAL")
                    .font(.flourishCaption)
                    .foregroundColor(.flourishTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear  // placeholder for the divider slot
                Text("IMPROVED")
                    .font(.flourishCaption)
                    .foregroundColor(.flourishTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)

            // Mirror trash button column
            Color.clear.frame(width: 32 + FS.md)
        }
        .padding(.vertical, FS.xs)
    }
}

// MARK: - History Row

private struct HomeHistoryRow: View {
    let entry: HistoryEntry
    let onDelete: () -> Void
    @State private var isHovered = false

    private var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: entry.createdAt)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(timeString)
                .font(.flourishMeta)
                .foregroundColor(.flourishTextTertiary)
                .frame(width: 52, alignment: .leading)
                .padding(.top, FS.md + 2)
                .padding(.leading, FS.xxl)

            TwoColumnLayout(dividerWidth: FS.borderWidth) {
                PromptCell(text: entry.originalPrompt)
                Rectangle()
                    .fill(Color.flourishBorder)
                    .padding(.vertical, FS.xs)
                PromptCell(text: entry.improvedPrompt)
            }
            .frame(maxWidth: .infinity)

            // Trash button — fades in on row hover
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.flourishTextTertiary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointerCursor()
            .opacity(isHovered ? 1 : 0)
            .padding(.trailing, FS.md)
            .help("Delete this entry")
        }
        .padding(.vertical, FS.xs)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Prompt Cell

private struct PromptCell: View {
    let text: String
    @State private var copied = false
    @State private var isHovered = false

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            withAnimation(.easeInOut(duration: 0.15)) { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.15)) { copied = false }
            }
        } label: {
            ZStack(alignment: .topLeading) {
                // Prompt text — hidden while copied
                Text(text)
                    .font(.flourishBody)
                    .foregroundColor(isHovered && !copied ? .flourishTextPrimary : .flourishTextSecondary)
                    .lineLimit(2)
                    .opacity(copied ? 0 : 1)

                // Copied indicator — visible while copied
                HStack(spacing: FS.xs) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Copied")
                        .font(.flourishBody)
                }
                .foregroundColor(.flourishAccent)
                .opacity(copied ? 1 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(FS.md)
            .animation(.easeInOut(duration: 0.15), value: copied)
        }
        .buttonStyle(.plain)
        .pointerCursor()
        .onHover { isHovered = $0 }
    }
}

// MARK: - Empty State

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: FS.sm) {
            flourishLogoSymbol(size: 36, color: .flourishTextTertiary.opacity(0.5))
            Text("No improvements yet")
                .font(.flourishBody)
                .foregroundColor(.flourishTextSecondary)
            Text("Press your shortcut from any app to get started.")
                .font(.flourishMeta)
                .foregroundColor(.flourishTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, FS.xxl)
    }
}
