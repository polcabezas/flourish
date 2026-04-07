import SwiftUI

// MARK: - Generate Profile Sheet
// Two-stage modal: (1) user describes their role → (2) review and edit the generated profile.
// On save, calls onSave with the final GuidelineProfile.

struct GenerateProfileSheet: View {
    let onSave: (GuidelineProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .describe

    var body: some View {
        switch stage {
        case .describe:
            DescribeStage { generated in
                stage = .review(generated)
            }
        case .review(let generated):
            ReviewStage(
                generated: generated,
                onBack: { stage = .describe },
                onSave: { profile in
                    onSave(profile)
                    dismiss()
                }
            )
        }
    }

    private enum Stage {
        case describe
        case review(GuidelineProfile)
    }
}

// MARK: - Stage 1: Describe

private struct DescribeStage: View {
    let onGenerated: (GuidelineProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var isGenerating = false
    @State private var errorMessage: String? = nil

    private let service = ProfileGeneratorService()

    private var canGenerate: Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty && !isGenerating
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Generate Profile with AI")
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
                    Text("Describe your role and what you use AI for at work")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
                    TextEditor(text: $description)
                        .font(.flourishBody)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: FS.radiusSm)
                                .stroke(Color.flourishBorder, lineWidth: FS.borderWidth)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: FS.radiusSm))
                    Text("e.g. \"I'm a marketing manager who writes campaign briefs, client proposals, and social media content.\"")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.flourishMeta)
                        .foregroundColor(.red)
                }
            }
            .padding(FS.xxl)

            Spacer()

            Divider()
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(.flourishBody)
                    .keyboardShortcut(.cancelAction)
                    .pointerCursor()
                Button {
                    generate()
                } label: {
                    if isGenerating {
                        HStack(spacing: FS.xs) {
                            ProgressView().controlSize(.small)
                            Text("Generating…")
                        }
                    } else {
                        Text("Generate →")
                    }
                }
                .font(.flourishButton)
                .keyboardShortcut(.defaultAction)
                .disabled(!canGenerate)
                .pointerCursor()
            }
            .padding(FS.lg)
            .background(Color.flourishSurfaceRaised)
        }
        .frame(width: 500, height: 360)
    }

    private func generate() {
        errorMessage = nil
        isGenerating = true
        Task {
            do {
                let profile = try await service.generate(from: description)
                await MainActor.run {
                    isGenerating = false
                    onGenerated(profile)
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Stage 2: Review & Edit

private struct ReviewStage: View {
    let generated: GuidelineProfile
    let onBack: () -> Void
    let onSave: (GuidelineProfile) -> Void

    @State private var name: String
    @State private var systemPrompt: String

    init(generated: GuidelineProfile, onBack: @escaping () -> Void, onSave: @escaping (GuidelineProfile) -> Void) {
        self.generated = generated
        self.onBack = onBack
        self.onSave = onSave
        _name = State(initialValue: generated.name)
        _systemPrompt = State(initialValue: generated.systemPrompt)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !systemPrompt.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Review Generated Profile")
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
                    TextField("Profile name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.flourishBody)
                }

                VStack(alignment: .leading, spacing: FS.xs) {
                    Text("Guidelines")
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
                    Text("You can edit the generated guidelines before saving.")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
                }
            }
            .padding(FS.xxl)

            Spacer()

            Divider()
            HStack {
                Button("← Back") { onBack() }
                    .font(.flourishBody)
                    .pointerCursor()
                Spacer()
                Button("Save") {
                    let saved = GuidelineProfile(
                        id: generated.id,
                        name: name.trimmingCharacters(in: .whitespaces),
                        systemPrompt: systemPrompt.trimmingCharacters(in: .whitespaces)
                    )
                    onSave(saved)
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
