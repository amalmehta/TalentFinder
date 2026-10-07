import Foundation

/// A survey that has been started but not finished.
public struct SurveyProgress: Codable, Equatable, Sendable {
    public var order: [String]
    public var answers: [String: Int]
    public var currentIndex: Int
    public var startedAt: Date

    public init(order: [String], answers: [String: Int] = [:], currentIndex: Int = 0, startedAt: Date = Date()) {
        self.order = order
        self.answers = answers
        self.currentIndex = currentIndex
        self.startedAt = startedAt
    }

    /// A fresh survey over every question, optionally in a shuffled order.
    public static func new(shuffled: Bool, using generator: inout some RandomNumberGenerator) -> SurveyProgress {
        let ids = QuestionBank.all.map(\.id)
        return SurveyProgress(order: shuffled ? ids.shuffled(using: &generator) : ids)
    }

    public static func new(shuffled: Bool) -> SurveyProgress {
        var g = SystemRandomNumberGenerator()
        return new(shuffled: shuffled, using: &g)
    }

    public var isComplete: Bool { order.allSatisfy { answers[$0] != nil } }
    public var fractionComplete: Double { order.isEmpty ? 0 : Double(answers.count) / Double(order.count) }
}

public struct Feedback: Codable, Equatable, Sendable {
    public var date: Date
    public var kind: String
    public var message: String

    public init(date: Date = Date(), kind: String, message: String) {
        self.date = date
        self.kind = kind
        self.message = message
    }
}

/// Saves everything as small JSON files in one folder (Application Support/TalentFinder by default).
public struct Store: Sendable {
    public let folder: URL

    public init(folder: URL) { self.folder = folder }

    public static var standard: Store {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return Store(folder: base.appendingPathComponent("TalentFinder", isDirectory: true))
    }

    var progressURL: URL { folder.appendingPathComponent("Survey In Progress.json") }
    var resultURL: URL { folder.appendingPathComponent("Latest Result.json") }
    public var feedbackURL: URL { folder.appendingPathComponent("Feedback.json") }

    public func loadProgress() -> SurveyProgress? { read(progressURL) }
    public func saveProgress(_ p: SurveyProgress?) throws { try write(p, to: progressURL) }

    public func loadResult() -> SurveyResult? { read(resultURL) }
    public func saveResult(_ r: SurveyResult?) throws { try write(r, to: resultURL) }

    public func loadFeedback() -> [Feedback] { read(feedbackURL) ?? [] }
    public func addFeedback(_ f: Feedback) throws { try write(loadFeedback() + [f], to: feedbackURL) }

    /// Deletes saved progress and results. Feedback is kept.
    public func resetSurveyData() throws {
        try saveProgress(nil)
        try saveResult(nil)
    }

    private func read<T: Decodable>(_ url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }

    private func write<T: Encodable>(_ value: T?, to url: URL) throws {
        guard let value else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: url, options: .atomic)
    }
}
