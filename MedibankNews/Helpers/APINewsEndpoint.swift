//
//  APINewsEndpoint.swift
//  MedibankNews
//
//  Created by Clayton on 15/1/2026.
//
import Foundation

enum APINewsEndpoint {
    static let domain = "NewsAPI"
    static let host = "newsapi.org"
    static let scheme = "https"

    case sources
    case topHeadlines(sourceID: String)

    var path: String {
        switch self {
        case .sources:
            return "/v2/top-headlines/sources"
        case .topHeadlines:
            return "/v2/top-headlines"
        }
    }

    func makeComponents(apiKey: String, extraQueryItems: [URLQueryItem] = []) -> URLComponents {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        components.path = path

        var queryItems = [URLQueryItem(name: "apiKey", value: apiKey)]

        switch self {
        case .sources:
            queryItems.append(URLQueryItem(name: "language", value: "en"))
            
        case .topHeadlines(let sourceID):
            queryItems.append(URLQueryItem(name: "sources", value: sourceID))
        }

        queryItems.append(contentsOf: extraQueryItems)
        components.queryItems = queryItems

        return components
    }
}
