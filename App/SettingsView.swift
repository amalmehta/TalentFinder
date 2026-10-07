import SwiftUI
import TalentFinderCore

/// All preferences in one place. Opens with ⌘, or the gear button in the toolbar.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage(Pref.shuffle) private var shuffle = true
    @AppStorage(Pref.autoAdvance) private var autoAdvance = true
    @AppStorage(Pref.topCount) private var topCount = 10
    @State private var confirmingReset = false

    var body: some View {
        Form {
            Section("Survey") {
                Toggle("Shuffle question order", isOn: $shuffle)
                Text("Applies the next time you start a survey.").font(.caption).foregroundStyle(.secondary)
                Toggle("Move to the next question after answering", isOn: $autoAdvance)
            }
            Section("Results") {
                Picker("Activities to show", selection: $topCount) {
                    ForEach([5, 10, 15, 25], id: \.self) { Text("\($0)").tag($0) }
                }
            }
            Section("Your data") {
                LabeledContent("Saved in") {
                    Button("Show in Finder") { model.revealDataFolder() }
                }
                LabeledContent("Survey answers and results") {
                    Button("Reset…", role: .destructive) { confirmingReset = true }
                }
            }
            Section("Feedback") {
                LabeledContent("Ideas, bugs, questions") {
                    Button("Send Feedback…") { model.showingFeedback = true }
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .confirmationDialog("Delete your saved answers and results?", isPresented: $confirmingReset) {
            Button("Delete", role: .destructive) { model.resetAll() }
        } message: {
            Text("This can't be undone. Feedback you've written is kept.")
        }
    }
}
