import XCTest
@testable import TalentFinderCore

final class ScorerTests: XCTestCase {
    /// Answers that max out `target` and min out everything else.
    func answers(favoring target: Aptitude) -> [String: Int] {
        var a: [String: Int] = [:]
        for q in QuestionBank.all {
            switch q.kind {
            case .choice:
                a[q.id] = q.options.max { ($0.weights[target] ?? 0) < ($1.weights[target] ?? 0) }!.id
            default:
                let high = q.weights[target] != nil
                a[q.id] = (high != q.reversed) ? 5 : 1
            }
        }
        return a
    }

    func testFavoredDimensionRanksFirstForEveryDimension() {
        for d in Aptitude.allCases {
            let r = Scorer.score(answers: answers(favoring: d))
            XCTAssertEqual(r.scores.first?.aptitude, d)
            XCTAssertEqual(r.answeredCount, 60)
        }
    }

    func testReverseKeyedItemCountsAgainst() {
        let agreeing = Scorer.score(answers: ["an3": 5]).scores.first { $0.aptitude == .analytical }!
        let disagreeing = Scorer.score(answers: ["an3": 1]).scores.first { $0.aptitude == .analytical }!
        XCTAssertEqual(agreeing.score, 0)
        XCTAssertEqual(disagreeing.score, 100)
    }

    func testNeutralAnswersScoreFifty() {
        let r = Scorer.score(answers: Dictionary(uniqueKeysWithValues: QuestionBank.scale.map { ($0.id, 3) }))
        for s in r.scores { XCTAssertEqual(s.score, 50, accuracy: 0.001) }
    }

    func testScoresStayInRangeAndInvalidAnswersAreIgnored() {
        let r = Scorer.score(answers: ["an1": 9, "ch1": 7, "ve1": 0])
        XCTAssertEqual(r.answeredCount, 0)
        XCTAssertTrue(r.scores.allSatisfy { (0...100).contains($0.score) })
    }

    func testChoiceGivesEvidenceAndFullCredit() {
        let r = Scorer.score(answers: ["ch3": 2]) // "Coding or data analysis"
        let an = r.scores.first { $0.aptitude == .analytical }!
        XCTAssertEqual(an.score, 100)
        XCTAssertTrue(an.evidence.first?.contains("Coding") ?? false)
    }

    func testMatchesFollowStrengths() {
        let r = Scorer.score(answers: answers(favoring: .nature))
        let top = r.matches.prefix(3).map(\.activity)
        XCTAssertTrue(top.contains("Birdwatching") || top.contains("Gardening"), "\(top)")
        XCTAssertEqual(r.matches.first?.reasons.first, .nature)
        XCTAssertEqual(r.matches.count, ActivityCatalog.all.count)
    }
}

final class EvidenceTests: XCTestCase {
    func testQuotedChoiceTextIsNotDoubleQuoted() {
        let r = Scorer.score(answers: ["ch5": 1]) // "“You're a brilliant writer.”"
        let ev = r.scores.first { $0.aptitude == .verbal }!.evidence.first!
        XCTAssertEqual(ev, "You picked \u{201C}You're a brilliant writer.\u{201D}")
    }
}
