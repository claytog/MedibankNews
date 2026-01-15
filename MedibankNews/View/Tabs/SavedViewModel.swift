//
//  SavedViewModel.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import Foundation

@MainActor
final class SavedViewModel: ObservableObject {
    @Published var saved: [Article] = []
    @Published var selectedArticle: Article? = nil

    private let savedArticlesStore: SavedArticlesStore

    init(savedArticlesStore: SavedArticlesStore) {
        self.savedArticlesStore = savedArticlesStore
    }

    func deleteArticle(at offsets: IndexSet) {
        saved.remove(atOffsets: offsets)
        savedArticlesStore.save(saved)
    }
    
    func isArticleSaved(_ article: Article) -> Bool {
        saved.contains(where: { $0.id == article.id })
    }
    
    func loadArticle() {
        saved = savedArticlesStore.load()
    }

    func openArticle(_ article: Article) {
        selectedArticle = article
    }

    func toggleSavedArticle(_ article: Article) {
        if let idx = saved.firstIndex(where: { $0.id == article.id }) {
            saved.remove(at: idx)
        } else {
            saved.insert(article, at: 0)
        }
        savedArticlesStore.save(saved)
    }
}
