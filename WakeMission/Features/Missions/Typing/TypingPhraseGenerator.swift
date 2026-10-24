import Foundation

struct TypingPhraseGenerator: Sendable {
    static let easyPhrases = [
        "Trust yourself.",
        "Today is a new day.",
        "Wake up and smile.",
        "Make it happen.",
        "Focus on the good.",
        "Rise and shine.",
        "You got this."
    ]

    static let mediumPhrases = [
        "Today will be a productive and successful day.",
        "Consistency is the key to unlocking your true potential.",
        "Get out of bed and conquer your morning goals.",
        "Small steps every day lead to massive achievements.",
        "Energy flows where your attention goes today.",
        "Every morning is a chance to start over."
    ]

    static let hardPhrases = [
        "Discipline is choosing between what you want now, and what you want most.",
        "Success is not final, failure is not fatal: it is the courage to continue that counts.",
        "The secret of getting ahead is getting started, without excuses.",
        "You don't have to be great to start, but you have to start to be great."
    ]

    static func phrases(for difficulty: MissionDifficulty) -> [String] {
        switch difficulty {
        case .easy: return easyPhrases
        case .medium: return mediumPhrases
        case .hard: return hardPhrases
        }
    }

    static func randomPhrase(for difficulty: MissionDifficulty) -> String {
        phrases(for: difficulty).randomElement() ?? "Trust yourself."
    }
}
