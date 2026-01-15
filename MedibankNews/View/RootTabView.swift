//
//  RootTabView.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//
import SwiftUI

struct RootTabView: View {
    let container: AppContainer

    var body: some View {
        TabView {
            HeadlinesView(viewModel: container.makeHeadlinesViewModel())
                .tabItem {
                    Label(Constants.TabTitle.headlines, systemImage: "newspaper")
                }

            SourcesView(viewModel: container.makeSourcesViewModel())
                .tabItem {
                    Label(Constants.TabTitle.sources, systemImage: "line.3.horizontal.decrease.circle")
                }

            SavedView(viewModel: container.makeSavedViewModel())
                .tabItem {
                    Label(Constants.TabTitle.saved, systemImage: "bookmark")
                }
        }
    }
}

