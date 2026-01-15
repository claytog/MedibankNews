//
//  NewsAPIClient.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import Foundation

final class NewsAPIClient: NewsAPIClientProtocol {

    private let apiKeyProvider: APIKeyProvider
    private let session: URLSession
    private let apiHelper = APIResponseHelper()

    init(apiKeyProvider: APIKeyProvider, session: URLSession = .shared) {
        self.apiKeyProvider = apiKeyProvider
        self.session = session
    }

    func fetchSources() async throws -> [Source] {
        let url = try makeURL(endpoint: .sources, extraQueryItems: [])

        let (data, response) = try await session.data(from: url)

        #if DEBUG
        apiHelper.debugPrintResponse(data, response, url: url)
        #endif

        try validateHTTPResponse(response, data: data)

        do {
            let decoder = APINewsCoding.makeDecoder()
            let decoded = try decoder.decode(SourcesResponse.self, from: data)
            return decoded.sources.sorted { $0.name < $1.name }
        } catch {
            #if DEBUG
            apiHelper.printDecodingError(error)
            #endif
            throw error
        }
    }

    func fetchHeadlines(sourceIDs: [String]) async throws -> [Article] {
        let ids = sourceIDs
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !ids.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: [Article].self) { group in
            for id in ids {
                group.addTask {
                    try await self.fetchHeadlines(forSourceID: id)
                }
            }

            var all: [Article] = []
            for try await articles in group {
                all.append(contentsOf: articles)
            }

            var seen = Set<String>()
            let deduped = all.filter { seen.insert($0.id).inserted }

            return deduped.sorted { (a, b) in
                (a.publishedAt ?? .distantPast) > (b.publishedAt ?? .distantPast)
            }
        }
    }

    private func fetchHeadlines(forSourceID sourceID: String) async throws -> [Article] {
        let url = try makeURL(
            endpoint: .topHeadlines(sourceID: sourceID),
            extraQueryItems: [
                URLQueryItem(name: "pageSize", value: "10")
            ]
        )

        let (data, response) = try await session.data(from: url)

        #if DEBUG
        apiHelper.debugPrintResponse(data, response, url: url)
        #endif

        try validateHTTPResponse(response, data: data)

        do {
            let decoder = APINewsCoding.makeDecoder()
            let decoded = try decoder.decode(HeadlinesResponse.self, from: data)
            return decoded.articles
        } catch {
            #if DEBUG
            apiHelper.printDecodingError(error)
            #endif
            throw error
        }
    }
}

private extension NewsAPIClient {

    func makeURL(endpoint: APINewsEndpoint, extraQueryItems: [URLQueryItem]) throws -> URL {
        let components = endpoint.makeComponents(apiKey: apiKeyProvider.newsAPIKey, extraQueryItems: extraQueryItems)
        guard let url = components.url else { throw URLError(.badURL) }
        return url
    }

    func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(http.statusCode) else {
            try apiHelper.decodeOrThrowAPIError(data)
            throw URLError(.badServerResponse)
        }
    }
}
