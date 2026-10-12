import Foundation

/// Exports the survey (questions, activities, aptitudes) and scoring test cases as JSON for the website,
/// so Swift stays the single source of truth.
public enum WebExport {
    /// Where the files go, relative to the repository root.
    public static let surveyPath = "web/data/survey.json"
    public static let fixturesPath = "web/tests/fixtures.json"
    public static let exportFixturesPath = "web/tests/export-fixtures.json"

    struct AptitudeOut: Encodable { let id, name, summary: String }
    struct OptionOut: Encodable { let text: String; let weights: [String: Double] }
    struct QuestionOut: Encodable {
        let id, kind, prompt, instruction: String
        let scaleLabels: [String]
        let weights: [String: Double]
        let reversed: Bool
        let options: [OptionOut]
    }
    struct ActivityOut: Encodable { let name, category: String; let weights: [String: Double] }
    struct Survey: Encodable {
        let aptitudes: [AptitudeOut]
        let categories: [String]
        let questions: [QuestionOut]
        let activities: [ActivityOut]
    }

    struct ScoreOut: Encodable { let aptitude: String; let score: Double; let evidence: [String] }
    struct MatchOut: Encodable { let activity, category: String; let fit: Double; let reasons: [String] }
    struct Fixture: Encodable {
        let name: String
        let answers: [String: Int]
        let answeredCount: Int
        let scores: [ScoreOut]
        let matches: [MatchOut]
    }

    public static func surveyJSON() throws -> Data {
        func w(_ d: [Aptitude: Double]) -> [String: Double] {
            Dictionary(uniqueKeysWithValues: d.map { ($0.key.rawValue, $0.value) })
        }
        let survey = Survey(
            aptitudes: Aptitude.allCases.map { AptitudeOut(id: $0.rawValue, name: $0.name, summary: $0.summary) },
            categories: Activity.Category.allCases.map(\.rawValue),
            questions: QuestionBank.all.map { q in
                QuestionOut(id: q.id, kind: q.kind.rawValue, prompt: q.prompt, instruction: q.instruction,
                            scaleLabels: q.scaleLabels, weights: w(q.weights), reversed: q.reversed,
                            options: q.options.map { OptionOut(text: $0.text, weights: w($0.weights)) })
            },
            activities: ActivityCatalog.all.map { ActivityOut(name: $0.name, category: $0.category.rawValue, weights: w($0.weights)) })
        return try encode(survey)
    }

    public static func fixturesJSON() throws -> Data {
        var sets: [(String, [String: Int])] = Aptitude.allCases.map { ("favor \($0.rawValue)", answers(favoring: $0)) }
        sets.append(("all neutral", Dictionary(uniqueKeysWithValues: QuestionBank.all.map { ($0.id, $0.kind == .choice ? 0 : 3) })))
        sets.append(("first twenty only", Dictionary(uniqueKeysWithValues: QuestionBank.all.prefix(20).enumerated().map { ($0.element.id, $0.offset % 4 + 1) })))
        sets.append(("invalid values ignored", ["an1": 9, "ch1": 7, "ve1": 0, "sp1": 5]))
        sets.append(("empty", [:]))
        var rng = SplitMix64(seed: 2026)
        for i in 1...6 {
            sets.append(("random \(i)", Dictionary(uniqueKeysWithValues: QuestionBank.all.map { q in
                (q.id, q.kind == .choice ? Int(rng.next() % 4) : Int(rng.next() % 5) + 1)
            })))
        }
        let fixtures = sets.map { name, answers -> Fixture in
            let r = Scorer.score(answers: answers)
            return Fixture(name: name, answers: answers, answeredCount: r.answeredCount,
                           scores: r.scores.map { ScoreOut(aptitude: $0.aptitude.rawValue, score: $0.score, evidence: $0.evidence) },
                           matches: r.matches.map { MatchOut(activity: $0.activity, category: $0.category, fit: $0.fit, reasons: $0.reasons.map(\.rawValue)) })
        }
        return try encode(fixtures)
    }

    struct ExportFixture: Encodable {
        let name: String
        let result: ResultOut
        let previous: ResultOut?
        let date: String
        let previousDate: String?
        let activityCount: Int
        let markdown: String
    }
    struct ResultOut: Encodable {
        let answeredCount: Int
        let scores: [ScoreOut]
        let matches: [MatchOut]
    }

    /// Markdown exports for a few cases, so the web version can be checked against the Swift one.
    public static func exportFixturesJSON() throws -> Data {
        func out(_ r: SurveyResult) -> ResultOut {
            ResultOut(answeredCount: r.answeredCount,
                      scores: r.scores.map { ScoreOut(aptitude: $0.aptitude.rawValue, score: $0.score, evidence: $0.evidence) },
                      matches: r.matches.map { MatchOut(activity: $0.activity, category: $0.category, fit: $0.fit, reasons: $0.reasons.map(\.rawValue)) })
        }
        let creative = Scorer.score(answers: answers(favoring: .creative), date: Date(timeIntervalSince1970: 2_000_000))
        let nature = Scorer.score(answers: answers(favoring: .nature), date: Date(timeIntervalSince1970: 1_000_000))
        var rng = SplitMix64(seed: 7)
        let random = Scorer.score(answers: Dictionary(uniqueKeysWithValues: QuestionBank.all.map { q in
            (q.id, q.kind == .choice ? Int(rng.next() % 4) : Int(rng.next() % 5) + 1)
        }), date: Date(timeIntervalSince1970: 3_000_000))
        let cases: [(String, SurveyResult, SurveyResult?, Int)] = [
            ("first result", creative, nil, 10),
            ("with a previous result", creative, nature, 10),
            ("random answers, few activities", random, creative, 5),
            ("all activities", nature, nil, 100),
        ]
        let fixtures = cases.map { name, r, prev, count in
            ExportFixture(name: name, result: out(r), previous: prev.map(out), date: "DATE", previousDate: prev == nil ? nil : "PREVIOUS DATE",
                          activityCount: count,
                          markdown: ResultExport.markdown(r, date: "DATE", previous: prev, previousDate: prev == nil ? nil : "PREVIOUS DATE", activityCount: count))
        }
        return try encode(fixtures)
    }

    /// Answers that max out `target` and minimise everything else.
    static func answers(favoring target: Aptitude) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: QuestionBank.all.map { q in
            switch q.kind {
            case .choice:
                return (q.id, q.options.max { ($0.weights[target] ?? 0) < ($1.weights[target] ?? 0) }!.id)
            default:
                return (q.id, (q.weights[target] != nil) != q.reversed ? 5 : 1)
            }
        })
    }

    private static func encode<T: Encodable>(_ value: T) throws -> Data {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try e.encode(value) + Data("\n".utf8)
    }
}

/// Small deterministic random generator so the random fixtures are the same on every machine.
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
