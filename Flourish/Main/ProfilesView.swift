import SwiftUI
import Defaults

// MARK: - Profiles View
// Full-panel guideline profile management (lifted from the old ProfilesTab).

struct ProfilesView: View {
    @Default(.profiles) private var profiles
    @State private var editingProfile: GuidelineProfile? = nil
    @State private var showAddSheet = false
    @State private var deleteConfirmTarget: GuidelineProfile? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Header ───────────────────────────────────────────────────────
            HStack {
                Text("Profiles")
                    .font(.flourishTitle)
                    .foregroundColor(.flourishTextPrimary)
                Spacer()
                Button {
                    editingProfile = nil
                    showAddSheet = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                        Text("New Profile")
                            .font(.flourishButton)
                    }
                    .foregroundColor(.flourishButtonLabel)
                    .padding(.horizontal, FS.md)
                    .padding(.vertical, FS.xs + 1)
                    .background(Color.flourishButtonBg)
                    .cornerRadius(FS.radiusSm)
                }
                .buttonStyle(.plain)
                .pointerCursor()
            }
            .padding(.horizontal, FS.xxl)
            .padding(.top, FS.xxl)
            .padding(.bottom, FS.lg)

            Rectangle()
                .fill(Color.flourishBorder)
                .frame(height: FS.borderWidth)

            // ── Profile List ─────────────────────────────────────────────────
            if profiles.isEmpty {
                VStack(spacing: FS.sm) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 28))
                        .foregroundColor(.flourishTextTertiary.opacity(0.5))
                    Text("No profiles yet")
                        .font(.flourishBody)
                        .foregroundColor(.flourishTextSecondary)
                    Text("Create a profile to apply custom instructions when improving prompts.")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.flourishSurface)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(profiles) { profile in
                            ProfileListRow(
                                profile: profile,
                                onEdit: {
                                    editingProfile = profile
                                    showAddSheet = true
                                },
                                onDelete: {
                                    deleteConfirmTarget = profile
                                }
                            )
                            Rectangle()
                                .fill(Color.flourishBorder)
                                .frame(height: FS.borderWidth)
                                .padding(.leading, FS.xxl)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .background(Color.flourishSurface)
            }
        }
        .background(Color.flourishSurface)
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

// MARK: - Profile List Row

private struct ProfileListRow: View {
    let profile: GuidelineProfile
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name)
                    .font(.flourishBody)
                    .foregroundColor(.flourishTextPrimary)
                Text(String(profile.systemPrompt.prefix(90)) + (profile.systemPrompt.count > 90 ? "…" : ""))
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextTertiary)
                    .lineLimit(2)
            }
            Spacer()
            HStack(spacing: FS.xs) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isHovered ? .flourishTextSecondary : .flourishTextTertiary.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointerCursor()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isHovered ? .red.opacity(0.75) : .flourishTextTertiary.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointerCursor()
            }
        }
        .padding(.horizontal, FS.xxl)
        .padding(.vertical, FS.md)
        .background(isHovered ? Color.flourishSurfaceRaised : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
        .pointerCursor()
    }
}
