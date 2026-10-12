import SwiftUI
import TalentFinderCore
import UniformTypeIdentifiers

/// Keys for the preferences shown in Settings.
enum Pref {
    static let shuffle = "shuffleQuestions"
    static let autoAdvance = "autoAdvance"
    static let topCount = "topActivitiesCount"
}

@Observable @MainActor
final class AppModel {
    enum Screen { case welcome, survey, results, history }

    let store: Store
    var screen: Screen = .welcome
    var progress: SurveyProgress?
    /// Every completed result, oldest first.
    var history: [SurveyResult] = []
    /// The past result being shown on the results screen; nil means the latest.
    var viewingID: SurveyResult.ID?
    /// Aptitudes drawn on the Past Results trend chart; nil until first shown.
    var trendAptitudes: Set<Aptitude>?
    var showingFeedback = false
    var errorMessage: String?

    init(store: Store = .standard) {
        self.store = store
        UserDefaults.standard.register(defaults: [Pref.shuffle: true, Pref.autoAdvance: true, Pref.topCount: 10])
        progress = store.loadProgress()
        history = store.loadHistory()
    }

    /// The result the results screen shows.
    var result: SurveyResult? {
        viewingID.flatMap { id in history.first { $0.id == id } } ?? history.last
    }

    var isViewingLatest: Bool { result?.id == history.last?.id }

    // MARK: Survey

    var currentQuestion: Question? {
        guard let p = progress, p.order.indices.contains(p.currentIndex) else { return nil }
        return QuestionBank.question(id: p.order[p.currentIndex])
    }

    var currentAnswer: Int? {
        guard let p = progress, let q = currentQuestion else { return nil }
        return p.answers[q.id]
    }

    func startNew() {
        progress = .new(shuffled: UserDefaults.standard.bool(forKey: Pref.shuffle))
        save()
        screen = .survey
    }

    func resume() { screen = .survey }

    func answer(_ value: Int) {
        guard var p = progress, let q = currentQuestion, q.accepts(value) else { return }
        p.answers[q.id] = value
        progress = p
        if UserDefaults.standard.bool(forKey: Pref.autoAdvance), p.currentIndex < p.order.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) { progress?.currentIndex += 1 }
        }
        save()
    }

    func move(by delta: Int) {
        guard let p = progress else { return }
        let i = p.currentIndex + delta
        guard p.order.indices.contains(i) else { return }
        withAnimation(.easeInOut(duration: 0.2)) { progress?.currentIndex = i }
        save()
    }

    /// Jumps to the first question still unanswered.
    func goToFirstUnanswered() {
        guard let p = progress, let i = p.order.firstIndex(where: { p.answers[$0] == nil }) else { return }
        progress?.currentIndex = i
        save()
    }

    func finish() {
        guard let p = progress, p.isComplete else { return }
        history = ResultHistory.adding(Scorer.score(answers: p.answers), to: history)
        viewingID = nil
        progress = nil
        do {
            try store.saveHistory(history)
            try store.saveProgress(nil)
        } catch { errorMessage = error.localizedDescription }
        screen = .results
    }

    // MARK: History

    func showLatest() {
        viewingID = nil
        screen = .results
    }

    func open(_ r: SurveyResult) {
        viewingID = r.id
        screen = .results
    }

    func delete(_ r: SurveyResult) {
        history = ResultHistory.removing(r.id, from: history)
        if viewingID == r.id { viewingID = nil }
        do { try store.saveHistory(history) } catch { errorMessage = error.localizedDescription }
        if history.isEmpty { screen = .welcome }
    }

    func resetAll() {
        do { try store.resetSurveyData() } catch { errorMessage = error.localizedDescription }
        progress = nil
        history = []
        viewingID = nil
        screen = .welcome
    }

    // MARK: Export

    enum ExportFormat { case pdf, markdown }

    /// Saves the result on screen as a PDF or Markdown file, asking where with a save panel.
    func export(_ format: ExportFormat) {
        guard let r = result else { return }
        let previous = ResultHistory.previous(to: r, in: history)
        let date = r.completedAt.formatted(date: .long, time: .shortened)
        let previousDate = previous?.completedAt.formatted(date: .long, time: .shortened)
        let count = UserDefaults.standard.integer(forKey: Pref.topCount)

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        switch format {
        case .pdf:
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = ResultExport.fileName(for: r) + ".pdf"
        case .markdown:
            panel.allowedContentTypes = [UTType("net.daringfireball.markdown") ?? .plainText]
            panel.nameFieldStringValue = ResultExport.fileName(for: r) + ".md"
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let data: Data = switch format {
        case .pdf: ReportPDF.make(r, date: date, previous: previous, previousDate: previousDate, activityCount: count)
        case .markdown: Data(ResultExport.markdown(r, date: date, previous: previous, previousDate: previousDate,
                                                   activityCount: count).utf8)
        }
        do { try data.write(to: url, options: .atomic) } catch { errorMessage = error.localizedDescription }
    }

    var canExport: Bool { screen == .results && result != nil }

    func sendFeedback(kind: String, message: String) -> Bool {
        do {
            try store.addFeedback(Feedback(kind: kind, message: message))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func revealDataFolder() {
        try? FileManager.default.createDirectory(at: store.folder, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([store.folder])
    }

    private func save() {
        do { try store.saveProgress(progress) } catch { errorMessage = error.localizedDescription }
    }
}
