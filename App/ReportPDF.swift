import SwiftUI
import TalentFinderCore

/// Builds a paginated A4 PDF of one result. Each section is rendered with SwiftUI and kept whole,
/// so page breaks fall between blocks rather than through them.
@MainActor
enum ReportPDF {
    static let page = CGSize(width: 595, height: 842)
    static let margin: CGFloat = 44
    static let gap: CGFloat = 14
    static var contentWidth: CGFloat { page.width - 2 * margin }

    static func make(_ r: SurveyResult, date: String, previous: SurveyResult?, previousDate: String?, activityCount: Int) -> Data {
        render(blocks: blocks(r, date: date, previous: previous, previousDate: previousDate, activityCount: activityCount),
               footer: "TalentFinder results · \(date)")
    }

    // MARK: Layout

    static func render(blocks: [AnyView], footer: String) -> Data {
        let footerHeight: CGFloat = 20
        let bottom = page.height - margin - footerHeight
        let renderers = blocks.map { block -> (ImageRenderer<AnyView>, CGFloat) in
            let r = ImageRenderer(content: AnyView(block.frame(width: contentWidth, alignment: .leading)
                .environment(\.colorScheme, .light)))
            r.proposedSize = ProposedViewSize(width: contentWidth, height: nil)
            var height: CGFloat = 0
            r.render { size, _ in height = size.height }
            return (r, height)
        }

        // Assign blocks to pages: a block that doesn't fit starts a new page.
        var pages: [[(ImageRenderer<AnyView>, CGFloat, CGFloat)]] = [[]]
        var y = margin
        for (r, h) in renderers {
            if y + h > bottom, !pages[pages.count - 1].isEmpty {
                pages.append([])
                y = margin
            }
            pages[pages.count - 1].append((r, y, h))
            y += h + gap
        }

        let data = NSMutableData()
        var box = CGRect(origin: .zero, size: page)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { return Data() }
        for (i, blocks) in pages.enumerated() {
            ctx.beginPDFPage(nil)
            for (r, top, h) in blocks { draw(r, in: ctx, top: top, height: h) }
            let label = ImageRenderer(content: AnyView(
                HStack { Text(footer); Spacer(); Text("Page \(i + 1) of \(pages.count)") }
                    .font(.system(size: 8)).foregroundStyle(.gray)
                    .frame(width: contentWidth).environment(\.colorScheme, .light)))
            var labelHeight: CGFloat = 0
            label.render { size, _ in labelHeight = size.height }
            draw(label, in: ctx, top: page.height - margin, height: labelHeight)
            ctx.endPDFPage()
        }
        ctx.closePDF()
        return data as Data
    }

    private static func draw(_ r: ImageRenderer<AnyView>, in ctx: CGContext, top: CGFloat, height: CGFloat) {
        ctx.saveGState()
        // PDF space has its origin at the bottom left.
        ctx.translateBy(x: margin, y: page.height - top - height)
        r.render { _, draw in draw(ctx) }
        ctx.restoreGState()
    }

    // MARK: Content

    static func blocks(_ r: SurveyResult, date: String, previous: SurveyResult?, previousDate: String?, activityCount: Int) -> [AnyView] {
        var out: [AnyView] = []
        out.append(AnyView(VStack(alignment: .leading, spacing: 4) {
            Text("TalentFinder results").font(.system(size: 24, weight: .bold))
            Text("Completed \(date) · based on \(r.answeredCount) answers").font(.system(size: 11)).foregroundStyle(.gray)
        }))

        out.append(titled("Your aptitudes", VStack(alignment: .leading, spacing: 6) {
            ForEach(r.scores) { s in
                HStack(spacing: 8) {
                    Text(s.aptitude.name).font(.system(size: 10)).frame(width: 150, alignment: .leading)
                    Capsule().fill(s.aptitude.color)
                        .frame(width: max(2, (contentWidth - 250) * s.score / 100), height: 7)
                    Text("\(Int(s.score.rounded()))").font(.system(size: 10).monospacedDigit())
                    if let previous {
                        let d = Int((s.score - previous.score(for: s.aptitude)).rounded())
                        if d != 0 {
                            Text(d > 0 ? "▲\(d)" : "▼\(-d)").font(.system(size: 9).monospacedDigit())
                                .foregroundStyle(d > 0 ? Color.green : Color.orange)
                        }
                    }
                }
            }
            if let previousDate {
                Text("▲▼ change since your previous result on \(previousDate).").font(.system(size: 9)).foregroundStyle(.gray)
                    .padding(.top, 4)
            }
        }))

        for (i, s) in r.topStrengths.enumerated() {
            let card = HStack(alignment: .top, spacing: 10) {
                Image(systemName: s.aptitude.symbol).font(.system(size: 18)).foregroundStyle(s.aptitude.color).frame(width: 26)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(i + 1). \(s.aptitude.name) — \(Int(s.score.rounded()))").font(.system(size: 12, weight: .semibold))
                    Text(s.aptitude.summary).font(.system(size: 10))
                    ForEach(s.evidence, id: \.self) { e in
                        Text("• \(e)").font(.system(size: 9)).foregroundStyle(.gray)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(s.aptitude.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            out.append(i == 0 ? titled("Your top strengths", card) : AnyView(card))
        }

        for (i, m) in r.matches.prefix(activityCount).enumerated() {
            let row = VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.activity).font(.system(size: 11, weight: .semibold))
                        Text("\(m.category) · \(m.reasons.map(\.name).joined(separator: ", "))")
                            .font(.system(size: 9)).foregroundStyle(.gray)
                    }
                    Spacer()
                    Text("\(Int(m.fit.rounded()))% fit").font(.system(size: 11).monospacedDigit())
                }
                Divider()
            }
            out.append(i == 0 ? titled("Activities that suit you", row) : AnyView(row))
        }
        out.append(AnyView(VStack(alignment: .leading, spacing: 6) {
            Text("Fit is a weighted average of the aptitudes each activity draws on. It's a pointer for what to try, not a verdict.")
            Text("Made with TalentFinder · \(ResultExport.siteURL)")
        }
        .font(.system(size: 9)).foregroundStyle(.gray)))
        return out
    }

    /// A section heading kept on the same page as the block after it.
    private static func titled(_ title: String, _ content: some View) -> AnyView {
        AnyView(VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 15, weight: .bold)).padding(.top, 6)
            content
        })
    }
}
