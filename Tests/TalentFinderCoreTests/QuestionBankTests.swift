import XCTest
@testable import TalentFinderCore

final class QuestionBankTests: XCTestCase {
    func testHasSixtyQuestionsWithUniqueIDs() {
        XCTAssertEqual(QuestionBank.all.count, 60)
        XCTAssertEqual(Set(QuestionBank.all.map(\.id)).count, 60)
    }

    func testEveryDimensionHasFivePrimaryScaleItemsAndOneReversed() {
        for d in Aptitude.allCases {
            let primary = QuestionBank.scale.filter { $0.weights[d] == 1 }
            XCTAssertEqual(primary.count, 5, "\(d)")
            XCTAssertEqual(primary.filter(\.reversed).count, 1, "\(d)")
        }
    }

    func testEveryDimensionAppearsInAtLeastThreeChoiceItems() {
        for d in Aptitude.allCases {
            let n = QuestionBank.choices.filter { q in q.options.contains { $0.weights[d] != nil } }.count
            XCTAssertGreaterThanOrEqual(n, 3, "\(d)")
        }
    }

    func testChoiceItemsHaveFourOptionsAndScaleItemsHaveWeights() {
        for q in QuestionBank.all {
            if q.kind == .choice { XCTAssertEqual(q.options.count, 4, q.id) }
            else { XCTAssertFalse(q.weights.isEmpty, q.id); XCTAssertEqual(q.scaleLabels.count, 5) }
        }
    }

    func testEveryDimensionHasActivities() {
        for d in Aptitude.allCases {
            XCTAssertTrue(ActivityCatalog.all.contains { ($0.weights[d] ?? 0) >= 0.8 }, "\(d)")
        }
        XCTAssertEqual(Set(ActivityCatalog.all.map(\.name)).count, ActivityCatalog.all.count)
    }
}
