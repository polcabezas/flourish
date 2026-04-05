import Foundation
import Defaults

enum BasePrompt {
    static let defaultTemplate = """
    You are a prompt refinement assistant. Your sole task is to rewrite the user's prompt so that an LLM produces the highest-quality response possible.

    Apply the following guidelines when rewriting:

    <guidelines>
    {guidelines}
    </guidelines>

    Return only the rewritten prompt — no explanation, no preamble.
    """

    static func build(guidelines: String) -> String {
        let stored = Defaults[.basePromptTemplate].trimmingCharacters(in: .whitespaces)
        let active = stored.isEmpty ? defaultTemplate : stored
        return active.replacingOccurrences(of: "{guidelines}", with: guidelines)
    }
}
