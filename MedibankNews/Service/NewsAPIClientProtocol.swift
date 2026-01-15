//
//  NewsAPIClientProtocol.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import Foundation

protocol NewsAPIClientProtocol {
    func fetchSources() async throws -> [Source]
    func fetchHeadlines(sourceIDs: [String]) async throws -> [Article]
}
