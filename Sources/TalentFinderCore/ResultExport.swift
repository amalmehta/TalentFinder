import Foundation

/// Turns a result into a Markdown document. Dates are passed in already formatted, so each
/// platform can use the reader's locale while the rest of the text stays identical everywhere
/// (web/js/export.js is a port; web/tests/export.test.mjs checks they match).
public enum ResultExport {
    public static let siteURL = "https://amalmehta.github.io/TalentFinder/"

    /// - Parameters:
    ///   - previous: the result before this one, for the change column; nil if there isn't one.
    ///   - activityCount: how many activity matches to include.
    public static func markdown(_ r: SurveyResult, date: String, previous: SurveyResult?, previousDate: String?,
                                activityCount: Int) -> String {
        var lines = ["# TalentFinder results", "", "Completed \(date) · based on \(r.answeredCount) answers", ""]

        lines += ["## Your aptitudes", ""]
        if let previous, let previousDate {
            lines += ["| Aptitude | Score | Change since \(cell(previousDate)) |", "|---|---:|---:|"]
            for s in r.scores {
                lines.append("| \(cell(s.aptitude.name)) | \(whole(s.score)) | \(change(s.score - previous.score(for: s.aptitude))) |")
            }
        } else {
            lines += ["| Aptitude | Score |", "|---|---:|"]
            for s in r.scores { lines.append("| \(cell(s.aptitude.name)) | \(whole(s.score)) |") }
        }
        lines.append("")

        lines += ["## Your top strengths", ""]
        for (i, s) in r.topStrengths.enumerated() {
            lines += ["### \(i + 1). \(s.aptitude.name) — \(whole(s.score))", "", s.aptitude.summary, ""]
            if !s.evidence.isEmpty { lines += s.evidence.map { "- \($0)" } + [""] }
        }

        lines += ["## Activities that suit you", "", "| Activity | Category | Fit | Why |", "|---|---|---:|---|"]
        for m in r.matches.prefix(activityCount) {
            lines.append("| \(cell(m.activity)) | \(cell(m.category)) | \(whole(m.fit))% | \(cell(m.reasons.map(\.name).joined(separator: ", "))) |")
        }
        lines += ["", "_Fit is a weighted average of the aptitudes each activity draws on. It's a pointer for what to try, not a verdict._",
                  "", "---", "", "Made with [TalentFinder](\(siteURL))", ""]
        return lines.joined(separator: "\n")
    }

    /// A file name people would recognise, e.g. "TalentFinder Results 2026-10-11".
    public static func fileName(for r: SurveyResult, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: r.completedAt)
        return String(format: "TalentFinder Results %04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Rounds half away from zero, the same in Swift and the web version.
    static func whole(_ x: Double) -> Int { Int(x.rounded()) }

    static func change(_ d: Double) -> String {
        let n = whole(d)
        return n > 0 ? "▲\(n)" : n < 0 ? "▼\(-n)" : "–"
    }

    /// Keeps table cells from breaking the table.
    static func cell(_ s: String) -> String { s.replacingOccurrences(of: "|", with: "\\|") }
}
