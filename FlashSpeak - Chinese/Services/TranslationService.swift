import Foundation

class TranslationService {
    static let shared = TranslationService()
    
    private init() {}
    
    struct TranslationResult {
        let hanzi: String
        let pinyin: String
    }
    
    enum TranslationError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case apiError(String)
        case decodingError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from server"
            case .apiError(let message):
                return "API error: \(message)"
            case .decodingError:
                return "Failed to parse translation response"
            }
        }
    }
    
    func translate(_ englishText: String) async throws -> TranslationResult {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let systemPrompt = """
        You are a Chinese language translation assistant. Translate English phrases into Mandarin Chinese using everyday, colloquial speech - the way a native speaker would naturally say it in casual conversation. Avoid formal or written Chinese.

        Return JSON only, no markdown, no code blocks, just raw JSON:
        {"hanzi": "Chinese characters here", "pinyin": "pinyin with tone marks here"}
        """
        
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 256,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": englishText]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to extract error message from response
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw TranslationError.apiError(message)
            }
            throw TranslationError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse Claude's response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw TranslationError.decodingError
        }
        
        // Parse the JSON from Claude's text response
        guard let translationData = text.data(using: .utf8),
              let translation = try? JSONSerialization.jsonObject(with: translationData) as? [String: String],
              let hanzi = translation["hanzi"],
              let pinyin = translation["pinyin"] else {
            throw TranslationError.decodingError
        }
        
        return TranslationResult(hanzi: hanzi, pinyin: pinyin)
    }
}
