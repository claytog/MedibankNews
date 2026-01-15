//
//  Article.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import Foundation

struct Article: Codable, Identifiable, Hashable {

    let id: String
    let url: URL
    let title: String
    let author: String?
    let description: String?
    let urlToImage: URL?
    let publishedAt: Date?
    let content: String?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case title
        case author
        case description
        case urlToImage
        case publishedAt
        case content
    }

    init(
        id: String? = nil,
        url: URL,
        title: String,
        author: String? = nil,
        description: String? = nil,
        urlToImage: URL? = nil,
        publishedAt: Date? = nil,
        content: String? = nil
    ) {
        self.url = url
        self.id = (id?.isEmpty == false) ? id! : url.absoluteString
        self.title = title
        self.author = author
        self.description = description
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.content = content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        url = try container.decode(URL.self, forKey: .url)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        urlToImage = try container.decodeIfPresent(URL.self, forKey: .urlToImage)
        publishedAt = try container.decodeIfPresent(Date.self, forKey: .publishedAt)
        content = try container.decodeIfPresent(String.self, forKey: .content)

        let decodedId = try container.decodeIfPresent(String.self, forKey: .id)
        id = (decodedId?.isEmpty == false) ? decodedId! : url.absoluteString
    }
}
