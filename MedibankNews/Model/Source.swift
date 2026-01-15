//
//  Source.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import Foundation

struct Source: Identifiable, Codable, Equatable {

    let id: String
    let name: String
    let description: String?
    let url: URL?
    let category: String?
    let language: String?
    let country: String?
}
