//
//  InfoPlistAPIKeyProvider.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import Foundation

struct InfoPlistAPIKeyProvider: APIKeyProvider {
    var newsAPIKey: String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "NEWS_API_KEY") as? String,
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            assertionFailure("Missing NEWS_API_KEY in Info.plist")
            return ""
        }
        return value
    }
}
