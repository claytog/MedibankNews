//
//  SavedView.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import SwiftUI

struct SavedView: View {
    @ObservedObject var viewModel: SavedViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.saved.isEmpty {
                    EmptyStateView(title: Constants.Articles.noSavedHeading, message: Constants.Articles.noSavedMessage)
                } else {
                    List {
                        ForEach(viewModel.saved) { article in
                            ArticleRowView(article: article, isSaved: viewModel.isArticleSaved(article), onSave: { viewModel.toggleSavedArticle(article) })
                            .contentShape(Rectangle())
                            .onTapGesture { viewModel.openArticle(article) }
                        }
                        .onDelete { offsets in
                            viewModel.deleteArticle(at: offsets)
                        }

                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(Constants.TabTitle.saved)
        }
        .sheet(item: $viewModel.selectedArticle) { article in
            SafariView(url: article.url)
        }
        .onAppear { viewModel.loadArticle() }
    }
}
