//
//  AI_News_Watch_AppApp.swift
//  AI News Watch App Watch App
//
//  Created by Muhammad Ewaily on 14/05/2025.
//

import SwiftUI

@main
struct AI_News_Watch_App_Watch_AppApp: App {
    @StateObject private var preferencesService = UserPreferencesService()

    var body: some Scene {
        WindowGroup {
            ContentView(preferencesService: preferencesService)
        }
    }
}
