import Foundation

enum TypingValidator {
    /// Lowercased, smart punctuation flattened, whitespace collapsed and trimmed.
    static func normalize(_ text: String) -> String {
        var s = text
            .replacingOccurrences(of: "\u{2018}", with: "'")
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{201C}", with: "\"")
            .replacingOccurrences(of: "\u{201D}", with: "\"")
            .replacingOccurrences(of: "\u{2013}", with: "-")
            .replacingOccurrences(of: "\u{2014}", with: "-")
        s = s.lowercased()
        let parts = s.split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: " ")
    }

    static func isMatch(input: String, target: String) -> Bool {
        normalize(input) == normalize(target)
    }

    /// Number of leading characters of `input` that agree with `target` (after per-character normalization).
    static func correctPrefixLength(input: String, target: String) -> Int {
        let a = Array(normalize(input))
        let b = Array(normalize(target))
        var n = 0
        while n < a.count, n < b.count, a[n] == b[n] { n += 1 }
        return n
    }

    /// True when `new` grew by more than one character compared to `old` (paste / autofill).
    static func isSuspiciousJump(old: String, new: String) -> Bool {
        new.count - old.count > 1
    }
}
