import Foundation

// MARK: - Profile Generator Service
// Calls the flourish proxy with a meta-prompt to generate a custom GuidelineProfile
// from a plain-language description of the user's role and tasks.

final class ProfileGeneratorService {
    private let proxy = flourishProxyService()

    private static let metaPrompt = """
    You are a profile generator for flourish, a tool that improves AI prompts for office \
    professionals who are not prompt engineers.

    Given a description of someone's role and work, generate a custom profile that will \
    rewrite their prompts so an AI assistant produces the best possible output for their \
    specific professional context.

    Generate:
    1. A short profile name (2–4 words) that clearly describes their work context.
    2. A systemPrompt that instructs an AI to rewrite prompts to produce ideal output for \
    this professional.

    The systemPrompt must:
    - Open with: "Rewrite this prompt so an AI assistant produces..."
    - Be outcome-oriented: specify the exact output format, tone, structure, and level of \
    detail needed for their role.
    - Reference the professional's specific context and typical tasks from their description.
    - Make implicit requirements explicit, but only from what is present in the user's \
    original prompt — never invent context that isn't there.
    - Close with a preservation rule in this exact form: "Include only context present in \
    the original — do not invent [role-specific details] if not stated." substituting \
    [role-specific details] with the most relevant examples for this professional (e.g. \
    "the recipient, tone, or deadline" for an email-heavy role).
    - Be written for a non-technical professional — focus on practical, work-ready output, \
    not prompt engineering theory.

    Respond with valid JSON only. No markdown, no code fences, no explanation:
    {"name": "...", "systemPrompt": "..."}
    """

    func generate(from description: String) async throws -> GuidelineProfile {
        let response = try await proxy.improvePrompt(
            description,
            systemPrompt: Self.metaPrompt,
            model: ""
        )

        let raw = response.improvedText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = raw.data(using: .utf8) else {
            throw LLMError.invalidResponse
        }

        struct Parsed: Decodable {
            let name: String
            let systemPrompt: String
        }

        let parsed = try JSONDecoder().decode(Parsed.self, from: data)
        return GuidelineProfile(
            name: parsed.name.trimmingCharacters(in: .whitespaces),
            systemPrompt: parsed.systemPrompt.trimmingCharacters(in: .whitespaces)
        )
    }
}
