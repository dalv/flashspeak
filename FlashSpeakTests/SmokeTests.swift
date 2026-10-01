import Testing
@testable import FlashSpeak

struct SmokeTests {
    @Test func supportedLanguageThemesExist() {
        #expect(LanguageTheme.all.count == 4)
    }
}
