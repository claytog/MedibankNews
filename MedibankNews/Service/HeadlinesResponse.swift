//
//  HeadlinesResponse.swift
//  MedibankNews
//
//  Created by Clayton on 15/1/2026.
//

struct HeadlinesResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [Article]
}
