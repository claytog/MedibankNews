//
//  NewsAPIClientTests.swift
//  MedibankNewsTests
//
//  Created by Clayton on 15/1/2026.
//
import XCTest
@testable import MedibankNews

final class NewsAPIClientTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.requestHandler = nil
    }

    // MARK: - fetchSources()

    func test_fetchSources_returnsSourcesSortedByName_andSendsExpectedQueryItems() async throws {
        let apiKey = TestFactory.API.key
        let sut = makeSUT(apiKey: apiKey)

        let expected = expectedBaseURL(for: .sources, apiKey: apiKey, extraQueryItems: [])

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)

            XCTAssertEqual(url.scheme, expected.scheme)
            XCTAssertEqual(url.host, expected.host)
            XCTAssertEqual(url.path, expected.path)

            let query = Self.queryItems(url)
            XCTAssertEqual(query["apiKey"], apiKey)
            XCTAssertEqual(query["language"], "en")

            // Return sources out-of-order, client should sort by name ascending
            let json = Self.makeSourcesJSON(sources: [
                Self.makeSourceJSON(id: TestFactory.ID.source2, name: TestFactory.Name.source2), // BBC
                Self.makeSourceJSON(id: TestFactory.ID.source1, name: TestFactory.Name.source1)  // ABC
            ])

            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let sources = try await sut.fetchSources()

        XCTAssertEqual(sources.map(\.name), [TestFactory.Name.source1, TestFactory.Name.source2])
        XCTAssertEqual(sources.map(\.id), [TestFactory.ID.source1, TestFactory.ID.source2])
    }

    func test_fetchSources_whenNon2xx_throws() async {
        let sut = makeSUT()

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)

            let data = """
            {
              "status": "error",
              "code": "apiKeyInvalid",
              "message": "Your API key is invalid or incorrect."
            }
            """.data(using: .utf8)!

            let response = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        do {
            _ = try await sut.fetchSources()
            XCTFail("Expected fetchSources() to throw, but it returned successfully.")
        } catch {
            XCTAssertTrue(true)
        }
    }

    // MARK: - fetchHeadlines(sourceIDs:)

    func test_fetchHeadlines_whenAllSourceIDsAreEmpty_returnsEmpty_andDoesNotRequestNetwork() async throws {
        let sut = makeSUT()

        MockURLProtocol.requestHandler = { _ in
            XCTFail("Network should not be called when all sourceIDs are empty.")
            throw URLError(.badURL)
        }

        // This test assumes production code trims whitespace.
        let articles = try await sut.fetchHeadlines(sourceIDs: ["", "   ", "\n\t"])
        XCTAssertEqual(articles.count, 0)
    }

    func test_fetchHeadlines_dedupesByID_andSortsByPublishedAtDescending_andUsesPageSize10() async throws {
        let apiKey = TestFactory.API.key
        let sut = makeSUT(apiKey: apiKey)

        let sharedURL = URL(string: "\(TestFactory.URLs.example)/shared")!
        let uniqueURL = URL(string: "\(TestFactory.URLs.example)/unique")!

        let newer = "2026-01-15T10:00:00Z"
        let older = "2026-01-14T10:00:00Z"

        let lock = NSLock()
        var requestedSourceIDs: [String] = []
        var requestedPageSizes: [String] = []

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)

            // Derived endpoint checks
            let expected = self.expectedBaseURL(for: .topHeadlines(sourceID: "IGNORED"), apiKey: apiKey, extraQueryItems: [])
            XCTAssertEqual(url.scheme, expected.scheme)
            XCTAssertEqual(url.host, expected.host)
            XCTAssertEqual(url.path, APINewsEndpoint.topHeadlines(sourceID: "x").path)

            let query = Self.queryItems(url)

            // Endpoint uses "sources" query param for top headlines
            let sourceID = query["sources"] ?? ""
            lock.lock()
            requestedSourceIDs.append(sourceID)
            if let ps = query["pageSize"] { requestedPageSizes.append(ps) }
            lock.unlock()

            // Enforce required query items
            XCTAssertEqual(query["apiKey"], apiKey)
            XCTAssertEqual(query["pageSize"], "10")
            XCTAssertFalse(sourceID.isEmpty)

            let data: Data
            switch sourceID {
            case TestFactory.ID.source1:
                data = Self.makeHeadlinesJSON(articles: [
                    Self.makeArticleJSON(url: sharedURL.absoluteString, title: "Shared (older)", publishedAt: older),
                    Self.makeArticleJSON(url: uniqueURL.absoluteString, title: "Unique (newer)", publishedAt: newer)
                ])
            case TestFactory.ID.source2:
                data = Self.makeHeadlinesJSON(articles: [
                    Self.makeArticleJSON(url: sharedURL.absoluteString, title: "Shared (older - dup)", publishedAt: older)
                ])
            default:
                XCTFail("Unexpected sourceID in request: '\(sourceID)'. Query: \(query)")
                data = Self.makeHeadlinesJSON(articles: [])
            }

            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let articles = try await sut.fetchHeadlines(sourceIDs: [TestFactory.ID.source1, TestFactory.ID.source2])

        // Sorted by publishedAt desc: Unique (newer) should come first
        XCTAssertEqual(articles.first?.title, "Unique (newer)")

        // Dedupe assertion: exactly one per URL (regardless of which response arrived first)
        let urls = articles.map(\.url)
        XCTAssertTrue(urls.contains(uniqueURL))
        XCTAssertTrue(urls.contains(sharedURL))
        XCTAssertEqual(Set(urls).count, 2)

        // Ensure each source was requested (order not guaranteed)
        XCTAssertEqual(Set(requestedSourceIDs), Set([TestFactory.ID.source1, TestFactory.ID.source2]))

        // Ensure pageSize=10
        XCTAssertTrue(requestedPageSizes.allSatisfy { $0 == "10" })
    }
}

// MARK: - JSON helpers

private extension NewsAPIClientTests {

    static func queryItems(_ url: URL) -> [String: String] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.compactMap { item in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
    }

    static func makeSourcesJSON(sources: [[String: Any]]) -> Data {
        let payload: [String: Any] = [
            "status": "ok",
            "sources": sources
        ]
        return encode(payload)
    }

    static func makeSourceJSON(id: String, name: String) -> [String: Any] {
        [
            "id": id,
            "name": name,
            "description": "desc",
            "url": TestFactory.URLs.example,
            "category": "general",
            "language": "en",
            "country": "au"
        ]
    }

    static func makeHeadlinesJSON(articles: [[String: Any]]) -> Data {
        let payload: [String: Any] = [
            "status": "ok",
            "totalResults": articles.count,
            "articles": articles
        ]
        return encode(payload)
    }

    static func makeArticleJSON(
        url: String,
        title: String,
        publishedAt: String? = nil,
        author: String? = nil,
        description: String? = nil,
        content: String? = nil
    ) -> [String: Any] {

        var article: [String: Any] = [
            "source": [
                "id": TestFactory.ID.source1,
                "name": TestFactory.Name.source1
            ],
            "url": url,
            "title": title
        ]

        if let author { article["author"] = author }
        if let description { article["description"] = description }
        if let publishedAt { article["publishedAt"] = publishedAt }
        if let content { article["content"] = content }

        article["urlToImage"] = "\(TestFactory.URLs.example)/img.png"

        return article
    }

    static func encode(_ object: Any) -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: object, options: [])
        } catch {
            fatalError("Failed to encode JSON: \(error)")
        }
    }
}

// MARK: - SUT + endpoint expectation helpers

private extension NewsAPIClientTests {

    private struct MockAPIKeyProvider: APIKeyProvider {
        let newsAPIKey: String
    }

    private func makeSUT(apiKey: String = "TEST_API_KEY") -> NewsAPIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]

        let session = URLSession(configuration: config)
        return NewsAPIClient(
            apiKeyProvider: MockAPIKeyProvider(newsAPIKey: apiKey),
            session: session
        )
    }

    private func expectedBaseURL(for endpoint: APINewsEndpoint, apiKey: String, extraQueryItems: [URLQueryItem]) -> URL {
        let components = endpoint.makeComponents(apiKey: apiKey, extraQueryItems: extraQueryItems)
        return (try? XCTUnwrap(components.url)) ?? URL(string: "https://invalid")!
    }
}
