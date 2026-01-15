//
//  ArticlesResponse.swift
//  MedibankNews
//
//  Created by Clayton on 15/1/2026.
//

struct ArticlesResponse: Decodable {
    let status: String
    let totalResults: Int?
    let articles: [Article]
}
