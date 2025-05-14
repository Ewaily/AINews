//
//  AInewsApp.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import SwiftUI

@main
struct AINewsApp: App {
    @StateObject private var newsViewModel: NewsViewModel
    @State private var showSplash = true // State to control splash screen visibility
    @StateObject private var navigationManager = AppNavigationManager() // Add the navigation manager
    @StateObject private var preferencesService: UserPreferencesService // Removed inline initialization
    @State private var selectedTab: AppTab = .newsFeed // State to control TabView selection

    init() {
        let persistenceController = PersistenceController.shared
        let prefs = UserPreferencesService() // Create instance first
        _preferencesService = StateObject(wrappedValue: prefs) // Initialize StateObject
        // Initialize NewsViewModel with the managed object context and the created preferences service
        _newsViewModel = StateObject(wrappedValue: NewsViewModel(context: persistenceController.container.viewContext, preferencesService: prefs))
    }

    var body: some Scene {
        WindowGroup {
            ZStack { // Use a ZStack to overlay and switch views
                if showSplash {
                    SplashScreenView()
                        .onAppear {
                            // Simulate a delay for the splash screen
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { // Adjust delay as needed
                                withAnimation {
                                    self.showSplash = false
                                }
                            }
                        }
                } else {
                    // Main TabView for app content
                    TabView(selection: $selectedTab) { // Bind selection to selectedTab
                        NewsFeedView(viewModel: newsViewModel, preferencesService: preferencesService)
                            .tabItem {
                                Label("News Feed", systemImage: "newspaper")
                            }
                            .tag(AppTab.newsFeed) // Tag for selection

                        SavedArticlesView(viewModel: newsViewModel)
                            .tabItem {
                                Label("Bookmarks", systemImage: "bookmark.fill")
                            }
                            .tag(AppTab.bookmarks) // Tag for selection
                    }
                    .onAppear { // onAppear for TabView content setup
                        if newsViewModel.newsItems.isEmpty && !newsViewModel.isLoading && newsViewModel.errorMessage == nil {
                            newsViewModel.fetchNews()
                        }
                        newsViewModel.fetchSavedArticles()
                    }
                    // Moved onReceive outside of onAppear, applied directly to TabView
                    .onReceive(navigationManager.$activeTab) { tab in
                        if let tab = tab {
                            selectedTab = tab
                        }
                    }
                }
            }
            // Use the static shared instance for the environment as well
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            // Handle incoming NSUserActivity (which includes intents)
            // Using string identifiers as a fallback if static .identifier is not found
            .onContinueUserActivity("GetLatestNewsIntent") { userActivity in // Changed to string
                print("Continuing user activity for GetLatestNewsIntent")
                navigationManager.activeTab = .newsFeed
            }
            .onContinueUserActivity("ShowBookmarksIntent") { userActivity in // Changed to string
                print("Continuing user activity for ShowBookmarksIntent")
                navigationManager.activeTab = .bookmarks
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                 // Handle web links if your app supports them via Universal Links
            }
        }
        #if os(macOS)
        // You can add settings scene for macOS if needed
        // Settings {
        //     EmptyView() // Placeholder for settings view
        // }
        .windowStyle(DefaultWindowStyle()) // or .hiddenTitleBar.windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentMinSize) // Adjust as needed
        // Optionally set a default size for the macOS window on launch
        // .defaultSize(width: 600, height: 700)
        #endif
    }
}
