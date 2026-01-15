//
//  SavedViewModelTests.swift
//  MedibankNewsTests
//
//  Created by Clayton on 15/1/2026.
//
import XCTest
@testable import MedibankNews

@MainActor
final class SavedViewModelTests: XCTestCase {

    // MARK: - Tests

    func test_init_startsWithEmptySavedAndNilSelection() {
        let (sut, _) = makeSUT()

        XCTAssertTrue(sut.saved.isEmpty)
        XCTAssertNil(sut.selectedArticle)
    }

    func test_loadArticle_loadsFromStore() {
        let a1 = TestFactory.makeBaseArticle()
        let a2 = TestFactory.makeSecondaryArticle()
        let store = TestFactory.MockSavedArticlesStore(initial: [a1, a2])
        let sut = SavedViewModel(savedArticlesStore: store)

        sut.loadArticle()

        XCTAssertEqual(sut.saved.map(\.id), [TestFactory.ArticleFixture.baseID, TestFactory.ArticleFixture.secondaryID])
    }

    func test_openArticle_setsSelectedArticle() {
        let article = TestFactory.makeBaseArticle()
        let (sut, _) = makeSUT()

        sut.openArticle(article)

        XCTAssertEqual(sut.selectedArticle?.id, TestFactory.ArticleFixture.baseID)
    }

    func test_isArticleSaved_returnsTrueWhenSavedContainsMatchingID() {
        let saved = TestFactory.makeBaseArticle()
        let other = TestFactory.makeSecondaryArticle()
        let (sut, _) = makeSUT(initialSaved: [saved])

        XCTAssertTrue(sut.isArticleSaved(saved))
        XCTAssertFalse(sut.isArticleSaved(other))
    }

    func test_toggleSavedArticle_whenNotSaved_insertsAtFront_andPersists() {
        let a1 = TestFactory.makeSecondaryArticle() // existing (will become index 1)
        let toToggle = TestFactory.makeBaseArticle() // inserted at front

        let (sut, store) = makeSUT(initialSaved: [a1])
        XCTAssertFalse(sut.isArticleSaved(toToggle))

        sut.toggleSavedArticle(toToggle)

        XCTAssertEqual(sut.saved.map(\.id), [TestFactory.ArticleFixture.baseID, TestFactory.ArticleFixture.secondaryID])
        XCTAssertEqual(store.load().map(\.id), [TestFactory.ArticleFixture.baseID, TestFactory.ArticleFixture.secondaryID])
        XCTAssertEqual(store.saveCallCount, 1)
    }

    func test_toggleSavedArticle_whenSaved_removes_andPersists() {
        let a1 = TestFactory.makeBaseArticle()
        let a2 = TestFactory.makeSecondaryArticle()

        let (sut, store) = makeSUT(initialSaved: [a1, a2])
        XCTAssertTrue(sut.isArticleSaved(a1))

        sut.toggleSavedArticle(a1)

        XCTAssertEqual(sut.saved.map(\.id), [TestFactory.ArticleFixture.secondaryID])
        XCTAssertEqual(store.load().map(\.id), [TestFactory.ArticleFixture.secondaryID])
        XCTAssertEqual(store.saveCallCount, 1)
    }

    func test_deleteArticle_removesByOffsets_andPersists() {
        let a1 = TestFactory.makeBaseArticle()
        let a2 = TestFactory.makeSecondaryArticle()
        let (sut, store) = makeSUT(initialSaved: [a1, a2])

        sut.deleteArticle(at: IndexSet(integer: 0))

        XCTAssertEqual(sut.saved.map(\.id), [TestFactory.ArticleFixture.secondaryID])
        XCTAssertEqual(store.load().map(\.id), [TestFactory.ArticleFixture.secondaryID])
        XCTAssertEqual(store.saveCallCount, 1)
    }

    func test_deleteArticle_multipleOffsets_removesCorrectItems_andPersists() {
        // Three articles: base, secondary, and a third with a custom id to track order.
        let a1 = TestFactory.makeBaseArticle()
        let a2 = TestFactory.makeSecondaryArticle()
        let a3 = TestFactory.makeArticle(id: TestFactory.ID.a1)

        let (sut, store) = makeSUT(initialSaved: [a1, a2, a3])

        // remove secondary (index 1) and a3 (index 2)
        sut.deleteArticle(at: IndexSet([1, 2]))

        XCTAssertEqual(sut.saved.map(\.id), [TestFactory.ArticleFixture.baseID])
        XCTAssertEqual(store.load().map(\.id), [TestFactory.ArticleFixture.baseID])
        XCTAssertEqual(store.saveCallCount, 1)
    }
}

private extension SavedViewModelTests {

    func makeSUT(initialSaved: [Article] = []) -> (sut: SavedViewModel, store: TestFactory.MockSavedArticlesStore) {

        let store = TestFactory.MockSavedArticlesStore(initial: initialSaved)
        let sut = SavedViewModel(savedArticlesStore: store)

        // Mirror real usage: many screens call load on appear.
        sut.loadArticle()

        return (sut, store)
    }
}

