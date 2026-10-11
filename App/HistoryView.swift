import Charts
import SwiftUI
import TalentFinderCore

/// Every past result, a chart of how the scores changed, and ways to open or delete each one.
struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @State private var pendingDelete: SurveyResult?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Past Results").font(.largeTitle.bold())
                    Text(model.history.count == 1 ? "1 result" : "\(model.history.count) results")
                        .foregroundStyle(.secondary)
                }
                if model.history.count > 1 { trend }
                list
            }
            .padding(32)
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
        }
        .confirmationDialog("Delete this result?", isPresented: .constant(pendingDelete != nil), presenting: pendingDelete) { r in
            Button("Delete", role: .destructive) { model.delete(r); pendingDelete = nil }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { r in
            Text("The result from \(r.completedAt.formatted(date: .long, time: .shortened)) will be removed. This can't be undone.")
        }
    }

    /// Starts with the latest result's top three aptitudes; remembered while the app is open.
    private var shown: Set<Aptitude> {
        model.trendAptitudes ?? Set(model.history.last?.topStrengths.map(\.aptitude) ?? [])
    }

    private func toggle(_ a: Aptitude) {
        var s = shown
        if s.contains(a) { s.remove(a) } else { s.insert(a) }
        model.trendAptitudes = s
    }

    private var trend: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How your scores have changed").font(.title2.bold())
            Chart {
                ForEach(Aptitude.allCases.filter(shown.contains)) { a in
                    // Evenly spaced by result number, so retakes taken close together stay readable.
                    ForEach(Array(ResultHistory.series(for: a, in: model.history).enumerated()), id: \.offset) { i, point in
                        LineMark(x: .value("Result", i + 1), y: .value("Score", point.score))
                            .foregroundStyle(by: .value("Aptitude", a.name))
                            .symbol(by: .value("Aptitude", a.name))
                    }
                }
            }
            .chartXScale(domain: 0.8...(Double(model.history.count) + 0.2))
            .chartXAxis {
                AxisMarks(values: Array(1...model.history.count)) { value in
                    AxisGridLine()
                    if let i = value.as(Int.self) {
                        AxisValueLabel("#\(i) · \(model.history[i - 1].completedAt.formatted(.dateTime.month(.abbreviated).day()))")
                    }
                }
            }
            .chartForegroundStyleScale(domain: Aptitude.allCases.map(\.name), range: Aptitude.allCases.map(\.color))
            .chartYScale(domain: 0...100)
            .chartLegend(.hidden)
            .frame(height: 240)
            .accessibilityLabel("Aptitude scores over time")

            Text("Choose which aptitudes to show:").font(.callout).foregroundStyle(.secondary)
            FlowChips(items: Aptitude.allCases) { a in
                Button { toggle(a) } label: {
                    Label(a.name, systemImage: a.symbol)
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(shown.contains(a) ? a.color.opacity(0.3) : Color.secondary.opacity(0.1), in: Capsule())
                        .overlay(Capsule().strokeBorder(shown.contains(a) ? a.color : .clear))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(shown.contains(a) ? .isSelected : [])
            }
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("All results").font(.title2.bold()).padding(.bottom, 8)
            ForEach(model.history.reversed()) { r in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(r.completedAt.formatted(date: .long, time: .shortened)).font(.headline)
                            if r.id == model.history.last?.id {
                                Text("Latest").font(.caption.bold())
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.2), in: Capsule())
                            }
                        }
                        HStack(spacing: 6) {
                            ForEach(r.topStrengths) { s in
                                Label("\(s.aptitude.name) \(Int(s.score.rounded()))", systemImage: s.aptitude.symbol)
                                    .font(.caption)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(s.aptitude.color.opacity(0.15), in: Capsule())
                            }
                        }
                    }
                    Spacer()
                    Button("Open") { model.open(r) }
                    Button { pendingDelete = r } label: { Image(systemName: "trash") }
                        .help("Delete this result")
                        .accessibilityLabel("Delete result from \(r.completedAt.formatted(date: .long, time: .shortened))")
                }
                .padding(.vertical, 10)
                Divider()
            }
        }
    }
}

/// Lays chips out in rows, wrapping as needed.
private struct FlowChips<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        FlowLayout(spacing: 6) { ForEach(items, id: \.self) { content($0) } }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (i, p) in arrange(width: bounds.width, subviews).points.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, _ subviews: Subviews) -> (points: [CGPoint], size: CGSize) {
        var points: [CGPoint] = [], x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (points, CGSize(width: maxX, height: y + rowHeight))
    }
}
