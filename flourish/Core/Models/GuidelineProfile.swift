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
            name: "Professional Email",
            systemPrompt: "Rewrite this prompt so an AI assistant produces a complete, professional email or message that is ready to send. The rewritten prompt must specify: the relationship and context between sender and recipient, the single clear objective the email must achieve, the appropriate tone (formal for client or executive communication, professional but warm for colleagues), and that the output should be concise unless the context genuinely requires detail. Include only context present in the original — do not invent the recipient, relationship, or objective if not stated.",
            isBuiltin: true
        ),
        GuidelineProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Summarize",
            systemPrompt: "Rewrite this prompt so an AI assistant produces a crisp, actionable summary. The rewritten prompt must ask for: a one-sentence TL;DR at the top, the 3–5 most important points as bullet points, any decisions or actions clearly highlighted, and a total length no longer than 20% of the source. Include the intended audience only if stated in the original.",
            isBuiltin: true
        ),
        GuidelineProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Explain Simply",
            systemPrompt: "Rewrite this prompt so an AI assistant produces a clear, jargon-free explanation that any professional can understand regardless of their technical background. The rewritten prompt must ask for: plain language with no unexplained terms, at least one concrete real-world example or analogy, a structure that starts with the big picture before going into specifics, and a length appropriate to the complexity of the topic. Include the professional context from the original prompt so the explanation stays relevant to the user's field.",
            isBuiltin: true
        ),
        GuidelineProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Draft a Document",
            systemPrompt: "Rewrite this prompt so an AI assistant produces a complete, well-structured professional document ready to use or adapt. The rewritten prompt must specify: the document type and its purpose (report, proposal, memo, brief, plan, etc.), the intended audience and their familiarity with the subject, a structure appropriate to the document type, and a professional tone throughout. Include only context present in the original — do not invent the document type, audience, or purpose if not stated.",
            isBuiltin: true
        ),
        GuidelineProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "Analyze & Advise",
            systemPrompt: "Rewrite this prompt so an AI assistant produces a clear, decision-ready analysis with a concrete recommendation. The rewritten prompt must ask for: a direct upfront recommendation or verdict, the key reasons or evidence supporting it, the main risks or counterarguments to be aware of, and specific next steps the person can take. The tone should be that of a trusted advisor — concise, honest, and practical rather than academic. Include the business or professional context from the original so the advice is grounded and specific.",
            isBuiltin: true
        ),
        GuidelineProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            name: "Brainstorm",
            systemPrompt: "Rewrite this prompt so an AI assistant generates a diverse set of practical, actionable ideas or options. The rewritten prompt must ask for: 5 to 8 distinct ideas that are meaningfully different from each other (not variations on the same theme), a one-sentence rationale for each, and a note on which ideas are fastest to implement versus which have the highest potential impact. Include only constraints explicitly stated in the original — audience, budget, timeframe, industry, or brand.",
            isBuiltin: true
        ),
    ]
}
