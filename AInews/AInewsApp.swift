//
//  AInewsApp.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import SwiftUI

@main
struct AINewsApp: App {
    @StateObject private var newsViewModel = NewsViewModel()
    @State private var showSplash = true // State to control splash screen visibility

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
                    NewsFeedView(viewModel: newsViewModel)
                        .onAppear {
                            // Fetch news only if not already loaded and no error
                            if newsViewModel.newsItems.isEmpty && !newsViewModel.isLoading && newsViewModel.errorMessage == nil {
                                newsViewModel.fetchNews()
                            }
                        }
                }
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
