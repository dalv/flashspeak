import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @AppStorage("autoPlayAudio") var autoPlayAudio: Bool = true
    @AppStorage("formality") var formality: String = "informal"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
    @AppStorage("notificationHour") var notificationHour: Int = 9
    @AppStorage("notificationMinute") var notificationMinute: Int = 0
    @AppStorage("currentLanguageCode") var currentLanguageCode: String = "id"
    @AppStorage("myLanguageCodes") var myLanguageCodesData: String = "[\"id\",\"zh-CN\"]"

    private init() {}

    var isFormal: Bool {
        formality == "formal"
    }

    var currentLanguage: Language {
        Language.find(byCode: currentLanguageCode) ?? Language.allLanguages[0]
    }

    var myLanguageCodes: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(myLanguageCodesData.utf8))) ?? ["id", "zh-CN"]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                myLanguageCodesData = string
            }
        }
    }

    var myLanguages: [Language] {
        myLanguageCodes.compactMap { Language.find(byCode: $0) }
    }

    func addLanguage(_ language: Language) {
        var codes = myLanguageCodes
        guard !codes.contains(language.code) else { return }
        codes.append(language.code)
        myLanguageCodes = codes
    }

    func removeLanguage(_ language: Language) {
        var codes = myLanguageCodes
        codes.removeAll { $0 == language.code }
        myLanguageCodes = codes
        if currentLanguageCode == language.code, let first = codes.first {
            currentLanguageCode = first
        }
    }

    func setCurrentLanguage(_ language: Language) {
        currentLanguageCode = language.code
    }

    var notificationTime: Date {
        get {
            var components = DateComponents()
            components.hour = notificationHour
            components.minute = notificationMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            notificationHour = components.hour ?? 9
            notificationMinute = components.minute ?? 0
        }
    }
}
