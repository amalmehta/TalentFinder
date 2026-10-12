import Charts
import SwiftUI
import TalentFinderCore

struct ResultsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage(Pref.topCount) private var topCount = 10
    @State private var category = "All"

    var body: some View {
        if let r = model.result {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if !model.isViewingLatest { olderResultBanner(r) }
                    header(r)
                    chart(r)
                    if model.isViewingLatest, model.history.count > 1 {
                        Text("▲▼ show the change since your previous result on \(model.history[model.history.count - 2].completedAt.formatted(date: .abbreviated, time: .omitted)).")
                            .font(.footnote).foregroundStyle(.secondary)
                            .padding(.top, -16)
                    }
                    strengths(r)
                    activities(r)
                }
                .padding(32)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
        } else {
            ContentUnavailableView("No results yet", systemImage: "chart.bar",
                                   description: Text("Finish the survey to see your aptitudes."))
        }
    }

    private func header(_ r: SurveyResult) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your natural aptitudes").font(.largeTitle.bold())
                Text("Based on \(r.answeredCount) answers · \(r.completedAt.formatted(date: .long, time: .shortened))")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if model.history.count > 1 {
                Button("Past Results") { model.screen = .history }
            }
            Menu("Export") {
                Button("PDF…") { model.export(.pdf) }
                Button("Markdown…") { model.export(.markdown) }
            }
            .fixedSize()
            .help("Save this result as a PDF or Markdown file (⌘E, ⇧⌘E)")
            Button("Retake Survey") { model.startNew() }
        }
    }

    private func olderResultBanner(_ r: SurveyResult) -> some View {
        HStack {
            Label("You're looking at a past result from \(r.completedAt.formatted(date: .long, time: .shortened)).",
                  systemImage: "clock.arrow.circlepath")
            Spacer()
            Button("Back to Past Results") { model.screen = .history }
            Button("See Latest") { model.showLatest() }
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    /// Change since the previous result, shown only on the latest result.
    private func change(for a: Aptitude) -> Double? {
        guard model.isViewingLatest else { return nil }
        return ResultHistory.latestChange(in: model.history)?[a]
    }

    private func chart(_ r: SurveyResult) -> some View {
        Chart(r.scores) { s in
            BarMark(x: .value("Score", s.score), y: .value("Aptitude", s.aptitude.name))
                .foregroundStyle(s.aptitude.color.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    HStack(spacing: 4) {
                        Text("\(Int(s.score.rounded()))").foregroundStyle(.secondary)
                        if let d = change(for: s.aptitude), Int(d.rounded()) != 0 {
                            Text(d > 0 ? "▲\(Int(d.rounded()))" : "▼\(Int(-d.rounded()))")
                                .foregroundStyle(d > 0 ? .green : .orange)
                                .help("Change since your previous result")
                        }
                    }
                    .font(.caption.monospacedDigit())
                }
        }
        .chartXScale(domain: 0...100)
        .chartXAxis { AxisMarks(values: [0, 25, 50, 75, 100]) }
        .frame(height: 320)
        .accessibilityLabel("Aptitude scores from 0 to 100")
    }

    private func strengths(_ r: SurveyResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your top strengths").font(.title2.bold())
            ForEach(Array(r.topStrengths.enumerated()), id: \.element.id) { i, s in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: s.aptitude.symbol)
                        .font(.title).foregroundStyle(s.aptitude.color).frame(width: 40)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(i + 1). \(s.aptitude.name) — \(Int(s.score.rounded()))").font(.headline)
                        Text(s.aptitude.summary)
                        if !s.evidence.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(s.evidence, id: \.self) { e in
                                    Text("• \(e)").font(.callout).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(s.aptitude.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func activities(_ r: SurveyResult) -> some View {
        let filtered = r.matches.filter { category == "All" || $0.category == category }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activities that suit you").font(.title2.bold())
                Spacer()
                Picker("Category", selection: $category) {
                    Text("All").tag("All")
                    ForEach(Activity.Category.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
                }
                .labelsHidden().fixedSize()
            }
            ForEach(filtered.prefix(topCount)) { m in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(m.activity).font(.headline)
                        HStack(spacing: 6) {
                            Text(m.category).font(.caption).foregroundStyle(.secondary)
                            ForEach(m.reasons) { a in
                                Label(a.name, systemImage: a.symbol)
                                    .font(.caption)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(a.color.opacity(0.15), in: Capsule())
                            }
                        }
                    }
                    Spacer()
                    Gauge(value: m.fit, in: 0...100) { EmptyView() } currentValueLabel: {
                        Text("\(Int(m.fit.rounded()))%").font(.callout.monospacedDigit())
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(m.reasons.first?.color ?? .accentColor)
                }
                .padding(.vertical, 6)
                Divider()
            }
            Text("Fit is a weighted average of the aptitudes each activity draws on. It's a pointer for what to try, not a verdict.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}
