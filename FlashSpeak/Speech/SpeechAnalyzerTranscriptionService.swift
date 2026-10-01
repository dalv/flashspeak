@preconcurrency import AVFoundation
import Speech

/// `TranscriptionService` on SpeechAnalyzer (iOS 26), en-US, fully on the
/// device. Microphone audio is converted to the analyzer's format and
/// streamed in; nothing is written to disk.
@MainActor
final class SpeechAnalyzerTranscriptionService: TranscriptionService {
    private let locale = Locale(identifier: "en-US")
    private let audioSession: AudioSessionCoordinator

    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var engine: AVAudioEngine?
    private var resultsTask: Task<Void, Never>?

    init(audioSession: AudioSessionCoordinator) {
        self.audioSession = audioSession
    }

    func requestPermission() async -> Bool {
        let microphone = await AVAudioApplication.requestRecordPermission()
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        return microphone && speech == .authorized
    }

    func prepare(progress: @escaping (Double) -> Void) async throws {
        let transcriber = makeTranscriber()
        guard await SpeechTranscriber.supportedLocales.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) else {
            throw TranscriptionError.modelUnavailable
        }
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            let observation = request.progress.observe(\.fractionCompleted) { value, _ in
                let fraction = value.fractionCompleted
                Task { @MainActor in progress(fraction) }
            }
            defer { observation.invalidate() }
            try await request.downloadAndInstall()
        }
        progress(1)
    }

    func start() async throws -> AsyncThrowingStream<Transcript, Error> {
        await stop()
        try audioSession.activate(.recording)

        let transcriber = makeTranscriber()
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw TranscriptionError.audioUnavailable
        }
        let (inputs, builder) = AsyncStream<AnalyzerInput>.makeStream()
        try await analyzer.start(inputSequence: inputs)

        let engine = AVAudioEngine()
        let input = engine.inputNode
        let micFormat = input.outputFormat(forBus: 0)
        guard let converter = AVAudioConverter(from: micFormat, to: format) else {
            throw TranscriptionError.audioUnavailable
        }
        input.installTap(
            onBus: 0, bufferSize: 4096, format: micFormat,
            block: Self.tapBlock(converter: converter, format: format, builder: builder)
        )
        engine.prepare()
        try engine.start()

        self.transcriber = transcriber
        self.analyzer = analyzer
        inputBuilder = builder
        self.engine = engine

        return AsyncThrowingStream { continuation in
            resultsTask = Task {
                var transcript = Transcript.empty
                do {
                    for try await result in transcriber.results {
                        let text = String(result.text.characters)
                        if result.isFinal {
                            transcript.finalized = [transcript.finalized, text]
                                .filter { !$0.isEmpty }.joined(separator: " ")
                            transcript.volatile = ""
                        } else {
                            transcript.volatile = text
                        }
                        continuation.yield(transcript)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func stop() async {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        inputBuilder?.finish()
        inputBuilder = nil
        try? await analyzer?.finalizeAndFinishThroughEndOfInput()
        analyzer = nil
        transcriber = nil
        await resultsTask?.value
        resultsTask = nil
        audioSession.deactivate()
    }

    // MARK: - Private

    private func makeTranscriber() -> SpeechTranscriber {
        SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )
    }

    /// Built outside the main actor because the tap runs on the audio thread.
    private nonisolated static func tapBlock(
        converter: AVAudioConverter,
        format: AVAudioFormat,
        builder: AsyncStream<AnalyzerInput>.Continuation
    ) -> AVAudioNodeTapBlock {
        { buffer, _ in
            if let converted = convert(buffer, with: converter, to: format) {
                builder.yield(AnalyzerInput(buffer: converted))
            }
        }
    }

    private nonisolated static func convert(
        _ buffer: AVAudioPCMBuffer,
        with converter: AVAudioConverter,
        to format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up))
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        var supplied = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if supplied {
                status.pointee = .noDataNow
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return buffer
        }
        return error == nil ? output : nil
    }
}
