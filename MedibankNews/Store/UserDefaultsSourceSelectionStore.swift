//
//  UserDefaultsSourceSelectionStore.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import Foundation

final class UserDefaultsSourceSelectionStore: SourceSelectionStore {

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "selected_source_ids") {
        self.defaults = defaults
        self.key = key
    }

    var selectedSourceIDs: Set<String> {
        get {
            let array = defaults.stringArray(forKey: key) ?? []
            return Set(array)
        }
        set {
            defaults.set(Array(newValue).sorted(), forKey: key)
        }
    }
}
