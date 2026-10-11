import XCTest
@testable import TalentFinderCore

/// Fails when the website's JSON is out of date. Fix by running `swift run ExportWebData`.
final class WebExportTests: XCTestCase {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    func testSurveyJSONIsCurrent() throws {
        let committed = try Data(contentsOf: root.appendingPathComponent(WebExport.surveyPath))
        XCTAssertEqual(committed, try WebExport.surveyJSON(), "Run `swift run ExportWebData`")
    }

    func testFixturesJSONIsCurrent() throws {
        let committed = try Data(contentsOf: root.appendingPathComponent(WebExport.fixturesPath))
        XCTAssertEqual(committed, try WebExport.fixturesJSON(), "Run `swift run ExportWebData`")
    }

    func testScoringIsDeterministic() {
        let a = WebExport.answers(favoring: .creative)
        XCTAssertEqual(Scorer.score(answers: a, date: .distantPast), Scorer.score(answers: a, date: .distantPast))
    }
}
