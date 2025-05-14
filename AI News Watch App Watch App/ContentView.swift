//
//  ContentView.swift
//  AI News Watch App Watch App
//
//  Created by Muhammad Ewaily on 14/05/2025.
//

import SwiftUI

// We need to ensure NewsFeedView and NewsViewModel are accessible here.
// This might require adding them to the Watch App's target membership in Xcode.

struct ContentView: View {
    @ObservedObject var preferencesService: UserPreferencesService
    @StateObject var viewModel: NewsViewModel

    init(preferencesService: UserPreferencesService) {
        self.preferencesService = preferencesService
        // Initialize viewModel with the context and the passed-in preferencesService
        _viewModel = StateObject(wrappedValue: NewsViewModel(context: PersistenceController.preview.container.viewContext, preferencesService: preferencesService))
    }

    var body: some View {
        // Display the NewsFeedView
        // If NewsFeedView is not part of the watch target, this will cause an error.
        NewsFeedView(viewModel: viewModel, preferencesService: preferencesService)
        // It's good practice to fetch news when the view appears on the watch as well.
        .onAppear {
            // Check if data is already loaded or loading to avoid redundant fetches
            if viewModel.newsItems.isEmpty && !viewModel.isLoading && viewModel.errorMessage == nil {
                viewModel.fetchNews()
            }
        }
    }
}

#Preview {
    // For preview, ensure preferencesService is provided.
    // If UserPreferencesService has a simple init(), this is fine.
    ContentView(preferencesService: UserPreferencesService())
}
