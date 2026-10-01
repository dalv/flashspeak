/// On-device English speech to text.
@MainActor
protocol TranscriptionService: AnyObject {
    /// Asks for microphone and speech permission. Returns false if denied.
    func requestPermission() async -> Bool
    /// Makes sure the English model is installed, reporting progress 0…1.
    func prepare(progress: @escaping (Double) -> Void) async throws
    /// Starts listening. The stream yields the growing transcript and ends
    /// after `stop()` once the last words are final.
    func start() async throws -> AsyncThrowingStream<Transcript, Error>
    func stop() async
}

enum TranscriptionError: Error, Equatable {
    case permissionDenied
    case modelUnavailable
    case audioUnavailable
}
