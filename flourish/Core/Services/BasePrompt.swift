import Foundation
import Defaults

enum BasePrompt {
    static let defaultTemplate = """
    You are a prompt engineer. Rewrite the user's raw prompt into a higher-quality version.

    Apply these guidelines to content and style:

    <guidelines>
    {guidelines}
    </guidelines>

    Rules that always apply regardless of guidelines:
    - Preserve all original intent. Never add goals or requirements not present in the original.
    - Output only the rewritten prompt. No preamble, no explanation, no wrapper tags. The first character of your response must be the first character of the rewritten prompt.
    """

    static func build(guidelines: String, targetPlatform: TargetPlatform = .generic) -> String {
        let stored = Defaults[.basePromptTemplate].trimmingCharacters(in: .whitespaces)
        let active = stored.isEmpty ? defaultTemplate : stored
        var prompt = active.replacingOccurrences(of: "{guidelines}", with: guidelines)
        if let instruction = targetPlatform.formattingInstruction {
            prompt += "\n\n" + instruction
        }
        return prompt
    }
}
