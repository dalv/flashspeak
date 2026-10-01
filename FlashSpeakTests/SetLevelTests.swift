@testable import FlashSpeak
import Testing

struct SetLevelTests {
    @Test func newSetStartsAtOne() {
        #expect(SetLevel.current(levels: [], override: nil) == 1)
        #expect(SetLevel.current(levels: [nil, nil], override: nil) == 1)
    }

    @Test func medianOfKnownLevels() {
        #expect(SetLevel.current(levels: [3, 1, 2], override: nil) == 2)
        #expect(SetLevel.current(levels: [1, 2, 3, 4], override: nil) == 2)
        #expect(SetLevel.current(levels: [nil, 4, nil, 4, 1], override: nil) == 4)
    }

    @Test func onlyTheMostRecentFiftyCount() {
        let levels: [Int?] = Array(repeating: 5, count: 50) + Array(repeating: 1, count: 100)
        #expect(SetLevel.current(levels: levels, override: nil) == 5)
    }

    @Test func overrideWinsAndIsClamped() {
        #expect(SetLevel.current(levels: [1, 1, 1], override: 4) == 4)
        #expect(SetLevel.current(levels: [], override: 9) == 6)
    }
}
