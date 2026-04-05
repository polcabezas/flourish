import SwiftUI
import AppKit
import Defaults
import LaunchAtLogin
import KeyboardShortcuts

// MARK: - Settings Panel View
// Inline settings — replaces the old TabView window.
// Three sections: Providers · Shortcut · General

struct SettingsPanelView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Settings")
                    .font(.flourishTitle)
                    .foregroundColor(.flourishTextPrimary)
                    .padding(.horizontal, FS.xxl)
                    .padding(.top, FS.xxl)
                    .padding(.bottom, FS.lg)

                Rectangle()
                    .fill(Color.flourishBorder)
                    .frame(height: FS.borderWidth)

                // Sections
                ProvidersSection()

                SectionDivider()

                ShortcutSection()

                SectionDivider()

                BasePromptSection()

                SectionDivider()

                GeneralSection()

                Spacer(minLength: FS.xxl)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.flourishSurface)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Section Divider

private struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.flourishBorder)
            .frame(height: FS.borderWidth)
            .padding(.horizontal, FS.xxl)
            .padding(.vertical, FS.lg)
    }
}

// MARK: - Providers Section

private struct ProvidersSection: View {
    @Default(.openRouterEnabled)      private var openRouterEnabled
    @Default(.groqEnabled)            private var groqEnabled
    @Default(.activeProvider)         private var activeProvider
    @Default(.openRouterModel)        private var openRouterModel
    @Default(.groqModel)              private var groqModel
    @Default(.openRouterCustomModels) private var openRouterCustomModels
    @Default(.groqCustomModels)       private var groqCustomModels

    @State private var openRouterKey: String = ""
    @State private var groqKey: String = ""
    @State private var testingProvider: LLMProvider? = nil
    @State private var testResult: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: FS.lg) {
            PanelSectionLabel("Providers")

            // Active provider
            VStack(alignment: .leading, spacing: FS.sm) {
                Text("Active Provider")
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextSecondary)
                Picker("", selection: $activeProvider) {
                    ForEach(LLMProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .pointerCursor()
            }

            // OpenRouter
            ProviderBlock(
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

            ProviderBlock(
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
        .padding(.horizontal, FS.xxl)
        .padding(.top, FS.lg)
        .padding(.bottom, 0)
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

// MARK: - Provider Block

private struct ProviderBlock: View {
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
        VStack(alignment: .leading, spacing: FS.sm) {
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

                    Text("Model")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
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

                    HStack {
                        TextField("Add model ID…", text: $newModelInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.flourishBody)
                            .onSubmit { addCustomModel() }
                        Button("Add") { addCustomModel() }
                            .font(.flourishBody)
                            .pointerCursor()
                            .disabled(newModelInput.trimmingCharacters(in: .whitespaces).isEmpty)
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
                .padding(.leading, FS.sm)
            }
        }
        .padding(FS.md)
        .background(Color.flourishSurfaceRaised.opacity(0.5))
        .cornerRadius(FS.radiusMd)
        .opacity(isEnabled ? 1 : 0.6)
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

// MARK: - Shortcut Section

private struct ShortcutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FS.md) {
            PanelSectionLabel("Shortcut")

            KeyboardShortcuts.Recorder("Open Flourish", name: .openOverlay)
                .font(.flourishBody)

            Text("Click the field and press your desired key combination. Default: ⌃ Space")
                .font(.flourishMeta)
                .foregroundColor(.flourishTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("If ⌃ Space conflicts with Input Source switching, remap it here or disable the system shortcut in System Settings → Keyboard → Shortcuts → Input Sources.")
                .font(.flourishMeta)
                .foregroundColor(.flourishTextTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, FS.xxl)
        .padding(.top, 0)
    }
}

// MARK: - Base Prompt Section

private struct BasePromptSection: View {
    @Default(.basePromptTemplate) private var basePromptTemplate

    private var isCustom: Bool {
        !basePromptTemplate.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var missingPlaceholder: Bool {
        isCustom && !basePromptTemplate.contains("{guidelines}")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FS.md) {
            HStack {
                PanelSectionLabel("Base Prompt")
                Spacer()
                if isCustom {
                    Button("Reset to Default") {
                        basePromptTemplate = ""
                    }
                    .font(.flourishMeta)
                    .foregroundColor(.flourishAccent)
                    .buttonStyle(.plain)
                    .pointerCursor()
                }
            }

            ZStack(alignment: .topLeading) {
                if !isCustom {
                    Text(BasePrompt.defaultTemplate)
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextTertiary)
                        .padding(.horizontal, FS.sm)
                        .padding(.vertical, FS.sm)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $basePromptTemplate)
                    .font(.flourishMeta)
                    .frame(minHeight: 160)
                    .scrollContentBackground(.hidden)
                    .padding(FS.xs)
            }
            .background(Color.flourishSurfaceRaised.opacity(0.5))
            .cornerRadius(FS.radiusSm)
            .overlay(
                RoundedRectangle(cornerRadius: FS.radiusSm)
                    .stroke(missingPlaceholder ? Color.orange.opacity(0.6) : Color.flourishBorder, lineWidth: FS.borderWidth)
            )

            if missingPlaceholder {
                Text("⚠ Your template must include {guidelines} — otherwise profile guidelines won't be applied.")
                    .font(.flourishMeta)
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Use {guidelines} where profile guidelines are inserted. Leave empty to use the built-in default.")
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, FS.xxl)
        .padding(.top, 0)
    }
}

// MARK: - General Section

private struct GeneralSection: View {
    @Default(.launchAtLogin) private var launchAtLogin
    @Default(.showDockIcon)  private var showDockIcon

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FS.md) {
            PanelSectionLabel("General")

            LaunchAtLogin.Toggle {
                Text("Launch Flourish at login")
                    .font(.flourishBody)
            }
            .onChange(of: launchAtLogin) { newValue in
                Defaults[.launchAtLogin] = newValue
            }
            .pointerCursor()

            Text("Flourish runs quietly in the menu bar and is always ready when you need it.")
                .font(.flourishMeta)
                .foregroundColor(.flourishTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: $showDockIcon) {
                Text("Show dock icon")
                    .font(.flourishBody)
            }
            .onChange(of: showDockIcon) { newValue in
                NSApp.setActivationPolicy(newValue ? .regular : .accessory)
            }
            .pointerCursor()

            Divider()
                .padding(.vertical, FS.xs)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    FlourishLogoSymbol(size: 20, color: .flourishAccent)
                    Text("Flourish")
                        .font(.flourishBody)
                        .fontWeight(.medium)
                }
                Text("Version \(appVersion) (\(buildNumber)) · macOS 13+")
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextTertiary)
            }
        }
        .padding(.horizontal, FS.xxl)
        .padding(.top, 0)
    }
}

// MARK: - Panel Section Label

private struct PanelSectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.flourishMeta)
            .foregroundColor(.flourishTextTertiary)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}
