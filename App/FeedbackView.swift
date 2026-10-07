import SwiftUI
import TalentFinderCore

struct FeedbackView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var kind = "Idea"
    @State private var message = ""
    @State private var sent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Send Feedback").font(.title2.bold())
            if sent {
                Label("Thanks! Your feedback has been saved.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                HStack {
                    Button("Show in Finder") { model.revealDataFolder() }
                    Spacer()
                    Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
                }
            } else {
                Picker("Type", selection: $kind) {
                    ForEach(["Idea", "Bug", "Question", "Other"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                TextEditor(text: $message)
                    .font(.body)
                    .frame(height: 140)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
                Text("Saved to Feedback.json on this Mac. Nothing is sent anywhere.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                    Button("Save Feedback") {
                        sent = model.sendFeedback(kind: kind, message: message.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}
