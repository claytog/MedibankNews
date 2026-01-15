//
//  EmptyStateView.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    init(title: String, message: String, systemImage: String = "info.circle") {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(message)
        )
        .padding()
    }
}
