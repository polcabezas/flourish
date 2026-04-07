import Foundation
import AppKit
import Combine
import Defaults

// MARK: - Notification Names

extension Notification.Name {
    /// Posted by OverlayWindowController after a successful prompt improvement.
    static let flourishDidImprovePrompt = Notification.Name("flourish.didImprovePrompt")
}

// MARK: - Usage Info

struct UsageInfo {
    let plan: String
    let requestsThisMonth: Int
    let limit: Int?      // nil = unlimited (pro plan)
    let resetAt: String
}

// MARK: - Account View Model

@MainActor
final class AccountViewModel: ObservableObject {
    @Published var usage: UsageInfo? = nil
    @Published var isLoadingUsage = false
    @Published var billingError: String? = nil

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Refresh after each successful improvement (counter just incremented on the server)
        NotificationCenter.default.publisher(for: .flourishDidImprovePrompt)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in Task { @MainActor [weak self] in await self?.loadUsage() } }
            .store(in: &cancellables)

        // Refresh when the user brings the app back to the foreground (catches plan changes)
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in Task { @MainActor [weak self] in await self?.loadUsage() } }
            .store(in: &cancellables)
    }

    // MARK: - Load Usage

    func loadUsage() async {
        guard let token = await AuthService.shared.currentAccessToken() else { return }
        isLoadingUsage = true
        defer { isLoadingUsage = false }

        var req = URLRequest(url: proxyURL("account/usage"))
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard
            let (data, _) = try? await URLSession.shared.data(for: req),
            let decoded = try? JSONDecoder().decode(UsageResponse.self, from: data)
        else { return }

        usage = UsageInfo(
            plan: decoded.plan,
            requestsThisMonth: decoded.requests_this_month,
            limit: decoded.limit,
            resetAt: decoded.reset_at
        )
        Defaults[.lastKnownSubscription] = decoded.plan
    }

    // MARK: - Open Stripe Billing Portal

    func openBillingPortal() async {
        billingError = nil
        guard let token = await AuthService.shared.currentAccessToken() else { return }

        if let url = await fetchPortalURL(token: token) { NSWorkspace.shared.open(url); return }

        // On 401 the session may be expired — retry with a refreshed token
        guard let refreshedToken = await AuthService.shared.currentAccessToken() else { return }
        if let url = await fetchPortalURL(token: refreshedToken) { NSWorkspace.shared.open(url); return }

        billingError = "Could not open billing portal. Try again."
    }

    private func fetchPortalURL(token: String) async -> URL? {
        var req = URLRequest(url: proxyURL("billing/portal"))
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard
            let (data, response) = try? await URLSession.shared.data(for: req),
            (response as? HTTPURLResponse)?.statusCode == 200,
            let resp = try? JSONDecoder().decode(URLPayload.self, from: data),
            let url = URL(string: resp.url)
        else { return nil }
        return url
    }

    // MARK: - Open Stripe Checkout

    func openCheckout(billingPeriod: String = "monthly") async {
        billingError = nil
        print("[Checkout] openCheckout called, billingPeriod=\(billingPeriod)")
        guard let token = await AuthService.shared.currentAccessToken() else {
            print("[Checkout] currentAccessToken() returned nil — no session")
            billingError = "Not signed in. Please sign out and sign in again."
            return
        }
        print("[Checkout] got token, length=\(token.count)")

        let bodyDict: [String: String] = [
            "billing_period": billingPeriod,
            "success_url": "https://flourish.app/billing/success",
            "cancel_url":  "https://flourish.app/billing/cancel",
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict) else { return }

        let (data, statusCode) = await performCheckoutRequest(token: token, bodyData: bodyData)

        // On 401 the session may be expired — supabase-swift auto-refreshes on next access
        if statusCode == 401 {
            guard let refreshedToken = await AuthService.shared.currentAccessToken() else { return }
            let (retryData, retryStatus) = await performCheckoutRequest(token: refreshedToken, bodyData: bodyData)
            handleCheckoutResponse(data: retryData, statusCode: retryStatus)
            return
        }

        handleCheckoutResponse(data: data, statusCode: statusCode)
    }

    private func performCheckoutRequest(token: String, bodyData: Data) async -> (Data, Int) {
        let url = proxyURL("billing/checkout")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        print("[Checkout] POST \(url)")
        print("[Checkout] token prefix: \(String(token.prefix(20)))…")
        print("[Checkout] body: \(String(data: bodyData, encoding: .utf8) ?? "nil")")

        guard let (data, response) = try? await URLSession.shared.data(for: req) else {
            print("[Checkout] URLSession threw — network error or bad URL")
            return (Data(), 0)
        }
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
        print("[Checkout] status: \(statusCode), body: \(body)")
        return (data, statusCode)
    }

    private func handleCheckoutResponse(data: Data, statusCode: Int) {
        if let resp = try? JSONDecoder().decode(URLPayload.self, from: data),
           let url = URL(string: resp.url) {
            NSWorkspace.shared.open(url)
            return
        }
        let serverMessage = String(data: data, encoding: .utf8) ?? "empty response"
        billingError = "Checkout failed (\(statusCode)): \(serverMessage)"
    }

    // MARK: - Helpers

    private func proxyURL(_ path: String) -> URL {
        let base = Bundle.main.infoDictionary?["flourishProxyURL"] as? String ?? ""
        return URL(string: "https://\(base)/\(path)")!
    }

    private struct UsageResponse: Decodable {
        let plan: String
        let requests_this_month: Int
        let limit: Int?      // null from worker = unlimited
        let reset_at: String
    }

    private struct URLPayload: Decodable {
        let url: String
    }
}
