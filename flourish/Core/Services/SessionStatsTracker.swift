import Foundation

// MARK: - Session Stats Tracker
// Lightweight singleton that accumulates per-session statistics.
// Lifetime: reset each app launch. Persisted totals live in Defaults.

final class SessionStatsTracker: ObservableObject {
    static let shared = SessionStatsTracker()
    private init() {}

    @Published private(set) var requestCount: Int = 0
    @Published private(set) var tokensIn:     Int = 0
    @Published private(set) var tokensOut:    Int = 0
    @Published private(set) var costUSD:      Double = 0.0

    func record(tokensIn: Int, tokensOut: Int, cost: Double) {
        requestCount += 1
        self.tokensIn  += tokensIn
        self.tokensOut += tokensOut
        self.costUSD   += cost
    }
}
