import SwiftUI
import TalentFinderCore

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Group {
            switch model.screen {
            case .welcome: WelcomeView()
            case .survey: SurveyView()
            case .results: ResultsView()
            case .history: HistoryView()
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if model.screen != .welcome {
                    Button { model.screen = .welcome } label: { Label("Home", systemImage: "house") }
                        .help("Back to the start screen")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if !model.history.isEmpty && model.screen != .history {
                    Button { model.screen = .history } label: { Label("Past Results", systemImage: "clock.arrow.circlepath") }
                        .help("Past results and how your scores have changed")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                SettingsLink { Label("Settings", systemImage: "gearshape") }
                    .help("Settings (⌘,)")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack { Spacer(); FeedbackTab() }
        }
        .sheet(isPresented: $model.showingFeedback) { FeedbackView() }
        .alert("Something went wrong", isPresented: .constant(model.errorMessage != nil)) {
            Button("OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }

    private var title: String {
        switch model.screen {
        case .welcome: "TalentFinder"
        case .survey: "Survey"
        case .results: "Your Results"
        case .history: "Past Results"
        }
    }
}

/// The small, unobtrusive tab in the bottom-right corner that opens the feedback sheet.
struct FeedbackTab: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Button { model.showingFeedback = true } label: {
            Label("Feedback", systemImage: "bubble.left")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(.separator))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .help("Send feedback about TalentFinder")
    }
}
