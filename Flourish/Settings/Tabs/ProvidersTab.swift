import SwiftUI
import Defaults

// MARK: - Providers Tab
// Configure OpenRouter and Groq — toggle, API key, model selection, active provider.

struct ProvidersTab: View {
    @Default(.openRouterEnabled)      private var openRouterEnabled
    @Default(.groqEnabled)            private var groqEnabled
    @Default(.activeProvider)         private var activeProvider
    @Default(.openRouterModel)        private var openRouterModel
    @Default(.groqModel)              private var groqModel
    @Default(.openRouterCustomModels) private var openRouterCustomModels
    @Default(.groqCustomModels)       private var groqCustomModels

    @State private var openRouterKey: String = ""
    @State private var groqKey: String       = ""
    @State private var testingProvider: LLMProvider? = nil
    @State private var testResult: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: FS.xxl) {
                // Active provider selector
                VStack(alignment: .leading, spacing: FS.sm) {
                    SectionLabel("Active Provider")
                    Picker("", selection: $activeProvider) {
                        ForEach(LLMProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .pointerCursor()
                    Text("Requests use the active provider.")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
                }

                Divider()

                // OpenRouter
                ProviderSection(
                    provider: .openRouter,
                    isEnabled: $openRouterEnabled,
                    apiKey: $openRouterKey,
                    selectedModel: $openRouterModel,
                    customModels: $openRouterCustomModels,
                    isTesting: testingProvider == .openRouter,
                    testResult: activeProvider == LLMProvider.openRouter.rawValue ? testResult : nil,
                    onTest: { testConnection(provider: .openRouter) },
                    onKeySave: { KeychainService.shared.save(openRouterKey, for: .openRouter) }
                )

                Divider()

                // Groq
                ProviderSection(
                    provider: .groq,
                    isEnabled: $groqEnabled,
                    apiKey: $groqKey,
                    selectedModel: $groqModel,
                    customModels: $groqCustomModels,
                    isTesting: testingProvider == .groq,
                    testResult: activeProvider == LLMProvider.groq.rawValue ? testResult : nil,
                    onTest: { testConnection(provider: .groq) },
                    onKeySave: { KeychainService.shared.save(groqKey, for: .groq) }
                )
            }
            .padding(FS.xxl)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            openRouterKey = KeychainService.shared.load(for: .openRouter) ?? ""
            groqKey       = KeychainService.shared.load(for: .groq)       ?? ""
        }
    }

    private func testConnection(provider: LLMProvider) {
        testingProvider = provider
        testResult = nil
        let key: String
        let model: String
        let service: LLMService

        switch provider {
        case .openRouter:
            key = openRouterKey
            model = openRouterModel
            service = OpenRouterService(apiKey: key)
        case .groq:
            key = groqKey
            model = groqModel
            service = GroqService(apiKey: key)
        }

        guard !key.isEmpty else {
            testResult = "No API key entered."
            testingProvider = nil
            return
        }

        Task {
            do {
                _ = try await service.improvePrompt("test", systemPrompt: "Say OK.", model: model)
                await MainActor.run {
                    testResult = "✓ Connection successful"
                    testingProvider = nil
                }
            } catch {
                await MainActor.run {
                    testResult = "✗ \(error.localizedDescription)"
                    testingProvider = nil
                }
            }
        }
    }
}

// MARK: - Provider Section

private struct ProviderSection: View {
    let provider: LLMProvider
    @Binding var isEnabled: Bool
    @Binding var apiKey: String
    @Binding var selectedModel: String
    @Binding var customModels: [String]
    let isTesting: Bool
    let testResult: String?
    let onTest: () -> Void
    let onKeySave: () -> Bool

    @State private var newModelInput: String = ""
    @State private var keySaveStatus: Bool? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: FS.md) {
            HStack {
                Text(provider.displayName)
                    .font(.flourishBody)
                    .fontWeight(.medium)
                Spacer()
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .pointerCursor()
            }

            if isEnabled {
                VStack(alignment: .leading, spacing: FS.sm) {
                    Text("API Key")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
                    HStack {
                        SecureField("Paste your API key here", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.flourishBody)
                            .onSubmit { saveKey() }
                        Button("Save") { saveKey() }
                            .font(.flourishBody)
                            .pointerCursor()
                        if let status = keySaveStatus {
                            Text(status ? "✓ Saved" : "✗ Failed")
                                .font(.flourishMeta)
                                .foregroundColor(status ? .green : .red)
                                .transition(.opacity)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: FS.sm) {
                    Text("Model")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
                    HStack {
                        TextField("Add model ID…", text: $newModelInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.flourishBody)
                            .onSubmit { addCustomModel() }
                        Button("Add") { addCustomModel() }
                            .font(.flourishBody)
                            .disabled(newModelInput.trimmingCharacters(in: .whitespaces).isEmpty)
                            .pointerCursor()
                    }
                    Picker("", selection: $selectedModel) {
                        ForEach(ModelOption.models(for: provider)) { model in
                            Text(model.displayName).tag(model.id)
                        }
                        if !customModels.isEmpty {
                            Divider()
                            ForEach(customModels, id: \.self) { modelId in
                                Text(modelId).tag(modelId)
                            }
                        }
                    }
                    .labelsHidden()
                    .pointerCursor()
                }

                HStack {
                    Button(isTesting ? "Testing…" : "Test Connection") { onTest() }
                        .font(.flourishBody)
                        .disabled(isTesting || apiKey.isEmpty)
                        .pointerCursor()

                    if let result = testResult {
                        Text(result)
                            .font(.flourishMeta)
                            .foregroundColor(result.hasPrefix("✓") ? .green : .red)
                    }
                }
            }
        }
        .opacity(isEnabled ? 1 : 0.5)
    }

    private func saveKey() {
        let success = onKeySave()
        withAnimation { keySaveStatus = success }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { keySaveStatus = nil }
        }
    }

    private func addCustomModel() {
        let trimmed = newModelInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              !ModelOption.models(for: provider).contains(where: { $0.id == trimmed }),
              !customModels.contains(trimmed) else { return }
        customModels.append(trimmed)
        selectedModel = trimmed
        newModelInput = ""
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.flourishMeta)
            .foregroundColor(.flourishTextSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}
