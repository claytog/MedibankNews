//
//  SourceSelectionStore.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//

protocol SourceSelectionStore {
    var selectedSourceIDs: Set<String> { get set }
}
