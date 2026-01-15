//
//  HeadlinesViewModelTests.swift
//  MedibankNewsTests
//
//  Created by Clayton on 15/1/2026.
//
import XCTest
@testable import MedibankNews

@MainActor
final class HeadlinesViewModelTests: XCTestCase {

    // MARK: - Tests

    func test_init_loadsSavedIDsFromStore() {
        let a1 = TestFactory.makeArticle(id: TestFactory.ID.a1)
        let a2 = TestFactory.makeArticle(id: TestFactory.ID.a2)
        let (sut, _, _, _) = makeSUT(savedInitial: [a1, a2])

        XCTAssertTrue(sut.savedArticleIDs.contains(TestFactory.ID.a1))
        XCTAssertTrue(sut.savedArticleIDs.contains(TestFactory.ID.a2))
        XCTAssertEqual(sut.savedArticleIDs.count, 2)
    }

    func test_isSavedArticle_returnsTrueWhenSaved() {
        let saved = TestFactory.makeArticle(id: "saved")
        let other = TestFactory.makeArticle(id: "other")
        let (sut, _, _, _) = makeSUT(savedInitial: [saved])

        XCTAssertTrue(sut.isSavedArticle(saved))
        XCTAssertFalse(sut.isSavedArticle(other))
    }

    func test_loadArticles_whenNoSources_setsEmptyStateAndClearsArticles() async {
        let (sut, client, _, _) = makeSUT(selectionIDs: [])
        sut.articles = [TestFactory.makeBaseArticle()] // prefill

        await sut.loadArticles()

        XCTAssertTrue(sut.articles.isEmpty)
        if case .empty(let title, let message) = sut.state {
            XCTAssertEqual(title, "No Sources Selected")
            XCTAssertEqual(message, "Go to Sources and select one or more sources.")
        } else {
            XCTFail("Expected .empty state")
        }
        XCTAssertNil(client.lastSourceIDs)
    }

    func test_loadArticles_successWithResults_setsLoadedStateAndArticles() async {
        let a1 = TestFactory.makeBaseArticle()
        let a2 = TestFactory.makeSecondaryArticle()

        let client = TestFactory.MockNewsAPIClient()
        client.fetchHeadlinesResult = .success([a1, a2])

        let (sut, _, _, _) = makeSUT(client: client, selectionIDs: [TestFactory.ID.source2, TestFactory.ID.source1])

        await sut.loadArticles()

        XCTAssertEqual(sut.articles.map(\.id), [
            TestFactory.ArticleFixture.baseID,
            TestFactory.ArticleFixture.secondaryID
        ])
        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(client.lastSourceIDs?.sorted(), [TestFactory.ID.source1, TestFactory.ID.source2])
    }

    func test_loadArticles_successWithNoResults_setsNoResultsEmptyState() async {
        let client = TestFactory.MockNewsAPIClient()
        client.fetchHeadlinesResult = .success([])

        let (sut, _, _, _) = makeSUT(client: client, selectionIDs: [TestFactory.ID.source2])

        await sut.loadArticles()

        XCTAssertTrue(sut.articles.isEmpty)
        if case .empty(let title, let message) = sut.state {
            XCTAssertEqual(title, "No Results")
            XCTAssertEqual(message, "No articles were returned for the selected sources.")
        } else {
            XCTFail("Expected .empty(No Results) state")
        }
    }

    func test_loadArticles_failure_setsFailedStateAndClearsArticles() async {
        let client = TestFactory.MockNewsAPIClient()
        client.fetchHeadlinesResult = .failure(TestFactory.MockNewsAPIClient.StubError.boom)

        let (sut, _, _, _) = makeSUT(client: client, selectionIDs: [TestFactory.ID.source2])
        sut.articles = [TestFactory.makeBaseArticle()] // prefill

        await sut.loadArticles()

        XCTAssertTrue(sut.articles.isEmpty)
        if case .failed(let message) = sut.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected .failed state")
        }
    }

    func test_saveArticle_insertsAtFront_persistsAndUpdatesSavedIDs() {
        let existing = TestFactory.makeSecondaryArticle()
        let toSave = TestFactory.makeBaseArticle()
        let (sut, _, _, savedStore) = makeSUT(savedInitial: [existing])

        sut.saveArticle(toSave)

        XCTAssertTrue(sut.savedArticleIDs.contains(TestFactory.ArticleFixture.baseID))
        XCTAssertEqual(savedStore.load().map(\.id), [
            TestFactory.ArticleFixture.baseID,
            TestFactory.ArticleFixture.secondaryID
        ])
        XCTAssertEqual(savedStore.saveCallCount, 1)
    }

    func test_saveArticle_whenAlreadySaved_doesNothing() {
        let existing = TestFactory.makeBaseArticle()
        let (sut, _, _, savedStore) = makeSUT(savedInitial: [existing])

        sut.saveArticle(existing)

        XCTAssertEqual(savedStore.load().map(\.id), [TestFactory.ArticleFixture.baseID])
        XCTAssertEqual(savedStore.saveCallCount, 0)
    }

    func test_toggleSavedArticle_whenNotSaved_savesAndUpdatesSet() {
        let a = TestFactory.makeBaseArticle()
        let (sut, _, _, savedStore) = makeSUT(savedInitial: [])
        XCTAssertFalse(sut.savedArticleIDs.contains(TestFactory.ArticleFixture.baseID))

        sut.toggleSavedArticle(a)

        XCTAssertTrue(sut.savedArticleIDs.contains(TestFactory.ArticleFixture.baseID))
        XCTAssertEqual(savedStore.load().map(\.id), [TestFactory.ArticleFixture.baseID])
        XCTAssertEqual(savedStore.saveCallCount, 1)
    }

    func test_toggleSavedArticle_whenSaved_removesAndUpdatesSet() {
        let a = TestFactory.makeBaseArticle()
        let b = TestFactory.makeSecondaryArticle()
        let (sut, _, _, savedStore) = makeSUT(savedInitial: [a, b])
        XCTAssertTrue(sut.savedArticleIDs.contains(TestFactory.ArticleFixture.baseID))

        sut.toggleSavedArticle(a)

        XCTAssertFalse(sut.savedArticleIDs.contains(TestFactory.ArticleFixture.baseID))
        XCTAssertEqual(savedStore.load().map(\.id), [TestFactory.ArticleFixture.secondaryID])
        XCTAssertEqual(savedStore.saveCallCount, 1)
    }

    func test_openArticle_setsSelectedURL() {
        let article = TestFactory.makeBaseArticle()
        let (sut, _, _, _) = makeSUT()

        sut.openArticle(article)

        XCTAssertEqual(sut.selectedArticleURL, TestFactory.ArticleFixture.baseURL)
    }

    func test_refreshSavedArticleIDs_reloadsFromStore() {
        let store = TestFactory.MockSavedArticlesStore(initial: [])
        let client = TestFactory.MockNewsAPIClient()
        let selection = TestFactory.MockSourceSelectionStore()

        let sut = HeadlinesViewModel(client: client, selectionStore: selection, savedStore: store)

        XCTAssertTrue(sut.savedArticleIDs.isEmpty)

        // mutate store out-of-band
        store.save([TestFactory.makeBaseArticle(), TestFactory.makeSecondaryArticle()])

        sut.refreshSavedArticleIDs()

        XCTAssertEqual(sut.savedArticleIDs, [
            TestFactory.ArticleFixture.baseID,
            TestFactory.ArticleFixture.secondaryID
        ])
    }
}

private extension HeadlinesViewModelTests {

    func makeSUT(
        client: TestFactory.MockNewsAPIClient = .init(),
        selectionIDs: Set<String> = [],
        savedInitial: [Article] = []
    ) -> (
        sut: HeadlinesViewModel,
        client: TestFactory.MockNewsAPIClient,
        selection: TestFactory.MockSourceSelectionStore,
        savedStore: TestFactory.MockSavedArticlesStore
    ) {

        let selection = TestFactory.MockSourceSelectionStore()
        selection.selectedSourceIDs = selectionIDs

        let savedStore = TestFactory.MockSavedArticlesStore(initial: savedInitial)
        let sut = HeadlinesViewModel(client: client, selectionStore: selection, savedStore: savedStore)

        return (sut, client, selection, savedStore)
    }
}
