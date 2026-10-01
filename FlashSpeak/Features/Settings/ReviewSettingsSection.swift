import SwiftUI

/// Level, new cards per day and flashcard direction.
struct ReviewSettingsSection: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Section {
            Picker(selection: $model.levelOverride) {
                Text("Automatic · \(model.levelLabel(model.automaticLevel))").tag(Int?.none)
                ForEach(SetLevel.range, id: \.self) { level in
                    Text(model.levelLabel(level)).tag(Int?.some(level))
                }
            } label: {
                SettingsRow("Your level") { EmptyView() }
            }

            Stepper(value: $model.dailyNewCards, in: 0 ... 50, step: 5) {
                SettingsRow("New cards per day") {
                    Text("\(model.dailyNewCards)").monospacedDigit()
                }
            }

            Toggle(isOn: $model.reverseFlashcards) {
                SettingsRow("Listening-first flashcards", subtitle: "Hear the \(model.theme.displayName) on the front") { EmptyView() }
            }
        } header: {
            SettingsSectionHeader(title: "Review")
        }
        .dsListRows()
    }
}
