import XCTest
@testable import TalentFinderCore

final class StoreTests: XCTestCase {
    var store: Store!

    override func setUp() {
        store = Store(folder: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    }

    override func tearDown() { try? FileManager.default.removeItem(at: store.folder) }

    func testProgressRoundTripAndReset() throws {
        var p = SurveyProgress.new(shuffled: true)
        p.answers = ["an1": 4]
        p.currentIndex = 1
        try store.saveProgress(p)
        XCTAssertEqual(store.loadProgress()?.answers, p.answers)
        XCTAssertEqual(store.loadProgress()?.order, p.order)
        try store.resetSurveyData()
        XCTAssertNil(store.loadProgress())
    }

    func testResultRoundTrip() throws {
        let r = Scorer.score(answers: ["an1": 5, "ch1": 0], date: Date(timeIntervalSince1970: 1_000_000))
        try store.saveResult(r)
        XCTAssertEqual(store.loadResult(), r)
    }

    func testFeedbackAppendsAndSurvivesReset() throws {
        try store.addFeedback(Feedback(kind: "Idea", message: "one"))
        try store.addFeedback(Feedback(kind: "Bug", message: "two"))
        try store.resetSurveyData()
        XCTAssertEqual(store.loadFeedback().map(\.message), ["one", "two"])
    }

    func testShuffledOrderStillCoversEveryQuestion() {
        let p = SurveyProgress.new(shuffled: true)
        XCTAssertEqual(Set(p.order), Set(QuestionBank.all.map(\.id)))
        XCTAssertFalse(p.isComplete)
    }
}
