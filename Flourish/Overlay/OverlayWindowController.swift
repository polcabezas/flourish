import AppKit
import SwiftUI
import Defaults

// MARK: - Overlay Window Controller

@MainActor
final class OverlayWindowController: NSWindowController {
    static let shared = OverlayWindowController()

    private let panel: OverlayPanel
    private var escapeMonitor: Any?
    private var viewModel = OverlayViewModel()

    private init() {
        panel = OverlayPanel()
        super.init(window: panel)

        let view = OverlayView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: view)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        panel.contentView = hostingView
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: panel.contentView!.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: panel.contentView!.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: panel.contentView!.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: panel.contentView!.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Show / Dismiss / Toggle

    func toggle() {
        if panel.isVisible {
            dismiss(paste: false)
        } else {
            show()
        }
    }

    func show() {
        // CRITICAL: Capture the previous app BEFORE showing the panel
        PasteService.shared.capturePreviousApp()

        // Reset the view model for a fresh prompt
        viewModel.reset()

        // Center the panel on the main screen
        centerOnScreen()

        // Bring panel forward and make it the key window (receives keyboard input)
        panel.makeKeyAndOrderFront(nil)

        // Install Escape key monitor
        installEscapeMonitor()
    }

    func dismiss(paste: Bool) {
        removeEscapeMonitor()
        let text = viewModel.promptText

        panel.orderOut(nil)
        viewModel.reset()

        if paste && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            LoaderWindowController.shared.show()
            Task {
                await runLLM(text: text)
            }
        }
    }

    // MARK: - LLM Orchestration

    @MainActor
    private func runLLM(text: String) async {
        let providerEnum = Defaults.activeProviderEnum
        let model: String
        let service: LLMService

        guard let apiKey = KeychainService.shared.load(for: providerEnum) else {
            LoaderWindowController.shared.hide()
            showError(LLMError.missingAPIKey(providerEnum))
            return
        }

        switch providerEnum {
        case .openRouter:
            service = OpenRouterService(apiKey: apiKey)
            model = Defaults[.openRouterModel]
        case .groq:
            service = GroqService(apiKey: apiKey)
            model = Defaults[.groqModel]
        }

        let guidelines = Defaults.selectedProfile()?.systemPrompt ?? ""

        do {
            let response = try await service.improvePrompt(
                text,
                systemPrompt: BasePrompt.build(guidelines: guidelines),
                model: model
            )

            LoaderWindowController.shared.hide()
            PasteService.shared.pasteText(response.improvedText)

            // Persist to history
            let cost = ModelOption.estimateCost(
                modelId: response.modelId,
                provider: response.provider,
                tokensIn: response.tokensIn,
                tokensOut: response.tokensOut
            )
            let entry = HistoryEntry(
                originalPrompt: text,
                improvedPrompt: response.improvedText,
                provider: response.provider.rawValue,
                modelId: response.modelId,
                tokensIn: response.tokensIn,
                tokensOut: response.tokensOut,
                estimatedCostUSD: cost
            )
            try? HistoryStore.shared.insert(entry)

            // Update all-time stats
            Defaults[.totalRequestCount] += 1
            Defaults[.totalTokensIn]     += response.tokensIn
            Defaults[.totalTokensOut]    += response.tokensOut
            Defaults[.totalCostUSD]      += cost

            // Update session stats
            SessionStatsTracker.shared.record(
                tokensIn: response.tokensIn,
                tokensOut: response.tokensOut,
                cost: cost
            )

        } catch {
            LoaderWindowController.shared.hide()
            showError(error)
        }
    }

    // MARK: - Helpers

    private func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size
        let x = screenFrame.midX - panelSize.width / 2
        let y = screenFrame.midY + screenFrame.height * 0.1  // slightly above center like Spotlight
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func installEscapeMonitor() {
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            switch event.keyCode {
            case 53:  // Escape → dismiss without paste
                self?.dismiss(paste: false)
                return nil
            case 36, 76:  // Return / Enter (without Shift) → submit
                if !event.modifierFlags.contains(.shift) {
                    self?.dismiss(paste: true)
                    return nil
                }
                return event  // Shift+Return → allow newline in TextEditor
            default:
                return event
            }
        }
    }

    private func removeEscapeMonitor() {
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }
    }

    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Flourish"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Overlay View Model

@MainActor
final class OverlayViewModel: ObservableObject {
    @Published var promptText: String = ""

    func reset() {
        promptText = ""
    }
}
