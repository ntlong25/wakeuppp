import Foundation

struct MathProblem: Sendable, Equatable {
    let expression: String
    /// Always a non-negative integer (the keypad has no minus key).
    let answer: Int
}

struct MathProblemGenerator: Sendable {
    static func requiredCount(for difficulty: MissionDifficulty) -> Int {
        switch difficulty {
        case .easy: return 2
        case .medium: return 3
        case .hard: return 4
        }
    }

    static func generate(for difficulty: MissionDifficulty) -> MathProblem {
        switch difficulty {
        case .easy:
            let a = Int.random(in: 12...79)
            let b = Int.random(in: 11...35)
            if Bool.random() {
                return MathProblem(expression: "\(a) + \(b)", answer: a + b)
            }
            let larger = max(a, b), smaller = min(a, b)
            return MathProblem(expression: "\(larger) - \(smaller)", answer: larger - smaller)

        case .medium:
            switch Int.random(in: 0...2) {
            case 0:
                let a = Int.random(in: 25...89), b = Int.random(in: 19...65)
                return MathProblem(expression: "\(a) + \(b)", answer: a + b)
            case 1:
                let a = Int.random(in: 45...110), b = Int.random(in: 18...44)
                return MathProblem(expression: "\(a) - \(b)", answer: a - b)
            default:
                let a = Int.random(in: 4...12), b = Int.random(in: 6...15)
                return MathProblem(expression: "\(a) × \(b)", answer: a * b)
            }

        case .hard:
            // (a × b) − c, with c strictly below the product so the answer stays positive.
            let a = Int.random(in: 6...14)
            let b = Int.random(in: 4...12)
            let product = a * b
            let c = Int.random(in: 10...min(30, product - 1))
            return MathProblem(expression: "(\(a) × \(b)) - \(c)", answer: product - c)
        }
    }
}
