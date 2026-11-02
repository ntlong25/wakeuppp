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

    static let easyPhrasesVI = [
        "Dậy thôi nào.",
        "Mở mắt ra đi.",
        "Ngày mới vui vẻ.",
        "Bạn làm được mà.",
        "Ra khỏi giường nào.",
        "Hôm nay sẽ ổn thôi.",
        "Cố lên nhé."
    ]

    static let mediumPhrasesVI = [
        "Hôm nay là một ngày mới đầy năng lượng.",
        "Dậy sớm hơn một chút, ngày dài hơn nhiều.",
        "Rửa mặt, uống nước và bắt đầu ngày mới.",
        "Mỗi buổi sáng là một cơ hội để làm lại.",
        "Từng bước nhỏ mỗi ngày sẽ đưa bạn đi xa.",
        "Giường vẫn ở đó, nhưng hôm nay thì không chờ."
    ]

    static let hardPhrasesVI = [
        "Kỷ luật là chọn điều bạn muốn nhất, thay vì điều bạn muốn ngay lúc này.",
        "Đừng đợi có hứng rồi mới dậy, cứ dậy trước và hứng thú sẽ đến sau.",
        "Năm phút nữa thường thành một giờ nữa, vậy nên hãy đứng dậy ngay bây giờ.",
        "Người chiến thắng buổi sáng thường là người chiến thắng cả ngày hôm đó."
    ]

    /// Phrases follow the language the app is actually running in.
    static var currentLanguage: String { Bundle.main.preferredLocalizations.first ?? "en" }

    static func phrases(for difficulty: MissionDifficulty, language: String = currentLanguage) -> [String] {
        let vietnamese = language.hasPrefix("vi")
        switch difficulty {
        case .easy: return vietnamese ? easyPhrasesVI : easyPhrases
        case .medium: return vietnamese ? mediumPhrasesVI : mediumPhrases
        case .hard: return vietnamese ? hardPhrasesVI : hardPhrases
        }
    }

    static func randomPhrase(for difficulty: MissionDifficulty) -> String {
        phrases(for: difficulty).randomElement() ?? "Trust yourself."
    }
}
