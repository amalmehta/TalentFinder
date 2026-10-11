import Foundation

public struct AptitudeScore: Codable, Hashable, Identifiable, Sendable {
    public let aptitude: Aptitude
    /// 0–100. How strongly the answers point to this aptitude.
    public let score: Double
    /// Prompts of the answers that pushed this score up the most.
    public let evidence: [String]
    public var id: Aptitude { aptitude }
}

public struct ActivityMatch: Codable, Hashable, Identifiable, Sendable {
    public let activity: String
    public let category: String
    /// 0–100. Weighted average of the scores of the aptitudes the activity draws on.
    public let fit: Double
    /// The aptitudes contributing most to this fit, strongest first.
    public let reasons: [Aptitude]
    public var id: String { activity }
}

public struct SurveyResult: Codable, Hashable, Sendable {
    public let completedAt: Date
    public let answeredCount: Int
    /// Strongest first.
    public let scores: [AptitudeScore]
    /// Best fit first.
    public let matches: [ActivityMatch]

    public var topStrengths: [AptitudeScore] { Array(scores.prefix(3)) }
}

/// Turns answers into aptitude scores and activity matches. Pure and deterministic.
public enum Scorer {
    /// - Parameter answers: question id → answer (1–5 for scale items, option index for choice items).
    public static func score(answers: [String: Int],
                             questions: [Question] = QuestionBank.all,
                             activities: [Activity] = ActivityCatalog.all,
                             date: Date = Date()) -> SurveyResult {
        var earned: [Aptitude: Double] = [:]
        var possible: [Aptitude: Double] = [:]
        var evidence: [Aptitude: [(String, Double)]] = [:]
        var answered = 0

        for q in questions {
            guard let value = answers[q.id], q.accepts(value) else { continue }
            answered += 1
            switch q.kind {
            case .agreement, .ability:
                var level = Double(value - 1) / 4
                if q.reversed { level = 1 - level }
                for d in Aptitude.allCases {
                    guard let w = q.weights[d] else { continue }
                    earned[d, default: 0] += w * level
                    possible[d, default: 0] += w
                    if level > 0.5 { evidence[d, default: []].append((evidenceText(q, value), w * level)) }
                }
            case .choice:
                let chosen = q.options[value]
                for d in Aptitude.allCases where q.options.contains(where: { $0.weights[d] != nil }) {
                    possible[d, default: 0] += q.options.map { $0.weights[d] ?? 0 }.max() ?? 0
                    if let w = chosen.weights[d] {
                        earned[d, default: 0] += w
                        evidence[d, default: []].append(("You picked \(quoted(chosen.text))", w))
                    }
                }
            }
        }

        let scores = Aptitude.allCases.map { d -> AptitudeScore in
            let p = possible[d] ?? 0
            let s = p > 0 ? (earned[d] ?? 0) / p * 100 : 0
            // Strongest first; ties keep question order.
            let ev = (evidence[d] ?? []).enumerated()
                .sorted { $0.element.1 != $1.element.1 ? $0.element.1 > $1.element.1 : $0.offset < $1.offset }
                .prefix(3).map(\.element.0)
            return AptitudeScore(aptitude: d, score: s, evidence: Array(ev))
        }
        .sorted { $0.score != $1.score ? $0.score > $1.score : $0.aptitude.name < $1.aptitude.name }

        return SurveyResult(completedAt: date, answeredCount: answered, scores: scores,
                            matches: match(scores: scores, activities: activities))
    }

    static func match(scores: [AptitudeScore], activities: [Activity]) -> [ActivityMatch] {
        let byDim = Dictionary(uniqueKeysWithValues: scores.map { ($0.aptitude, $0.score) })
        return activities.map { a in
            // Walk aptitudes in a fixed order so sums and ties are identical on every run (and in the web version).
            let weighted = Aptitude.allCases.compactMap { d in a.weights[d].map { (d, $0) } }
            let total = weighted.map(\.1).reduce(0, +)
            let parts = weighted.map { ($0.0, $0.1 * (byDim[$0.0] ?? 0)) }
            let fit = total > 0 ? parts.map(\.1).reduce(0, +) / total : 0
            let reasons = parts.enumerated()
                .sorted { $0.element.1 != $1.element.1 ? $0.element.1 > $1.element.1 : $0.offset < $1.offset }
                .prefix(2).map(\.element.0)
            return ActivityMatch(activity: a.name, category: a.category.rawValue, fit: fit, reasons: reasons)
        }
        .sorted { $0.fit != $1.fit ? $0.fit > $1.fit : $0.activity < $1.activity }
    }

    /// Wraps text in curly quotes unless it already starts with one.
    static func quoted(_ text: String) -> String {
        text.hasPrefix("\u{201C}") ? text : "\u{201C}\(text)\u{201D}"
    }

    private static func evidenceText(_ q: Question, _ value: Int) -> String {
        let label = q.scaleLabels[value - 1].lowercased()
        switch q.kind {
        case .ability: return "\(q.prompt) — \(label)"
        default: return q.reversed ? "You disagreed: \(quoted(q.prompt))" : "You \(label == "strongly agree" ? "strongly agreed" : "agreed"): \(quoted(q.prompt))"
        }
    }
}
