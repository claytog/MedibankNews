//
//  APIResponseHelper.swift
//  MedibankNews
//
//  Created by Clayton on 15/1/2026.
//
import Foundation

final class APIResponseHelper {
    
    private let domain = APINewsEndpoint.domain
    
    func debugPrintResponse(_ data: Data, _ response: URLResponse, url: URL) {
        guard let http = response as? HTTPURLResponse else { return }

        print("--- \(domain) ---")
        print("URL:", url.absoluteString)
        print("HTTP:", http.statusCode)

        if let raw = String(data: data, encoding: .utf8) {
            let maxChars = 4_000
            let clipped = raw.count > maxChars ? String(raw.prefix(maxChars)) + "\n…(truncated)" : raw
            print("BODY:\n\(clipped)")
        }
        print("---------------")
    }

    func decodeOrThrowAPIError(_ data: Data) throws {
        struct APIErrorResponse: Decodable {
            let status: String
            let code: String?
            let message: String?
        }

        if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data),
           apiError.status == "error" {
            throw NSError(domain: domain, code: 0, userInfo: [NSLocalizedDescriptionKey: apiError.message ?? "\(domain) error"])
        }
    }

    func printDecodingError(_ error: Error) {
        switch error {
        case let DecodingError.keyNotFound(key, context):
            print("DecodingError.keyNotFound:", key.stringValue)
            print("Path:", context.codingPath.map(\.stringValue).joined(separator: "."))
            print("Debug:", context.debugDescription)

        case let DecodingError.typeMismatch(type, context):
            print("DecodingError.typeMismatch:", type)
            print("Path:", context.codingPath.map(\.stringValue).joined(separator: "."))
            print("Debug:", context.debugDescription)

        case let DecodingError.valueNotFound(type, context):
            print("DecodingError.valueNotFound:", type)
            print("Path:", context.codingPath.map(\.stringValue).joined(separator: "."))
            print("Debug:", context.debugDescription)

        case let DecodingError.dataCorrupted(context):
            print("DecodingError.dataCorrupted")
            print("Path:", context.codingPath.map(\.stringValue).joined(separator: "."))
            print("Debug:", context.debugDescription)

        default:
            print("Decode error:", error)
        }
    }
}
