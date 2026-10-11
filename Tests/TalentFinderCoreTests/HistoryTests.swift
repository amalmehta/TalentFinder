import XCTest
@testable import TalentFinderCore

final class HistoryTests: XCTestCase {
    var store: Store!

    override func setUp() {
        store = Store(folder: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    }

    override func tearDown() { try? FileManager.default.removeItem(at: store.folder) }

    func result(_ favoring: Aptitude, at seconds: TimeInterval) -> SurveyResult {
        Scorer.score(answers: WebExport.answers(favoring: favoring), date: Date(timeIntervalSince1970: seconds))
    }

    func testAddingKeepsOldestFirstAndReplacesSameID() {
        let a = result(.nature, at: 1_000), b = result(.musical, at: 2_000)
        var h = ResultHistory.adding(b, to: [])
        h = ResultHistory.adding(a, to: h)
        XCTAssertEqual(h.map(\.id), [a.id, b.id])
        h = ResultHistory.adding(a, to: h)
        XCTAssertEqual(h.count, 2)
    }

    func testRemoving() {
        let a = result(.nature, at: 1_000), b = result(.musical, at: 2_000)
        XCTAssertEqual(ResultHistory.removing(a.id, from: [a, b]), [b])
    }

    func testSeriesAndLatestChange() {
        let a = result(.nature, at: 1_000), b = result(.musical, at: 2_000)
        let s = ResultHistory.series(for: .musical, in: [a, b])
        XCTAssertEqual(s.map(\.score), [a.score(for: .musical), b.score(for: .musical)])
        let change = ResultHistory.latestChange(in: [a, b])!
        XCTAssertGreaterThan(change[.musical]!, 0)
        XCTAssertLessThan(change[.nature]!, 0)
        XCTAssertNil(ResultHistory.latestChange(in: [a]))
    }

    func testHistoryRoundTripAndReset() throws {
        let h = [result(.nature, at: 1_000), result(.musical, at: 2_000)]
        try store.saveHistory(h)
        XCTAssertEqual(store.loadHistory(), h)
        try store.resetSurveyData()
        XCTAssertEqual(store.loadHistory(), [])
    }

    func testOldSingleResultIsMigratedIntoHistory() throws {
        let old = result(.creative, at: 5_000)
        try store.saveResult(old)
        XCTAssertEqual(store.loadHistory(), [old])
        XCTAssertNil(store.loadResult(), "old file is removed after migrating")
        XCTAssertEqual(store.loadHistory(), [old], "still there on the next launch")
    }
}
