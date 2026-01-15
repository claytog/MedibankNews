//
//  SourcesViewModel.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import Foundation

@MainActor
final class SourcesViewModel: ObservableObject {

    @Published var sources: [Source] = []
    @Published var state: LoadState = .idle
    @Published private(set) var selectedIDs: Set<String>

    private let client: NewsAPIClientProtocol
    private var selectionStore: SourceSelectionStore

    init(client: NewsAPIClientProtocol, selectionStore: SourceSelectionStore) {
        self.client = client
        self.selectionStore = selectionStore
        self.selectedIDs = selectionStore.selectedSourceIDs
    }

    func load() async {
        state = .loading
        do {
            let fetched = try await client.fetchSources()
            sources = fetched
            state = fetched.isEmpty ? .empty(title: "No Sources", message: "No news sources are currently available.") : .loaded
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    func toggle(_ source: Source) {
        if selectedIDs.contains(source.id) {
            selectedIDs.remove(source.id)
        } else {
            selectedIDs.insert(source.id)
        }
        selectionStore.selectedSourceIDs = selectedIDs
    }

    func isSelected(_ source: Source) -> Bool {
        selectedIDs.contains(source.id)
    }

    var selectedCount: Int {
        selectedIDs.count
    }

    func clearSelection() {
        selectedIDs.removeAll()
        selectionStore.selectedSourceIDs = selectedIDs
    }
}
