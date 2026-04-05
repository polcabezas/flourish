import Foundation
import Defaults

// MARK: - Guideline Profile

struct GuidelineProfile: Identifiable, Codable, Hashable, Defaults.Serializable {
    var id: UUID
    var name: String
    var systemPrompt: String
    var isBuiltin: Bool

    init(id: UUID = UUID(), name: String, systemPrompt: String, isBuiltin: Bool = false) {
        self.id = id
        self.name = name
        self.systemPrompt = systemPrompt
        self.isBuiltin = isBuiltin
    }
}

// MARK: - Built-in Profiles

extension GuidelineProfile {
    static let builtins: [GuidelineProfile] = [
        GuidelineProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Clearer",
            systemPrompt: "Make the prompt completely unambiguous with exactly one valid interpretation. Use precise, concrete language. Remove vague qualifiers, pronouns without clear referents, and any phrasing that could be read in more than one way. Do not add new requirements or information not present in the original.",
            isBuiltin: true
        ),
        GuidelineProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "More Concise",
            systemPrompt: "Rewrite the prompt to be as short as possible while preserving every meaningful constraint, intent, and requirement. Strip filler words, redundant phrases, unnecessary context, and verbose phrasing. Every word must earn its place.",
            isBuiltin: true
        ),
        GuidelineProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "More Detailed",
            systemPrompt: "Expand the prompt by making all implicit requirements explicit: expected output format, relevant constraints, context the model needs, and edge cases worth addressing. Do not change the core intent — only add missing precision.",
            isBuiltin: true
        ),
        GuidelineProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Professional",
            systemPrompt: "Rewrite the prompt in formal, professional English suitable for business or academic communication. Eliminate contractions, colloquialisms, and informal phrasing. Use structured, precise language. Maintain all original requirements and intent.",
            isBuiltin: true
        ),
        GuidelineProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "Developer",
            systemPrompt: "Rewrite the prompt with technical precision for software development contexts. Specify data types, expected input/output formats, error conditions, edge cases, and any language, framework, or environment constraints that can be inferred from context. Use developer vocabulary.",
            isBuiltin: true
        ),
        GuidelineProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            name: "Creative",
            systemPrompt: "Reframe the prompt to invite imaginative, divergent, and unexpected responses. Use evocative, open-ended language that encourages exploration rather than a single correct answer. Preserve the original subject or theme but reframe it to spark creativity and original thinking.",
            isBuiltin: true
        ),
    ]
}
