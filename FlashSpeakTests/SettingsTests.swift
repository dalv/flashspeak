@testable import FlashSpeak
import Foundation
import SwiftData
import Testing

@MainActor
struct SettingsTests {
    let dependencies = AppDependencies.test()

    private var reminders: FakeReminderScheduler {
        dependencies.reminders as! FakeReminderScheduler
    }

    @Test func csvQuotesCommasQuotesAndNewlines() {
        #expect(CSVExporter.escape("Turn left") == "Turn left")
        #expect(CSVExporter.escape("Yes, please") == "\"Yes, please\"")
        #expect(CSVExporter.escape("Say \"hi\"") == "\"Say \"\"hi\"\"\"")
        #expect(CSVExporter.escape("one\ntwo") == "\"one\ntwo\"")
    }

    @Test func csvHasAHeaderAndOneRowPerPhraseWithNativeScript() {
        let phrase = Phrase(englishText: "How much, roughly?", targetText: "大概多少钱?", pronunciation: "Dàgài duōshao qián?", languageCode: "zh-CN")
        phrase.level = 2
        phrase.createdAt = Date(timeIntervalSince1970: 1_800_000_000)
        let csv = CSVExporter.csv(for: [phrase])
        let lines = csv.components(separatedBy: "\r\n").filter { !$0.isEmpty }

        #expect(lines.count == 2)
        #expect(lines[0] == CSVExporter.header.joined(separator: ","))
        #expect(lines[1].hasPrefix("Mandarin,\"How much, roughly?\",大概多少钱?,Dàgài duōshao qián?,,HSK 2,User phrases,2027-01-15"))
        // Spreadsheet apps need the byte order mark to read UTF-8.
        #expect(CSVExporter.data(for: [phrase]).starts(with: [0xEF, 0xBB, 0xBF]))
    }

    @Test func turningTheReminderOnSchedulesItWithAPhrase() async throws {
        dependencies.settings.currentLanguageCode = "ko"
        try dependencies.phrases.insert(Phrase(englishText: "An iced Americano, please", targetText: "아이스 아메리카노 주세요", languageCode: "ko"))
        let model = SettingsModel(dependencies: dependencies)

        await model.setReminderEnabled(true)
        #expect(model.reminderEnabled)
        #expect(reminders.scheduled?.time == .default)
        #expect(reminders.scheduled?.languageName == "Korean")
        #expect(reminders.scheduled?.prompt == "An iced Americano, please")

        await model.setReminderEnabled(false)
        #expect(reminders.scheduled == nil)
    }

    @Test func aDeniedPermissionLeavesTheReminderOff() async {
        reminders.allowsNotifications = false
        let model = SettingsModel(dependencies: dependencies)
        await model.setReminderEnabled(true)
        #expect(!model.reminderEnabled)
        #expect(model.reminderDenied)
        #expect(reminders.scheduled == nil)
    }

    @Test func perLanguageSettingsStaySeparate() {
        let model = SettingsModel(dependencies: dependencies)
        model.languageCode = "ja"
        model.register = .polite
        model.dailyNewCards = 15
        model.levelOverride = 3

        model.languageCode = "id"
        #expect(model.register == .casual)
        #expect(model.dailyNewCards == 10)
        #expect(model.levelOverride == nil)

        model.languageCode = "ja"
        #expect(model.register == .polite)
        #expect(model.levelLabel(3) == "JLPT N3")
    }

    @Test func deleteAllDataRemovesEveryLanguage() throws {
        for code in Language.supportedCodes {
            try dependencies.phrases.insert(Phrase(englishText: "hello \(code)", targetText: "x", languageCode: code))
        }
        let model = SettingsModel(dependencies: dependencies)
        #expect(model.allPhrases().count == 4)
        model.deleteAllData()
        #expect(model.allPhrases().isEmpty)
    }

    #if DEBUG
        @Test func debugFreeSwitchChangesTheLimit() {
            let model = SettingsModel(dependencies: dependencies)
            model.debugForceFree = false
            #expect(model.isPro)
            #expect(model.translationsRemaining == nil)
            model.debugForceFree = true
            #expect(model.translationsRemaining == 3)
        }
    #endif
}
