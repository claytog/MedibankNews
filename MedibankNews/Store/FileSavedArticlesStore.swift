//
//  FileSavedArticlesStore.swift
//  MedibankNews
//
//  Created by Clayton on 15/1/2026.
//
import Foundation

final class FileSavedArticlesStore: SavedArticlesStore {

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileName: String = "saved_articles.json", baseDirectory: URL? = nil) {
        let directory = baseDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        self.fileURL = directory.appendingPathComponent(fileName)
        self.encoder = APINewsCoding.makeEncoder()
        self.decoder = APINewsCoding.makeDecoder()
    }

    func load() -> [Article] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([Article].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ articles: [Article]) {
        do {
            try ensureDirectoryExists()
            let data = try encoder.encode(articles)
            try data.write(to: fileURL, options: [.atomic])
            #if DEBUG
            print("Saving to:", fileURL.path)
            #endif
        } catch {
            #if DEBUG
            print("FileSavedArticlesStore save failed:", error)
            #endif
        }
    }

    private func ensureDirectoryExists() throws {
        let dir = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
}
