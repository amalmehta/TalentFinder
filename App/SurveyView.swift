import SwiftUI
import TalentFinderCore

struct SurveyView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let p = model.progress, let q = model.currentQuestion {
            VStack(spacing: 0) {
                header(p)
                Spacer(minLength: 20)
                QuestionCard(question: q, selected: model.currentAnswer) { model.answer($0) }
                    .id(q.id)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .opacity))
                Spacer(minLength: 20)
                footer(p)
            }
            .padding(32)
        } else {
            ContentUnavailableView("No survey in progress", systemImage: "list.bullet.clipboard",
                                   description: Text("Start a new survey from the home screen."))
        }
    }

    private func header(_ p: SurveyProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Question \(p.currentIndex + 1) of \(p.order.count)").font(.headline)
                Spacer()
                Text("\(p.answers.count) answered").foregroundStyle(.secondary)
            }
            ProgressView(value: p.fractionComplete)
        }
    }

    private func footer(_ p: SurveyProgress) -> some View {
        HStack {
            Button { model.move(by: -1) } label: { Label("Back", systemImage: "chevron.left") }
                .keyboardShortcut(.leftArrow, modifiers: [])
                .disabled(p.currentIndex == 0)
            Spacer()
            if p.isComplete {
                Button { model.finish() } label: { Label("See My Results", systemImage: "chart.bar.fill") }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            } else if p.currentIndex == p.order.count - 1 {
                Button("Go to First Unanswered") { model.goToFirstUnanswered() }
            }
            Spacer()
            Button { model.move(by: 1) } label: { Label("Next", systemImage: "chevron.right").labelStyle(TrailingIcon()) }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .disabled(p.currentIndex >= p.order.count - 1)
        }
    }
}

private struct TrailingIcon: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) { configuration.title; configuration.icon }
    }
}

struct QuestionCard: View {
    let question: Question
    let selected: Int?
    let onAnswer: (Int) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(question.instruction.uppercased())
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(1)
            Text(question.prompt)
                .font(.title.weight(.medium))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 620)
                .fixedSize(horizontal: false, vertical: true)
            if question.kind == .choice { choices } else { scale }
            Text("Tip: press \(question.kind == .choice ? "1–4" : "1–5") to answer, ← → to move.")
                .font(.footnote).foregroundStyle(.tertiary)
        }
    }

    private var scale: some View {
        HStack(spacing: 10) {
            ForEach(Array(question.scaleLabels.enumerated()), id: \.offset) { i, label in
                let value = i + 1
                AnswerButton(number: value, text: label, isSelected: selected == value) { onAnswer(value) }
            }
        }
        .frame(maxWidth: 680)
    }

    private var choices: some View {
        VStack(spacing: 10) {
            ForEach(question.options) { o in
                AnswerButton(number: o.id + 1, text: o.text, isSelected: selected == o.id, wide: true) { onAnswer(o.id) }
            }
        }
        .frame(maxWidth: 520)
    }
}

private struct AnswerButton: View {
    let number: Int
    let text: String
    let isSelected: Bool
    var wide = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if wide {
                    HStack(spacing: 12) {
                        Text("\(number)").font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                        Text(text).multilineTextAlignment(.leading)
                        Spacer()
                        if isSelected { Image(systemName: "checkmark.circle.fill") }
                    }
                } else {
                    VStack(spacing: 6) {
                        Text("\(number)").font(.title3.monospacedDigit().weight(.semibold))
                        Text(text).font(.callout).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: wide ? 0 : 84)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(Character("\(number)")), modifiers: [])
    }
}
