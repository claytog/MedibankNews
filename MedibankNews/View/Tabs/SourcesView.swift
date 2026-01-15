//
//  SourcesView.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import SwiftUI

struct SourcesView: View {
    @ObservedObject var viewModel: SourcesViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView()

                case .empty(let title, let message):
                    EmptyStateView(title: title, message: message)

                case .failed(let message):
                    EmptyStateView(title: "Error", message: message)

                case .loaded:
                    List(viewModel.sources) { source in
                        SourcesRowView(source: source,
                                isSelected: viewModel.isSelected(source),
                                onToggle: {
                                    viewModel.toggle(source)
                                }
                            )
                    }
                }
            }
            .navigationTitle(Constants.TabTitle.sources)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") { viewModel.clearSelection() }
                        .disabled(viewModel.selectedCount == 0)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
