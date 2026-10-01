@testable import FlashSpeak
import Foundation
import Testing

@MainActor
struct UsageAndSettingsTests {
    private func freshDefaults() -> UserDefaults {
        let name = "tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func freeUsersGetThreeTranslationsADayThatResetAtMidnight() {
        let defaults = freshDefaults()
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        let usage = LocalUsageService(defaults: defaults, calendar: Calendar(identifier: .gregorian), now: { now }) { false }

        #expect(usage.translationsRemainingToday == 3)
        usage.recordTranslation()
        usage.recordTranslation()
        usage.recordTranslation()
        #expect(usage.translationsRemainingToday == 0)

        now = now.addingTimeInterval(86400)
        #expect(usage.translationsRemainingToday == 3)
    }

    @Test func clarificationsAreCountedPerPhrase() {
        let usage = LocalUsageService(defaults: freshDefaults()) { false }
        usage.recordClarification(forPhrase: "a")
        usage.recordClarification(forPhrase: "a")
        #expect(usage.clarificationsRemaining(forPhrase: "a") == 1)
        #expect(usage.clarificationsRemaining(forPhrase: "b") == 3)
        #expect(usage.translationsRemainingToday == 3)
    }

    @Test func proIsUnlimited() {
        let usage = LocalUsageService(defaults: freshDefaults()) { true }
        #expect(usage.translationsRemainingToday == nil)
        #expect(usage.clarificationsRemaining(forPhrase: "a") == nil)
    }

    @Test func legacyKeysCarryOver() {
        let defaults = freshDefaults()
        defaults.set("ja", forKey: "currentLanguageCode")
        defaults.set(false, forKey: "autoPlayAudio")
        defaults.set("formal", forKey: "formality")

        let settings = UserDefaultsSettingsStore(defaults: defaults)
        #expect(settings.currentLanguageCode == "ja")
        #expect(settings.autoPlay == false)
        #expect(settings.settings(for: "ko").register == .polite)
    }

    @Test func unsupportedLegacyLanguageFallsBackToMandarin() {
        let defaults = freshDefaults()
        defaults.set("es", forKey: "currentLanguageCode")
        #expect(UserDefaultsSettingsStore(defaults: defaults).currentLanguageCode == "zh-CN")
    }

    @Test func perLanguageSettingsPersist() {
        let defaults = freshDefaults()
        let store = UserDefaultsSettingsStore(defaults: defaults)
        store.update(LanguageSettings(register: .neutral, levelOverride: 3, dailyNewCardLimit: 15), for: "id")

        let reloaded = UserDefaultsSettingsStore(defaults: defaults)
        #expect(reloaded.settings(for: "id") == LanguageSettings(register: .neutral, levelOverride: 3, dailyNewCardLimit: 15))
        #expect(reloaded.settings(for: "zh-CN") == LanguageSettings())
    }

    @Test func wordByWordSplitsScriptsWithoutSpaces() {
        let text = "你能再说一遍吗？"
        let words = AppleSpeechSynthesizer.words(in: text, languageCode: "zh-CN").map { String(text[$0]) }
        #expect(words.count >= 3)
        #expect(words.joined() == "你能再说一遍吗")
    }
}
