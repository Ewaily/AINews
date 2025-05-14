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
    // Initialize the NewsViewModel.
    // For the watch, we use a preview/in-memory context as it doesn't share the main app's CoreData store directly yet.
    // True offline/synced saved articles on watch would require WatchConnectivity.
    @StateObject var viewModel = NewsViewModel(context: PersistenceController.preview.container.viewContext)

    var body: some View {
        // Display the NewsFeedView
        // If NewsFeedView is not part of the watch target, this will cause an error.
        NewsFeedView(viewModel: viewModel)
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
    // For the preview, we can also pass a ViewModel,
    // potentially a PreviewNewsViewModel if you have one configured for watch previews.
    // For simplicity now, just using ContentView().
    ContentView()
}
