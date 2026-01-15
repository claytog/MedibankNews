//
//  AppContainer.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//

final class AppContainer {

    let apiKeyProvider: APIKeyProvider
    let newsAPI: NewsAPIClientProtocol
    let sourceSelectionStore: SourceSelectionStore
    let savedArticlesStore: SavedArticlesStore

    init() {
        self.apiKeyProvider = InfoPlistAPIKeyProvider()
        self.newsAPI = NewsAPIClient(apiKeyProvider: apiKeyProvider)
        self.sourceSelectionStore = UserDefaultsSourceSelectionStore()
        self.savedArticlesStore = FileSavedArticlesStore()
    }

    @MainActor
    func makeHeadlinesViewModel() -> HeadlinesViewModel {
        HeadlinesViewModel(
            client: newsAPI,
            selectionStore: sourceSelectionStore,
            savedStore: savedArticlesStore
        )
    }

    @MainActor
    func makeSourcesViewModel() -> SourcesViewModel {
        SourcesViewModel(
            client: newsAPI,
            selectionStore: sourceSelectionStore
        )
    }

    @MainActor
    func makeSavedViewModel() -> SavedViewModel {
        SavedViewModel(savedArticlesStore: savedArticlesStore)
    }
}
