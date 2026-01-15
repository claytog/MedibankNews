//
//  LoadState.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import Foundation

enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case empty(title: String, message: String)
    case failed(message: String)
}
