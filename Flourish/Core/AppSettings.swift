import Foundation
import Defaults

// MARK: - All Application Settings (Defaults-backed)

extension Defaults.Keys {

    // MARK: Profiles
    static let profiles              = Key<[GuidelineProfile]>("profiles",              default: [])
    static let lastSelectedProfileId = Key<String>("lastSelectedProfileId",             default: "")

    // MARK: Stats — All-time totals
    static let totalRequestCount = Key<Int>("totalRequestCount",    default: 0)
    static let totalTokensIn     = Key<Int>("totalTokensIn",        default: 0)
    static let totalTokensOut    = Key<Int>("totalTokensOut",       default: 0)
    static let totalCostUSD      = Key<Double>("totalCostUSD",      default: 0.0)

    // MARK: Base Prompt
    /// Custom base prompt template. Empty string = use the hardcoded default in BasePrompt.
    static let basePromptTemplate = Key<String>("basePromptTemplate", default: "")

    // MARK: General
    static let launchAtLogin  = Key<Bool>("launchAtLogin",  default: true)
    static let showDockIcon   = Key<Bool>("showDockIcon",   default: false)
}

// MARK: - Computed Helpers

extension Defaults {
    static func selectedProfile() -> GuidelineProfile? {
        let id = Defaults[.lastSelectedProfileId]
        return Defaults[.profiles].first(where: { $0.id.uuidString == id })
            ?? Defaults[.profiles].first
    }
}
