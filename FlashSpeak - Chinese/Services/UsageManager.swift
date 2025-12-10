import Foundation
import SwiftUI

class UsageManager: ObservableObject {
    static let shared = UsageManager()
    
    private let dailyLimitFree = 3
    
    @AppStorage("translationsToday") private var translationsToday: Int = 0
    @AppStorage("lastTranslationDate") private var lastTranslationDateString: String = ""
    
    @Published var todayCount: Int = 0
    
    private init() {
        resetIfNewDay()
        todayCount = translationsToday
    }
    
    var dailyLimit: Int {
        if StoreManager.shared.isSubscribed {
            return .max // Unlimited
        }
        return dailyLimitFree
    }
    
    var remainingToday: Int {
        max(0, dailyLimit - todayCount)
    }
    
    var canTranslate: Bool {
        StoreManager.shared.isSubscribed || todayCount < dailyLimitFree
    }
    
    var isSubscribed: Bool {
        StoreManager.shared.isSubscribed
    }
    
    func recordTranslation() {
        resetIfNewDay()
        translationsToday += 1
        todayCount = translationsToday
    }
    
    private func resetIfNewDay() {
        let today = formattedDate(Date())
        if lastTranslationDateString != today {
            translationsToday = 0
            lastTranslationDateString = today
            todayCount = 0
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
