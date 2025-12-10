import Foundation

class TranslationService {
    static let shared = TranslationService()
    
    private init() {}
    
    struct TranslationResult {
        let hanzi: String
        let pinyin: String
        let literalTranslation: String
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
    
    func translate(_ englishText: String, formality: String = "informal") async throws -> TranslationResult {
        guard let url = URL(string: APIConfig.translationEndpoint) else {
            throw TranslationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "english": englishText,
            "formality": formality
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJson["error"] as? String {
                throw TranslationError.apiError(message)
            }
            throw TranslationError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        guard let translation = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let hanzi = translation["hanzi"],
              let pinyin = translation["pinyin"] else {
            throw TranslationError.decodingError
        }
        
        let literal = translation["literal"] ?? ""
        
        return TranslationResult(hanzi: hanzi, pinyin: pinyin, literalTranslation: literal)
    }
}
