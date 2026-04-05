import SwiftUI

// MARK: - Profile Edit Sheet (add or edit a guideline profile)

struct ProfileEditSheet: View {
    let existingProfile: GuidelineProfile?
    let onSave: (GuidelineProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var systemPrompt: String = ""

    init(existingProfile: GuidelineProfile?, onSave: @escaping (GuidelineProfile) -> Void) {
        self.existingProfile = existingProfile
        self.onSave = onSave
        _name = State(initialValue: existingProfile?.name ?? "")
        _systemPrompt = State(initialValue: existingProfile?.systemPrompt ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !systemPrompt.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(existingProfile == nil ? "New Profile" : "Edit Profile")
                    .font(.flourishBody)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(FS.xxl)
            .background(Color.flourishSurfaceRaised)

            Divider()

            // Form
            VStack(alignment: .leading, spacing: FS.lg) {
                VStack(alignment: .leading, spacing: FS.xs) {
                    Text("Name")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
                    TextField("e.g. Technical Precision", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.flourishBody)
                }

                VStack(alignment: .leading, spacing: FS.xs) {
                    Text("System Prompt")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
                    TextEditor(text: $systemPrompt)
                        .font(.flourishBody)
                        .frame(minHeight: 160)
                        .overlay(
                            RoundedRectangle(cornerRadius: FS.radiusSm)
                                .stroke(Color.flourishBorder, lineWidth: FS.borderWidth)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: FS.radiusSm))
                    Text("This is the instruction sent to the LLM before your prompt.")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
                }
            }
            .padding(FS.xxl)

            Spacer()

            // Actions
            Divider()
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(.flourishBody)
                    .keyboardShortcut(.cancelAction)
                    .pointerCursor()
                Button("Save") {
                    let saved = GuidelineProfile(
                        id: existingProfile?.id ?? UUID(),
                        name: name.trimmingCharacters(in: .whitespaces),
                        systemPrompt: systemPrompt.trimmingCharacters(in: .whitespaces),
                        isBuiltin: existingProfile?.isBuiltin ?? false
                    )
                    onSave(saved)
                    dismiss()
                }
                .font(.flourishButton)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
                .pointerCursor()
            }
            .padding(FS.lg)
            .background(Color.flourishSurfaceRaised)
        }
        .frame(width: 500, height: 440)
    }
}
