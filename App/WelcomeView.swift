import SwiftUI
import TalentFinderCore

extension Aptitude {
    var color: Color {
        switch self {
        case .analytical: .blue
        case .verbal: .indigo
        case .spatial: .teal
        case .musical: .pink
        case .physical: .orange
        case .social: .red
        case .leadership: .purple
        case .creative: .yellow
        case .handsOn: .brown
        case .nature: .green
        }
    }
}

struct WelcomeView: View {
    @Environment(AppModel.self) private var model
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 52))
                        .foregroundStyle(.tint)
                    Text("TalentFinder").font(.largeTitle.bold())
                    Text("Find out what you're naturally good at. Answer 60 quick questions about what you enjoy and what comes easily, and see which of ten aptitudes are strongest for you — and the activities that suit them.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 560)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Aptitude.allCases) { a in
                        VStack(spacing: 6) {
                            Image(systemName: a.symbol).font(.title2).foregroundStyle(a.color)
                            Text(a.name).font(.caption).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .padding(8)
                        .background(a.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .frame(maxWidth: 640)

                actions
                Text("About 10–15 minutes. Your answers are saved as you go and never leave this Mac.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(40)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private var actions: some View {
        VStack(spacing: 10) {
            if let p = model.progress {
                Button { model.resume() } label: {
                    Text("Resume Survey (\(p.answers.count) of \(p.order.count) answered)").frame(minWidth: 260)
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .keyboardShortcut(.defaultAction)
                Button("Start Over") { model.startNew() }
            } else {
                Button { model.startNew() } label: { Text("Start Survey").frame(minWidth: 260) }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            }
            if !model.history.isEmpty {
                HStack(spacing: 16) {
                    Button("See My Latest Results") { model.showLatest() }
                    if model.history.count > 1 {
                        Button("Past Results (\(model.history.count))") { model.screen = .history }
                    }
                }
            }
        }
    }
}
