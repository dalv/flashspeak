import Foundation

/// `TranslationClient` for the Cloudflare Worker's v2 endpoints.
struct WorkerTranslationClient: TranslationClient {
    let baseURL: URL
    var session: URLSession = .shared

    func translate(_ request: TranslationRequest) async throws(TranslationError) -> TranslationResult {
        try await post("v2/translate", request)
    }

    func clarify(_ request: ClarificationRequest) async throws(TranslationError) -> ClarificationResult {
        try await post("v2/clarify", request)
    }

    func suggest(_ request: SuggestionRequest) async throws(TranslationError) -> [SuggestedPhrase] {
        let response: SuggestionResponse = try await post("v2/suggest", request)
        return response.phrases
    }

    func flag(_ report: TranslationFlag) async throws(TranslationError) {
        let _: FlagResponse = try await post("v2/flag", report)
    }

    // MARK: - Private

    private struct SuggestionResponse: Decodable { var phrases: [SuggestedPhrase] }
    private struct FlagResponse: Decodable { var ok: Bool }
    private struct ErrorResponse: Decodable { var error: String }

    private func post<Body: Encodable, Reply: Decodable>(_ path: String, _ body: Body) async throws(TranslationError) -> Reply {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let data: Data
        let response: URLResponse
        do {
            request.httpBody = try JSONEncoder().encode(body)
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where Self.offlineCodes.contains(error.code) {
            throw .offline
        } catch {
            throw .server(status: 0, message: error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw .invalidResponse }
        switch http.statusCode {
        case 200 ..< 300:
            do {
                return try JSONDecoder().decode(Reply.self, from: data)
            } catch {
                throw .invalidResponse
            }
        case 402, 429:
            throw .limitReached
        default:
            let message = try? JSONDecoder().decode(ErrorResponse.self, from: data).error
            if http.statusCode == 400, message?.contains("language") == true {
                throw .unsupportedLanguage
            }
            throw .server(status: http.statusCode, message: message)
        }
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .cannotFindHost, .cannotConnectToHost,
    ]
}
