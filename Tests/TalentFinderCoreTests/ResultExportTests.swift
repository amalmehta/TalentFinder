import XCTest
@testable import TalentFinderCore

final class ResultExportTests: XCTestCase {
    let creative = Scorer.score(answers: WebExport.answers(favoring: .creative), date: Date(timeIntervalSince1970: 2_000_000))
    let nature = Scorer.score(answers: WebExport.answers(favoring: .nature), date: Date(timeIntervalSince1970: 1_000_000))

    func testFirstResultHasNoChangeColumn() {
        let md = ResultExport.markdown(creative, date: "11 Oct", previous: nil, previousDate: nil, activityCount: 10)
        XCTAssertTrue(md.hasPrefix("# TalentFinder results\n\nCompleted 11 Oct · based on 60 answers\n"))
        XCTAssertTrue(md.contains("| Aptitude | Score |\n|---|---:|\n| Creative & Imaginative | 100 |"))
        XCTAssertFalse(md.contains("Change since"))
        XCTAssertTrue(md.contains("### 1. Creative & Imaginative — 100"))
        XCTAssertTrue(md.contains(Aptitude.creative.summary))
        XCTAssertEqual(md.components(separatedBy: "\n").filter { $0.hasPrefix("| ") && $0.hasSuffix("% | ") == false && $0.contains("% |") }.count, 10)
    }

    func testChangeColumnAgainstPreviousResult() {
        let md = ResultExport.markdown(creative, date: "11 Oct", previous: nature, previousDate: "1 Oct", activityCount: 3)
        XCTAssertTrue(md.contains("| Aptitude | Score | Change since 1 Oct |"))
        let natureRow = md.components(separatedBy: "\n").first { $0.hasPrefix("| Nature & Living Things |") }!
        XCTAssertTrue(natureRow.hasSuffix("▼\(Int((nature.score(for: .nature) - creative.score(for: .nature)).rounded())) |"), natureRow)
        XCTAssertEqual(md.components(separatedBy: "\n").filter { $0.contains("% |") }.count, 3)
    }

    func testChangeFormattingAndCells() {
        XCTAssertEqual(ResultExport.change(2.5), "▲3")
        XCTAssertEqual(ResultExport.change(-2.5), "▼3")
        XCTAssertEqual(ResultExport.change(0.4), "–")
        XCTAssertEqual(ResultExport.cell("a|b"), "a\\|b")
    }

    func testPreviousAndFileName() {
        XCTAssertEqual(ResultHistory.previous(to: creative, in: [nature, creative]), nature)
        XCTAssertNil(ResultHistory.previous(to: nature, in: [nature, creative]))
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(ResultExport.fileName(for: creative, calendar: utc), "TalentFinder Results 1970-01-24")
    }
}
