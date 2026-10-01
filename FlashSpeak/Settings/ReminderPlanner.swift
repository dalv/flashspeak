/// Schedules or cancels the daily reminder from the current settings,
/// with a random phrase from the current language as the prompt.
@MainActor
struct ReminderPlanner {
    let dependencies: AppDependencies

    func reschedule() async {
        let settings = dependencies.settings
        guard settings.reminderEnabled else {
            dependencies.reminders.cancel()
            return
        }
        let code = settings.currentLanguageCode
        let phrases = (try? dependencies.phrases.phrases(in: code, section: .all, sort: .newest)) ?? []
        await dependencies.reminders.schedule(
            at: settings.reminderTime,
            languageName: LanguageTheme.forCode(code)?.displayName ?? "",
            prompt: phrases.filter { !$0.hiddenFromReview }.randomElement()?.englishText
        )
    }
}
