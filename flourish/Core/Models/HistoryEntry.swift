import Foundation
import GRDB

// MARK: - History Entry (GRDB Record)

struct HistoryEntry: Identifiable {
    var id: Int64?
    var createdAt: Date
    var originalPrompt: String
    var improvedPrompt: String
    var provider: String       // "openrouter" | "groq"
    var modelId: String
    var tokensIn: Int
    var tokensOut: Int
    var estimatedCostUSD: Double

    init(
        id: Int64? = nil,
        createdAt: Date = Date(),
        originalPrompt: String,
        improvedPrompt: String,
        provider: String,
        modelId: String,
        tokensIn: Int,
        tokensOut: Int,
        estimatedCostUSD: Double
    ) {
        self.id = id
        self.createdAt = createdAt
        self.originalPrompt = originalPrompt
        self.improvedPrompt = improvedPrompt
        self.provider = provider
        self.modelId = modelId
        self.tokensIn = tokensIn
        self.tokensOut = tokensOut
        self.estimatedCostUSD = estimatedCostUSD
    }
}

// MARK: - GRDB Conformances

extension HistoryEntry: FetchableRecord {
    init(row: Row) throws {
        id               = row["id"]
        createdAt        = row["created_at"]
        originalPrompt   = row["original_prompt"]
        improvedPrompt   = row["improved_prompt"]
        provider         = row["provider"]
        modelId          = row["model_id"]
        tokensIn         = row["tokens_in"]
        tokensOut        = row["tokens_out"]
        estimatedCostUSD = row["estimated_cost_usd"]
    }
}

extension HistoryEntry: MutablePersistableRecord {
    static let databaseTableName = "history_entry"

    func encode(to container: inout PersistenceContainer) throws {
        container["id"]                 = id
        container["created_at"]         = createdAt
        container["original_prompt"]    = originalPrompt
        container["improved_prompt"]    = improvedPrompt
        container["provider"]           = provider
        container["model_id"]           = modelId
        container["tokens_in"]          = tokensIn
        container["tokens_out"]         = tokensOut
        container["estimated_cost_usd"] = estimatedCostUSD
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Helpers

extension HistoryEntry {
    var formattedCost: String {
        if estimatedCostUSD == 0 { return "Free" }
        if estimatedCostUSD < 0.001 { return "<$0.001" }
        return String(format: "$%.4f", estimatedCostUSD)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var truncatedOriginal: String {
        let trimmed = originalPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 60 { return trimmed }
        return String(trimmed.prefix(57)) + "..."
    }
}
