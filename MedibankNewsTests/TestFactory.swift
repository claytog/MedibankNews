//
//  TestFactory.swift
//  MedibankNewsTests
//
//  Created by Clayton on 15/1/2026.
//
import Foundation
@testable import MedibankNews

enum TestFactory {

    enum API {
        static let key = "KEY123"
    }
    
    enum ID {
        static let a1 = "a1"
        static let a2 = "a2"
        static let source1 = "abc-news"
        static let source2 = "bbc-news"
    }

    enum Name {
        static let source1 = "ABC News"
        static let source2 = "BBC News"
    }

    enum URLs {
        static let example = "https://example.com"
    }

    enum ArticleFixture {
        static let baseURL = URL(string: "\(URLs.example)/test-article")!
        static let baseID = baseURL.absoluteString

        static let secondaryURL = URL(string: "\(URLs.example)/test-article-2")!
        static let secondaryID = secondaryURL.absoluteString
    }

    static func makeArticle(
        id: String? = nil,
        url: URL = ArticleFixture.baseURL,
        title: String = "Test title",
        author: String? = nil,
        description: String? = nil,
        urlToImage: URL? = nil,
        publishedAt: Date? = nil,
        content: String? = nil
    ) -> Article {
        Article(
            id: id,
            url: url,
            title: title,
            author: author,
            description: description,
            urlToImage: urlToImage,
            publishedAt: publishedAt,
            content: content
        )
    }

    /// Convenience: returns an article whose id is always `ArticleFixture.baseID`.
    static func makeBaseArticle(
        title: String = "Base article"
    ) -> Article {
        makeArticle(url: ArticleFixture.baseURL, title: title)
    }

    /// Convenience: returns an article whose id is always `ArticleFixture.secondaryID`.
    static func makeSecondaryArticle(
        title: String = "Secondary article"
    ) -> Article {
        makeArticle(url: ArticleFixture.secondaryURL, title: title)
    }
    
    static func makeSource1() -> Source {
        makeSource(id: ID.source1, name: Name.source1)
    }

    static func makeSource2() -> Source {
        makeSource(id: ID.source2, name: Name.source2)
    }

    // MARK: - Mocks

    final class MockNewsAPIClient: NewsAPIClientProtocol {
        enum StubError: Error { case boom }

        // Headlines
        var fetchHeadlinesResult: Result<[Article], Error> = .success([])
        private(set) var lastSourceIDs: [String]?

        // Sources
        var fetchSourcesResult: Result<[Source], Error> = .success([])

        func fetchHeadlines(sourceIDs: [String]) async throws -> [Article] {
            lastSourceIDs = sourceIDs
            switch fetchHeadlinesResult {
            case .success(let articles): return articles
            case .failure(let error): throw error
            }
        }

        func fetchSources() async throws -> [Source] {
            switch fetchSourcesResult {
            case .success(let sources): return sources
            case .failure(let error): throw error
            }
        }
    }

    final class MockSourceSelectionStore: SourceSelectionStore {
       var selectedSourceIDs: Set<String> = []
    }
    
    final class MockSavedArticlesStore: SavedArticlesStore {
       private var storage: [Article]
       private(set) var saveCallCount: Int = 0

       init(initial: [Article] = []) {
           self.storage = initial
       }

       func load() -> [Article] { storage }

       func save(_ articles: [Article]) {
           saveCallCount += 1
           storage = articles
       }
    }

    static func makeSource(
        id: String = ID.source1,
        name: String = Name.source1,
        description: String? = nil,
        url: URL? = URL(string: URLs.example),
        category: String? = nil,
        language: String? = "en",
        country: String? = "au"
    ) -> Source {
        Source(
            id: id,
            name: name,
            description: description,
            url: url,
            category: category,
            language: language,
            country: country
        )
    }
    
}
