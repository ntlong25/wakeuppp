import Foundation

struct MathProblem {
    let expression: String
    let answer: Int
}

struct MathProblemGenerator {
    static func generate(for difficulty: MissionDifficulty) -> MathProblem {
        switch difficulty {
        case .easy:
            // 2 numbers addition or subtraction within 10..99
            let isAdd = Bool.random()
            let a = Int.random(in: 12...79)
            let b = Int.random(in: 11...35)
            if isAdd {
                return MathProblem(expression: "\(a) + \(b)", answer: a + b)
            } else {
                let larger = max(a, b)
                let smaller = min(a, b)
                return MathProblem(expression: "\(larger) - \(smaller)", answer: larger - smaller)
            }
            
        case .medium:
            // Include multiplication up to 12
            let op = Int.random(in: 0...2)
            if op == 0 {
                let a = Int.random(in: 25...89)
                let b = Int.random(in: 19...65)
                return MathProblem(expression: "\(a) + \(b)", answer: a + b)
            } else if op == 1 {
                let a = Int.random(in: 45...110)
                let b = Int.random(in: 18...44)
                return MathProblem(expression: "\(a) - \(b)", answer: a - b)
            } else {
                let a = Int.random(in: 4...12)
                let b = Int.random(in: 6...15)
                return MathProblem(expression: "\(a) × \(b)", answer: a * b)
            }
            
        case .hard:
            // Multi-step: (A * B) - C or A + B * C
            let a = Int.random(in: 6...14)
            let b = Int.random(in: 4...12)
            let c = Int.random(in: 10...30)
            let product = a * b
            let expression = "(\(a) × \(b)) - \(c)"
            return MathProblem(expression: expression, answer: product - c)
        }
    }
}
