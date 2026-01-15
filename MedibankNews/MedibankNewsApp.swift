//
//  MedibankNewsApp.swift
//  MedibankNews
//
//  Created by Clayton on 14/1/2026.
//

import SwiftUI

@main
struct MedibankNewsApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootTabView(container: container)
        }
    }
}
