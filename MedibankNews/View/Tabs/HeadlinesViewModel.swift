//
//  HeadlinesViewModel.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import Foundation

@MainActor
final class HeadlinesViewModel: ObservableObject {

    @Published var state: LoadState = .idle
    @Published var articles: [Article] = []
    @Published var selectedArticleURL: URL? = nil
    @Published private(set) var savedArticleIDs: Set<String> = []

    private let client: NewsAPIClientProtocol
    private let selectionStore: SourceSelectionStore
    private let savedStore: SavedArticlesStore

    init(client: NewsAPIClientProtocol, selectionStore: SourceSelectionStore, savedStore: SavedArticlesStore) {
        self.client = client
        self.selectionStore = selectionStore
        self.savedStore = savedStore
        self.savedArticleIDs = Set(savedStore.load().map(\.id))
    }
    
    func isSavedArticle(_ article: Article) -> Bool {
        savedArticleIDs.contains(article.id)
    }

    func loadArticles() async {
        savedArticleIDs = Set(savedStore.load().map(\.id))

        let selectedIDs = Array(selectionStore.selectedSourceIDs)
        guard !selectedIDs.isEmpty else {
            articles = []
            state = .empty(title: "No Sources Selected", message: "Go to Sources and select one or more sources.")
            return
        }
        
        state = .loading
        do {
            let fetched = try await client.fetchHeadlines(sourceIDs: selectedIDs)
            articles = fetched
            state = fetched.isEmpty ? .empty(title: "No Results", message: "No articles were returned for the selected sources.") : .loaded
        } catch {
            articles = []
            state = .failed(message: error.localizedDescription)
        }
    }
    
    func saveArticle(_ article: Article) {
        guard !savedArticleIDs.contains(article.id) else { return }

        var current = savedStore.load()
        current.insert(article, at: 0)
        savedStore.save(current)
        savedArticleIDs.insert(article.id)
    }
    
    func openArticle(_ article: Article) {
        selectedArticleURL = article.url
    }
    
    func refreshSavedArticleIDs() {
        savedArticleIDs = Set(savedStore.load().map(\.id))
    }

    func toggleSavedArticle(_ article: Article) {
        var current = savedStore.load()

        if savedArticleIDs.contains(article.id) { // Unsave
            current.removeAll { $0.id == article.id }
            savedStore.save(current)
            savedArticleIDs.remove(article.id)
        } else { // Save
            current.insert(article, at: 0)
            savedStore.save(current)
            savedArticleIDs.insert(article.id)
        }
    }

}
