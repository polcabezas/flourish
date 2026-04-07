import SwiftUI

// MARK: - History List View (left panel)

struct HistoryListView: View {
    @Binding var selectedEntry: HistoryEntry?
    @State private var searchText = ""
    @State private var entries: [HistoryEntry] = []

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.flourishTextSecondary)
                TextField("Search history…", text: $searchText)
                    .font(.flourishBody)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _ in loadEntries() }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        loadEntries()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.flourishTextSecondary)
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                }
            }
            .padding(.horizontal, FS.md)
            .padding(.vertical, FS.sm)
            .background(Color.flourishSurfaceRaised)

            Rectangle()
                .fill(Color.flourishBorder)
                .frame(height: FS.borderWidth)

            if entries.isEmpty {
                VStack(spacing: FS.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(.flourishTextSecondary)
                    Text(searchText.isEmpty ? "No history yet" : "No results")
                        .font(.flourishBody)
                        .foregroundColor(.flourishTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.flourishSurface)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(entries, id: \.id) { entry in
                            HistoryListRow(
                                entry: entry,
                                isSelected: selectedEntry?.id == entry.id
                            )
                            .onTapGesture { selectedEntry = entry }
                            .pointerCursor()

                            Rectangle()
                                .fill(Color.flourishBorder)
                                .frame(height: FS.borderWidth)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .background(Color.flourishSurface)
            }
        }
        .background(Color.flourishSurface)
        .onAppear { loadEntries() }
        .onReceive(NotificationCenter.default.publisher(for: .historyDidChange)) { _ in
            loadEntries()
        }
    }

    private func loadEntries() {
        entries = (try? HistoryStore.shared.fetchAll(search: searchText)) ?? []
    }
}

// MARK: - History List Row

private struct HistoryListRow: View {
    let entry: HistoryEntry
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FS.xs) {
            Text(entry.truncatedOriginal)
                .font(.flourishBody)
                .foregroundColor(.flourishTextPrimary)
                .lineLimit(2)
            Text(entry.formattedDate)
                .font(.flourishMeta)
                .foregroundColor(.flourishTextSecondary)
        }
        .padding(.horizontal, FS.md)
        .padding(.vertical, FS.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.flourishSurfaceRaised : Color.flourishSurface)
    }
}
