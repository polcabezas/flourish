import SwiftUI
import Defaults

// MARK: - Profiles Tab

struct ProfilesTab: View {
    @Default(.profiles) private var profiles
    @State private var editingProfile: GuidelineProfile? = nil
    @State private var showAddSheet = false
    @State private var deleteConfirmTarget: GuidelineProfile? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toolbar
            HStack {
                SectionLabel("Guideline Profiles")
                Spacer()
                Button {
                    editingProfile = nil
                    showAddSheet = true
                } label: {
                    Label("Add Profile", systemImage: "plus")
                        .font(.flourishBody)
                }
                .buttonStyle(.bordered)
                .pointerCursor()
            }
            .padding(.horizontal, FS.xxl)
            .padding(.top, FS.xxl)
            .padding(.bottom, FS.md)

            Divider()

            // Profile list
            List {
                ForEach(profiles) { profile in
                    ProfileRow(
                        profile: profile,
                        onEdit: {
                            editingProfile = profile
                            showAddSheet = true
                        },
                        onDelete: {
                            deleteConfirmTarget = profile
                        }
                    )
                }
            }
            .listStyle(.inset)
        }
        .sheet(isPresented: $showAddSheet) {
            ProfileEditSheet(existingProfile: editingProfile) { saved in
                if let existing = editingProfile,
                   let idx = profiles.firstIndex(where: { $0.id == existing.id }) {
                    profiles[idx] = saved
                } else {
                    profiles.append(saved)
                }
            }
        }
        .alert("Delete Profile?", isPresented: Binding(
            get: { deleteConfirmTarget != nil },
            set: { if !$0 { deleteConfirmTarget = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let target = deleteConfirmTarget {
                    profiles.removeAll { $0.id == target.id }
                }
                deleteConfirmTarget = nil
            }
            Button("Cancel", role: .cancel) { deleteConfirmTarget = nil }
        } message: {
            Text("\u{201C}\(deleteConfirmTarget?.name ?? "")\u{201D} will be removed permanently.")
        }
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let profile: GuidelineProfile
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: FS.xs) {
                    Text(profile.name)
                        .font(.flourishBody)
                        .foregroundColor(profile.isBuiltin ? .flourishTextSecondary : .flourishTextPrimary)
                    if profile.isBuiltin {
                        Text("BUILT-IN")
                            .font(.flourishMeta)
                            .foregroundColor(.flourishTextSecondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.flourishSurfaceRaised)
                            .cornerRadius(0)
                    }
                }
                Text(String(profile.systemPrompt.prefix(80)) + (profile.systemPrompt.count > 80 ? "…" : ""))
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextSecondary)
                    .lineLimit(2)
            }
            Spacer()
            HStack(spacing: FS.sm) {
                Button("Edit") { onEdit() }
                    .font(.flourishMeta)
                    .buttonStyle(.bordered)
                    .pointerCursor()
                if !profile.isBuiltin {
                    Button("Delete") { onDelete() }
                        .font(.flourishMeta)
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                        .pointerCursor()
                }
            }
        }
        .padding(.vertical, FS.xs)
    }
}
