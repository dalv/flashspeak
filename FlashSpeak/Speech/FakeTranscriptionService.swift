/// A `TranscriptionService` for Previews and tests: "hears" a fixed phrase
/// word by word.
@MainActor
final class FakeTranscriptionService: TranscriptionService {
    var phrase = "Can you say that one more time, slowly?"
    var wordDelay: Duration = .milliseconds(250)
    var grantsPermission = true

    private var task: Task<Void, Never>?

    func requestPermission() async -> Bool {
        grantsPermission
    }

    func prepare(progress: @escaping (Double) -> Void) async throws {
        progress(1)
    }

    func start() async throws -> AsyncThrowingStream<Transcript, Error> {
        let words = phrase.split(separator: " ").map(String.init)
        let delay = wordDelay
        return AsyncThrowingStream { continuation in
            task = Task {
                var heard: [String] = []
                for word in words {
                    try? await Task.sleep(for: delay)
                    if Task.isCancelled {
                        break
                    }
                    heard.append(word)
                    continuation.yield(Transcript(finalized: heard.dropLast().joined(separator: " "), volatile: word))
                }
                continuation.yield(Transcript(finalized: heard.joined(separator: " "), volatile: ""))
                continuation.finish()
            }
        }
    }

    func stop() async {
        task?.cancel()
        await task?.value
        task = nil
    }
}
