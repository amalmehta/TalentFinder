import Foundation

/// Operations on the list of past results. Histories are kept oldest first.
public enum ResultHistory {
    public static func adding(_ result: SurveyResult, to history: [SurveyResult]) -> [SurveyResult] {
        (history.filter { $0.id != result.id } + [result]).sorted { $0.completedAt < $1.completedAt }
    }

    public static func removing(_ id: SurveyResult.ID, from history: [SurveyResult]) -> [SurveyResult] {
        history.filter { $0.id != id }
    }

    /// One aptitude's score in each result, oldest first, for the trend chart.
    public static func series(for aptitude: Aptitude, in history: [SurveyResult]) -> [(date: Date, score: Double)] {
        history.map { ($0.completedAt, $0.score(for: aptitude)) }
    }

    /// How much each aptitude moved between the two most recent results, or nil with fewer than two.
    public static func latestChange(in history: [SurveyResult]) -> [Aptitude: Double]? {
        guard history.count >= 2 else { return nil }
        let new = history[history.count - 1], old = history[history.count - 2]
        return Dictionary(uniqueKeysWithValues: Aptitude.allCases.map { ($0, new.score(for: $0) - old.score(for: $0)) })
    }
}
