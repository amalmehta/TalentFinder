import Foundation

/// A single survey item. Scale items are answered 1–5; choice items by picking one option.
public struct Question: Identifiable, Hashable, Sendable {
    public enum Kind: String, Sendable {
        /// "How much do you agree?" — Strongly disagree … Strongly agree.
        case agreement
        /// "How easy is this for you?" — Very hard … Very easy.
        case ability
        /// "Which would you rather?" — pick one option.
        case choice
    }

    public struct Option: Identifiable, Hashable, Sendable {
        public let id: Int
        public let text: String
        public let weights: [Aptitude: Double]
    }

    public let id: String
    public let kind: Kind
    public let prompt: String
    /// For scale items: how strongly each aptitude is measured by this item.
    public let weights: [Aptitude: Double]
    /// For scale items: a high answer means *less* of the trait.
    public let reversed: Bool
    /// For choice items.
    public let options: [Option]

    public static let scaleRange = 1...5

    public var scaleLabels: [String] {
        switch kind {
        case .agreement: ["Strongly disagree", "Disagree", "Not sure", "Agree", "Strongly agree"]
        case .ability: ["Very hard", "Hard", "About average", "Easy", "Very easy"]
        case .choice: []
        }
    }

    public var instruction: String {
        switch kind {
        case .agreement: "How much do you agree?"
        case .ability: "How easy is this for you?"
        case .choice: "Which would you pick?"
        }
    }

    /// Whether `value` is a valid answer to this question.
    public func accepts(_ value: Int) -> Bool {
        kind == .choice ? options.indices.contains(value) : Self.scaleRange.contains(value)
    }

    static func agree(_ id: String, _ prompt: String, _ weights: [Aptitude: Double], reversed: Bool = false) -> Question {
        Question(id: id, kind: .agreement, prompt: prompt, weights: weights, reversed: reversed, options: [])
    }

    static func ability(_ id: String, _ prompt: String, _ weights: [Aptitude: Double]) -> Question {
        Question(id: id, kind: .ability, prompt: prompt, weights: weights, reversed: false, options: [])
    }

    static func choice(_ id: String, _ prompt: String, _ options: [(String, [Aptitude: Double])]) -> Question {
        Question(id: id, kind: .choice, prompt: prompt, weights: [:], reversed: false,
                 options: options.enumerated().map { Option(id: $0.offset, text: $0.element.0, weights: $0.element.1) })
    }
}
