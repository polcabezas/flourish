import SwiftUI

// MARK: - History View (HSplitView container)

struct HistoryView: View {
    @State private var selectedEntry: HistoryEntry? = nil

    var body: some View {
        HSplitView {
            HistoryListView(selectedEntry: $selectedEntry)
                .frame(minWidth: FS.historySidebarMinWidth, maxWidth: FS.historySidebarMaxWidth)

            HistoryDetailView(entry: selectedEntry)
                .frame(minWidth: FS.historyDetailMinWidth)
        }
        .frame(
            minWidth: FS.historyWindowMinWidth,
            minHeight: FS.historyWindowMinHeight
        )
        .background(Color.flourishSurface)
    }
}
