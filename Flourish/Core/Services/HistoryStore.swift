import Foundation
import GRDB

extension Notification.Name {
    static let historyDidChange = Notification.Name("flourish.historyDidChange")
}

// MARK: - History Store (GRDB SQLite)

final class HistoryStore {
    static let shared = HistoryStore()

    private var db: DatabaseQueue!
    private let maxEntries = 500

    private init() {
        setupDatabase()
    }

    // MARK: - Setup

    private func setupDatabase() {
        do {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!
            let dir = appSupport.appendingPathComponent("com.personal.flourish", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let dbPath = dir.appendingPathComponent("history.db").path
            db = try DatabaseQueue(path: dbPath)
            try migrate()
        } catch {
            print("HistoryStore setup error: \(error)")
        }
    }

    private func migrate() throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "history_entry", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("created_at",          .datetime).notNull().indexed()
                t.column("original_prompt",      .text).notNull()
                t.column("improved_prompt",      .text).notNull()
                t.column("provider",             .text).notNull()
                t.column("model_id",             .text).notNull()
                t.column("tokens_in",            .integer).notNull().defaults(to: 0)
                t.column("tokens_out",           .integer).notNull().defaults(to: 0)
                t.column("estimated_cost_usd",   .double).notNull().defaults(to: 0)
            }
        }
        try migrator.migrate(db)
    }

    // MARK: - Insert

    func insert(_ entry: HistoryEntry) throws {
        try db.write { db in
            var e = entry
            try e.insert(db)
            // Trim to maxEntries: delete oldest rows beyond limit
            let count = try HistoryEntry.fetchCount(db)
            if count > maxEntries {
                let overflow = count - maxEntries
                try db.execute(
                    sql: """
                    DELETE FROM history_entry WHERE id IN (
                        SELECT id FROM history_entry ORDER BY created_at ASC LIMIT ?
                    )
                    """,
                    arguments: [overflow]
                )
            }
        }
        NotificationCenter.default.post(name: .historyDidChange, object: nil)
    }

    // MARK: - Fetch

    func fetchAll(search: String = "", limit: Int = 200) throws -> [HistoryEntry] {
        try db.read { db in
            if search.isEmpty {
                return try HistoryEntry
                    .order(Column("created_at").desc)
                    .limit(limit)
                    .fetchAll(db)
            } else {
                let pattern = "%\(search)%"
                return try HistoryEntry
                    .filter(Column("original_prompt").like(pattern) ||
                            Column("improved_prompt").like(pattern))
                    .order(Column("created_at").desc)
                    .limit(limit)
                    .fetchAll(db)
            }
        }
    }

    // MARK: - Delete

    func delete(id: Int64) throws {
        try db.write { db in
            try db.execute(sql: "DELETE FROM history_entry WHERE id = ?", arguments: [id])
        }
        NotificationCenter.default.post(name: .historyDidChange, object: nil)
    }

    func deleteAll() throws {
        try db.write { db in
            try db.execute(sql: "DELETE FROM history_entry")
        }
        NotificationCenter.default.post(name: .historyDidChange, object: nil)
    }

    func totalCount() throws -> Int {
        try db.read { db in
            try HistoryEntry.fetchCount(db)
        }
    }
}
