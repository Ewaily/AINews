//
//  NewsViewModel.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import Foundation
import Combine

class NewsViewModel: ObservableObject {
    @Published var newsItems: [NewsItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var newsService = NewsService()
    private var cancellables = Set<AnyCancellable>()

    // Default initializer for the app
    init() {}
    
    // Convenience init for previews or testing if needed
    init(newsItems: [NewsItem] = [], isLoading: Bool = false, errorMessage: String? = nil) {
        self.newsItems = newsItems
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        // Note: newsService will use the default initializer in this case.
    }

    @MainActor
    func fetchNews() {
        isLoading = true
        errorMessage = nil

        newsService.fetchNews { [weak self] result in
            // Explicitly dispatch to main thread for UI updates from network completion
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let items):
                    // Sort by date_posted (String?), newest first.
                    // Treat items with nil date_posted as older than any item with a date.
                    self.newsItems = items.sorted(by: { (item1, item2) -> Bool in
                        guard let dateStr1 = item1.date_posted else {
                            return false // item1 is older if its date is nil (unless item2's is also nil)
                        }
                        guard let dateStr2 = item2.date_posted else {
                            return true // item1 is newer if item2's date is nil and item1's is not
                        }
                        return dateStr1 > dateStr2 // Compare non-nil date strings
                    })
                case .failure(let error):
                    self.errorMessage = "Failed to fetch news: \(error.localizedDescription)"
                    print("Error fetching news from ViewModel: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @MainActor
    func refreshNews() {
        fetchNews()
    }
}
