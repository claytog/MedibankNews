//
//  SavedArticlesStore.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//

protocol SavedArticlesStore {
    func load() -> [Article]
    func save(_ articles: [Article])
}
