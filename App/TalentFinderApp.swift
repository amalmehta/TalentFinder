import SwiftUI
import TalentFinderCore

@main
struct TalentFinderApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        Window("TalentFinder", id: "main") {
            ContentView()
                .environment(model)
                .frame(minWidth: 760, minHeight: 600)
        }
        .defaultSize(width: 900, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Survey") { model.startNew() }
                    .keyboardShortcut("n")
            }
            CommandGroup(after: .help) {
                Button("Send Feedback…") { model.showingFeedback = true }
            }
        }

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}
