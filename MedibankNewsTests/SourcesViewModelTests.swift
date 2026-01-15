//
//  SourcesViewModelTests.swift
//  MedibankNewsTests
//
//  Created by Clayton on 15/1/2026.
//
import XCTest
@testable import MedibankNews

@MainActor
final class SourcesViewModelTests: XCTestCase {

    // MARK: - Tests

    func test_init_loadsSelectedIDsFromSelectionStore() {
        let selection = TestFactory.MockSourceSelectionStore()
        selection.selectedSourceIDs = [TestFactory.ID.source1, TestFactory.ID.source2]

        let client = TestFactory.MockNewsAPIClient()
        let sut = SourcesViewModel(client: client, selectionStore: selection)

        XCTAssertEqual(sut.selectedIDs, [TestFactory.ID.source1, TestFactory.ID.source2])
        XCTAssertEqual(sut.selectedCount, 2)
    }

    func test_load_successWithResults_setsSources_andLoadedState() async {
        let s1 = TestFactory.makeSource1()
        let s2 = TestFactory.makeSource2()

        let client = TestFactory.MockNewsAPIClient()
        client.fetchSourcesResult = .success([s1, s2])

        let (sut, _) = makeSUT(client: client)

        await sut.load()

        XCTAssertEqual(sut.sources.map(\.id), [TestFactory.ID.source1, TestFactory.ID.source2])
        XCTAssertEqual(sut.state, .loaded)
    }

    func test_load_successWithNoResults_setsEmptyState_andClearsSources() async {
        let client = TestFactory.MockNewsAPIClient()
        client.fetchSourcesResult = .success([])

        let (sut, _) = makeSUT(client: client)
        sut.sources = [TestFactory.makeSource1()] // prefill

        await sut.load()

        XCTAssertTrue(sut.sources.isEmpty)
        if case .empty(let title, let message) = sut.state {
            XCTAssertEqual(title, "No Sources")
            XCTAssertEqual(message, "No news sources are currently available.")
        } else {
            XCTFail("Expected .empty state")
        }
    }

    func test_load_failure_setsFailedState() async {
        let client = TestFactory.MockNewsAPIClient()
        client.fetchSourcesResult = .failure(TestFactory.MockNewsAPIClient.StubError.boom)

        let (sut, _) = makeSUT(client: client)

        await sut.load()

        if case .failed(let message) = sut.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected .failed state")
        }
    }

    func test_toggle_whenNotSelected_insertsID_andPersistsToStore() {
        let source = TestFactory.makeSource1()

        let selection = TestFactory.MockSourceSelectionStore()
        selection.selectedSourceIDs = []

        let client = TestFactory.MockNewsAPIClient()
        let sut = SourcesViewModel(client: client, selectionStore: selection)

        XCTAssertFalse(sut.isSelected(source))

        sut.toggle(source)

        XCTAssertTrue(sut.isSelected(source))
        XCTAssertEqual(sut.selectedIDs, [TestFactory.ID.source1])
        XCTAssertEqual(selection.selectedSourceIDs, [TestFactory.ID.source1])
        XCTAssertEqual(sut.selectedCount, 1)
    }

    func test_toggle_whenSelected_removesID_andPersistsToStore() {
        let source = TestFactory.makeSource2()

        let selection = TestFactory.MockSourceSelectionStore()
        selection.selectedSourceIDs = [TestFactory.ID.source2]

        let client = TestFactory.MockNewsAPIClient()
        let sut = SourcesViewModel(client: client, selectionStore: selection)

        XCTAssertTrue(sut.isSelected(source))

        sut.toggle(source)

        XCTAssertFalse(sut.isSelected(source))
        XCTAssertTrue(sut.selectedIDs.isEmpty)
        XCTAssertTrue(selection.selectedSourceIDs.isEmpty)
        XCTAssertEqual(sut.selectedCount, 0)
    }

    func test_isSelected_reflectsSelectedIDs() {
        let s1 = TestFactory.makeSource1()
        let s2 = TestFactory.makeSource2()

        let selection = TestFactory.MockSourceSelectionStore()
        selection.selectedSourceIDs = [TestFactory.ID.source1]

        let client = TestFactory.MockNewsAPIClient()
        let sut = SourcesViewModel(client: client, selectionStore: selection)

        XCTAssertTrue(sut.isSelected(s1))
        XCTAssertFalse(sut.isSelected(s2))
    }

    func test_clearSelection_removesAll_andPersistsToStore() {
        let selection = TestFactory.MockSourceSelectionStore()
        selection.selectedSourceIDs = [TestFactory.ID.source1, TestFactory.ID.source2]

        let client = TestFactory.MockNewsAPIClient()
        let sut = SourcesViewModel(client: client, selectionStore: selection)

        XCTAssertEqual(sut.selectedCount, 2)

        sut.clearSelection()

        XCTAssertTrue(sut.selectedIDs.isEmpty)
        XCTAssertTrue(selection.selectedSourceIDs.isEmpty)
        XCTAssertEqual(sut.selectedCount, 0)
    }
}

private extension SourcesViewModelTests {

    func makeSUT(
        client: TestFactory.MockNewsAPIClient = .init(),
        selectionIDs: Set<String> = []
    ) -> (sut: SourcesViewModel, selection: TestFactory.MockSourceSelectionStore) {

        let selection = TestFactory.MockSourceSelectionStore()
        selection.selectedSourceIDs = selectionIDs

        let sut = SourcesViewModel(client: client, selectionStore: selection)
        return (sut, selection)
    }
}
