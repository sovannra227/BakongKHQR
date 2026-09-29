import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Calls to the Bakong Open API.
enum OpenAPI {
    static let timeout: TimeInterval = 45
    static let deepLinkPath = "/v1/generate_deeplink_by_qr"

    static func isValidDeepLinkURL(_ string: String) -> Bool {
        guard let components = URLComponents(string: string), components.scheme != nil, components.host != nil else {
            return false
        }
        return components.path == deepLinkPath
    }

    /// Posts a JSON body and returns the JSON object of the response. Any failure to get one is
    /// reported as `connectionTimeout`.
    static func post(_ url: String, body: [String: Any], session: URLSession) async throws -> [String: Any] {
        guard let url = URL(string: url), let payload = try? JSONSerialization.data(withJSONObject: body) else {
            throw KHQRError.connectionTimeout
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload

        let data: Data = try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { data, response, _ in
                guard let data,
                      let response = response as? HTTPURLResponse,
                      (200..<300).contains(response.statusCode)
                else {
                    continuation.resume(throwing: KHQRError.connectionTimeout)
                    return
                }
                continuation.resume(returning: data)
            }.resume()
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw KHQRError.connectionTimeout
        }
        return json
    }

    static func integer(_ value: Any?) -> Int? {
        (value as? NSNumber)?.intValue
    }
}
