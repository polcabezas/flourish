import SwiftUI

// MARK: - Navigation Sections

enum MainSection: String, CaseIterable, Hashable {
    case home     = "home"
    case profiles = "profiles"
    case settings = "settings"

    var label: String {
        switch self {
        case .home:     return "Home"
        case .profiles: return "Profiles"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home:     return "house"
        case .profiles: return "rectangle.stack"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Main Window State (observable, shared across window lifecycle)

final class MainWindowState: ObservableObject {
    static let shared = MainWindowState()
    @Published var selectedSection: MainSection = .home
    private init() {}
}

// MARK: - Main Window View

struct MainWindowView: View {
    @ObservedObject private var state = MainWindowState.shared

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selected: $state.selectedSection)
                .navigationSplitViewColumnWidth(FS.sidebarWidth)
        } detail: {
            detailView(for: state.selectedSection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.flourishSurface)
        }
    }

    @ViewBuilder
    private func detailView(for section: MainSection) -> some View {
        switch section {
        case .home:     HomeView()
        case .profiles: ProfilesView()
        case .settings: SettingsPanelView()
        }
    }
}

// MARK: - Sidebar

private struct SidebarView: View {
    @Binding var selected: MainSection

    private let primarySections: [MainSection] = [.home, .profiles]

    var body: some View {
        VStack(spacing: 0) {
            // Logo
            HStack(spacing: 10) {
                FlourishLogoView(size: 26, color: .flourishAccent)
                Spacer()
            }
            .padding(.horizontal, FS.sidebarItemPaddingH + 4)
            .padding(.top, 20)
            .padding(.bottom, 14)

            // Primary nav
            VStack(spacing: 2) {
                ForEach(primarySections, id: \.self) { section in
                    SidebarItem(section: section, selected: $selected)
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            // Bottom utility nav
            Rectangle()
                .fill(Color.flourishBorder)
                .frame(height: FS.borderWidth)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

            VStack(spacing: 2) {
                SidebarItem(section: .settings, selected: $selected)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.flourishSidebarSurface)
    }
}

// MARK: - Sidebar Item

private struct SidebarItem: View {
    let section: MainSection
    @Binding var selected: MainSection
    @State private var isHovered = false

    private var isActive: Bool { selected == section }

    var body: some View {
        Button {
            selected = section
        } label: {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.system(size: 13, weight: isActive ? .medium : .regular))
                    .foregroundColor(isActive ? .flourishAccent : .flourishTextSecondary)
                    .frame(width: 18)
                Text(section.label)
                    .font(isActive ? .flourishButton : .flourishBody)
                    .foregroundColor(isActive ? .flourishTextPrimary : .flourishTextSecondary)
                Spacer()
            }
            .padding(.horizontal, FS.sidebarItemPaddingH)
            .padding(.vertical, FS.sidebarItemPaddingV)
            .background(
                RoundedRectangle(cornerRadius: FS.radiusMd)
                    .fill(isActive
                          ? Color.flourishSurfaceRaised
                          : (isHovered ? Color.flourishSurfaceRaised.opacity(0.6) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .pointerCursor()
    }
}

// MARK: - Preview

#Preview {
    MainWindowView()
        .frame(width: FS.mainWindowWidth, height: FS.mainWindowHeight)
}
