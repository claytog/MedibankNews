//
//  HeadlinesView.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import SwiftUI

struct HeadlinesView: View {
    @ObservedObject var viewModel: HeadlinesViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView()
                    
                case .empty(let title, let message):
                    EmptyStateView(title: title, message: message)

                case .failed(let message):
                    EmptyStateView(title: Constants.Error.heading, message: message)

                case .loaded:
                    List(viewModel.articles) { article in
                        ArticleRowView(article: article, isSaved: viewModel.isSavedArticle(article), onSave: { viewModel.toggleSavedArticle(article) })
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.openArticle(article)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(Constants.TabTitle.headlines)
        }
        .task {
            viewModel.refreshSavedArticleIDs()
            await viewModel.loadArticles()
        }
    }
}
