import Foundation
import Defaults

// MARK: - Target Platform

enum TargetPlatform: String, CaseIterable, Codable, Defaults.Serializable, Identifiable {
    case generic    = "generic"
    case claude     = "claude"
    case chatgpt    = "chatgpt"
    case gemini     = "gemini"
    case perplexity = "perplexity"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .generic:    return "Universal"
        case .claude:     return "Claude"
        case .chatgpt:    return "ChatGPT"
        case .gemini:     return "Gemini"
        case .perplexity: return "Perplexity"
        }
    }

    /// Appended to the system prompt to instruct the improving LLM how to format output.
    /// Edit these strings to update platform-specific formatting rules.
    var formattingInstruction: String? {
        switch self {
        case .generic:
            return nil
        case .claude:
            return """
            Format the rewritten prompt for Claude (Anthropic). \
            Use descriptive XML tags to delineate each section — e.g. <task>, <context>, <constraints>, <output_format> — \
            placing any reference material or background at the top and the specific question or request at the very end. \
            State the rationale alongside any constraint rather than listing rules in isolation \
            (e.g. "avoid ellipses because the output will be read by a TTS engine"). \
            Output only the formatted prompt — no preamble, no wrapper tags.
            """
        case .chatgpt:
            return """
            Format the rewritten prompt for ChatGPT (OpenAI GPT-4o). \
            Use Markdown as the primary structuring syntax: ### section headers, --- separators between content blocks, \
            bullet lists for unordered requirements, numbered steps for sequences, and triple backticks for code or structured data. \
            Place the core instructions at the beginning and repeat the single most critical constraint at the very end \
            to counteract the model's recency bias on long prompts. \
            Output only the formatted prompt — no preamble.
            """
        case .gemini:
            return """
            Format the rewritten prompt for Google Gemini. \
            Wrap all reference material and background in <context> XML tags at the start of the prompt, \
            then state the task instructions, and place the specific query at the very end \
            preceded by a transition phrase such as "Based on the information above,". \
            Define the role, expected output format, and key behavioral constraints at the top. \
            Keep all few-shot examples structurally identical to each other, as inconsistency in example format \
            is especially disruptive to Gemini. \
            Output only the formatted prompt — no preamble.
            """
        case .perplexity:
            return """
            Format the rewritten prompt for Perplexity AI (search-augmented). \
            The user-facing query drives Perplexity's live web search, so write it as a precise, \
            expert-level search query with 2–3 domain-specific context words — concise and keyword-rich, \
            not instructional or conversational. \
            Put any behavioral or output-format instructions in a brief system message section only; \
            never include few-shot examples, as they will be searched rather than interpreted as instructions. \
            Include temporal framing when recency matters (e.g. "as of 2025"). \
            Output only the formatted prompt — no preamble.
            """
        }
    }
}
