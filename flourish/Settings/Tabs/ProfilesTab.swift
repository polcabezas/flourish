import SwiftUI
import Defaults

// MARK: - Profiles Tab

struct ProfilesTab: View {
    @Default(.profiles) private var profiles
    @State private var editingProfile: GuidelineProfile? = nil
    @State private var showAddSheet = false
    @State private var showGenerateSheet = false
    @State private var deleteConfirmTarget: GuidelineProfile? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toolbar
            HStack {
                SectionLabel("Guideline Profiles")
                Spacer()
                Button {
                    showGenerateSheet = true
                } label: {
                    Label("Generate with AI", systemImage: "sparkles")
                        .font(.flourishBody)
                }
                .buttonStyle(.bordered)
                .pointerCursor()
                Button {
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
            ProfileEditSheet(existingProfile: nil) { saved in
                profiles.append(saved)
            }
        }
        .sheet(isPresented: $showGenerateSheet) {
            GenerateProfileSheet { saved in
                profiles.append(saved)
            }
        }
        .sheet(item: $editingProfile) { profile in
            ProfileEditSheet(existingProfile: profile) { saved in
                if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
                    profiles[idx] = saved
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
            if !profile.isBuiltin {
                HStack(spacing: FS.sm) {
                    Button("Edit") { onEdit() }
                        .font(.flourishMeta)
                        .buttonStyle(.bordered)
                        .pointerCursor()
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
