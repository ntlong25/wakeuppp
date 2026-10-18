import Foundation

struct TypingPhraseGenerator: Sendable {
    static let easyPhrases = [
        "Trust yourself.",
        "Today is a new day.",
        "Wake up and smile.",
        "Make it happen.",
        "Focus on the good."
    ]
    
    static let mediumPhrases = [
        "Today will be a productive and successful day.",
        "Consistency is the key to unlocking your true potential.",
        "Get out of bed and conquer your morning goals.",
        "Small steps every day lead to massive achievements."
    ]
    
    static let hardPhrases = [
        "Discipline is choosing between what you want now, and what you want most.",
        "Success is not final, failure is not fatal: it is the courage to continue that counts.",
        "The secret of getting ahead is getting started, without excuses."
    ]
    
    static func randomPhrase(for difficulty: MissionDifficulty) -> String {
        switch difficulty {
        case .easy:
            return easyPhrases.randomElement() ?? "Trust yourself."
        case .medium:
            return mediumPhrases.randomElement() ?? "Today will be a good day."
        case .hard:
            return hardPhrases.randomElement() ?? "Discipline equals freedom."
        }
    }
}
