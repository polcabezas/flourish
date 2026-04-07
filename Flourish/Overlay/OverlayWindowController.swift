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
    private let hostingController: NSHostingController<OverlayView>

    private init() {
        panel = OverlayPanel()

        let view = OverlayView(viewModel: viewModel)
        hostingController = NSHostingController(rootView: view)
        // Tells the window to resize itself whenever the SwiftUI view's
        // preferred content size changes (i.e. as the user types).
        hostingController.sizingOptions = .preferredContentSize

        super.init(window: panel)
        panel.contentViewController = hostingController
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Show / Dismiss / Toggle

    func toggle() {
        guard AuthService.shared.currentUser != nil else {
            SignInWindowController.shared.show()
            return
        }
        if panel.isVisible {
            dismiss(paste: false)
        } else {
            show()
        }
    }

    func show() {
        // CRITICAL: Capture the previous app BEFORE showing the panel
        PasteService.shared.capturePreviousApp()

        // Reset the view model — loads any saved draft
        viewModel.reset()
        let hasDraft = !viewModel.promptText.isEmpty

        // Center the panel on the main screen
        centerOnScreen()

        // Bring panel forward and make it the key window (receives keyboard input)
        panel.makeKeyAndOrderFront(nil)

        // Install Escape key monitor
        installEscapeMonitor()

        // If a draft was restored, select all text so the user can type over it immediately
        if hasDraft {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
            }
        }
    }

    func dismiss(paste: Bool) {
        removeEscapeMonitor()
        let text = viewModel.promptText

        panel.orderOut(nil)

        // Persist or clear draft before reset
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if paste || trimmed.isEmpty {
            viewModel.clearDraft()
        } else {
            viewModel.saveDraft(text)
        }

        viewModel.reset()

        if paste && !trimmed.isEmpty {
            LoaderWindowController.shared.show()
            Task {
                await runLLM(text: text)
            }
        }
    }

    // MARK: - LLM Orchestration

    @MainActor
    private func runLLM(text: String) async {
        let service = flourishProxyService()
        let model = ""  // controlled by Cloudflare Worker env vars
        let guidelines = Defaults.selectedProfile()?.systemPrompt ?? ""
        let targetPlatform = Defaults[.targetPlatform]

        do {
            let response = try await service.improvePrompt(
                text,
                systemPrompt: BasePrompt.build(guidelines: guidelines, targetPlatform: targetPlatform),
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

            // Notify the Account view to refresh usage (counter just incremented on the server)
            NotificationCenter.default.post(name: .flourishDidImprovePrompt, object: nil)

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
        // Use sizeThatFits so the position is correct even before the first
        // layout pass (e.g. when a draft is restored on open).
        let fittingSize = hostingController.sizeThatFits(in: CGSize(width: FS.overlayWidth, height: .infinity))
        let panelSize = CGSize(
            width: FS.overlayWidth,
            height: fittingSize.height > 0 ? fittingSize.height : panel.frame.size.height
        )
        let x = screenFrame.midX - panelSize.width / 2
        // Center vertically, shifted slightly above mid — like Spotlight.
        // y is the bottom edge of the panel in AppKit screen coordinates.
        let y = screenFrame.midY - panelSize.height / 2 + screenFrame.height * 0.08
        panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: panelSize), display: false)
    }

    private func installEscapeMonitor() {
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            switch event.keyCode {
            case 53:  // Escape → dismiss (draft is auto-saved by dismiss logic)
                self?.dismiss(paste: false)
                return nil
            case 36, 76:  // Return / Enter (without Shift) → submit
                if !event.modifierFlags.contains(.shift) {
                    self?.dismiss(paste: true)
                    return nil
                }
                return event  // Shift+Return → allow newline in TextEditor
            case 126:  // Up arrow → previous history entry
                self?.viewModel.navigateUp()
                return nil
            case 125:  // Down arrow → next history entry (or back to draft)
                self?.viewModel.navigateDown()
                return nil
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
        alert.messageText = "flourish"
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
    @Published var draftRestored: Bool = false
    @Published var draftSavedAt: Date? = nil
    /// Toggled each time the overlay opens so the view can re-apply keyboard focus.
    @Published var focusTrigger: UUID = UUID()

    private var promptHistory: [String] = []  // most recent first
    private var historyIndex: Int = -1        // -1 = current draft
    private var draftText: String = ""

    private let draftKey     = "flourish.overlayDraft"
    private let draftDateKey = "flourish.overlayDraftDate"

    func reset() {
        let saved = UserDefaults.standard.string(forKey: draftKey) ?? ""
        promptText = saved
        draftRestored = !saved.isEmpty
        draftSavedAt = UserDefaults.standard.object(forKey: draftDateKey) as? Date
        draftText = ""
        historyIndex = -1
        focusTrigger = UUID()
        loadHistory()
    }

    func saveDraft(_ text: String) {
        let now = Date()
        UserDefaults.standard.set(text, forKey: draftKey)
        UserDefaults.standard.set(now, forKey: draftDateKey)
    }

    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: draftKey)
        UserDefaults.standard.removeObject(forKey: draftDateKey)
    }

    private func loadHistory() {
        let entries = (try? HistoryStore.shared.fetchAll(limit: 50)) ?? []
        promptHistory = entries.map { $0.originalPrompt }
    }

    func clearInput() {
        promptText = ""
        draftText = ""
        historyIndex = -1
    }

    func navigateUp() {
        guard !promptHistory.isEmpty else { return }

        // Save draft before the first navigation into history
        if historyIndex == -1 {
            draftText = promptText
        }

        let next = historyIndex + 1
        guard next < promptHistory.count else { return }
        historyIndex = next
        promptText = promptHistory[historyIndex]
    }

    func navigateDown() {
        guard historyIndex > -1 else { return }
        historyIndex -= 1
        promptText = historyIndex == -1 ? draftText : promptHistory[historyIndex]
    }
}
