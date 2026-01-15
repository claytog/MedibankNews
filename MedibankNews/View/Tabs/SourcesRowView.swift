//
//  SourcesRowView.swift
//  MedibankNews
//
//  Created by Clayton on 15/1/2026.
//
import SwiftUI

struct SourcesRowView: View {
    let source: Source
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(source.name)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
