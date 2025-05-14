//
//  NewsViewModel.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import Foundation
import Combine
import CoreData

class NewsViewModel: ObservableObject {
    @Published var newsItems: [NewsItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var savedArticles: [SavedArticle] = []

    private var newsService = NewsService()
    private var cancellables = Set<AnyCancellable>()

    // Core Data Managed Object Context
    private var viewContext: NSManagedObjectContext

    // Updated Initializer to accept a ManagedObjectContext
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        // Fetch saved articles on init to have them available early
        // We might also call this when online fetching fails or after saving/unsaving.
        fetchSavedArticles()
    }
    
    // Convenience init for previews or testing, now also accepting a context
    convenience init(newsItems: [NewsItem] = [], isLoading: Bool = false, errorMessage: String? = nil, context: NSManagedObjectContext = PersistenceController.preview.container.viewContext) {
        self.init(context: context) // Call the designated initializer
        self.newsItems = newsItems
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }

    @MainActor
    func fetchNews() {
        isLoading = true
        errorMessage = nil

        newsService.fetchNews { [weak self] result in
            guard let self = self else { return }
            // Explicitly dispatch to main thread for UI updates from network completion
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let items):
                    self.newsItems = items.sorted(by: { (item1, item2) -> Bool in
                        guard let dateStr1 = item1.date_posted else { return false }
                        guard let dateStr2 = item2.date_posted else { return true }
                        return dateStr1 > dateStr2
                    })
                    // Optionally, refresh saved articles list if needed, though not strictly necessary here
                    // self.fetchSavedArticles()
                case .failure(let error):
                    self.errorMessage = "Failed to fetch news: \(error.localizedDescription)"
                    print("Error fetching news from ViewModel: \(error.localizedDescription)")
                    // If fetching news fails, try to load saved articles
                    self.fetchSavedArticles() // Now, if we are offline, saved articles will be shown
                }
            }
        }
    }
    
    @MainActor
    func refreshNews() {
        fetchNews()
    }

    // MARK: - Core Data Operations

    func isArticleSaved(articleID: Int) -> Bool {
        savedArticles.contains { $0.articleID == Int64(articleID) }
    }

    func saveArticle(newsItem: NewsItem) {
        guard !isArticleSaved(articleID: newsItem.id) else {
            print("Article with ID \(newsItem.id) is already saved.")
            return
        }

        let newSavedArticle = SavedArticle(context: viewContext)
        newSavedArticle.articleID = Int64(newsItem.id)
        newSavedArticle.title = newsItem.title
        newSavedArticle.summary = newsItem.summary
        newSavedArticle.urlString = newsItem.url
        newSavedArticle.imageURLString = newsItem.image
        newSavedArticle.datePostedString = newsItem.date_posted
        newSavedArticle.subreddit = newsItem.subreddit
        newSavedArticle.significance = newsItem.significance
        newSavedArticle.savedAt = Date()

        // Convert tags array to JSON string
        do {
            let tagsData = try JSONEncoder().encode(newsItem.tags)
            newSavedArticle.tagsJSON = String(data: tagsData, encoding: .utf8)
        } catch {
            print("Failed to encode tags: \(error.localizedDescription)")
            newSavedArticle.tagsJSON = "[]" // Default to empty JSON array on error
        }

        do {
            try viewContext.save()
            fetchSavedArticles() // Refresh the saved articles list
            print("Article '\(newsItem.title)' saved successfully.")
        } catch {
            let nsError = error as NSError
            // Consider more robust error handling for production
            print("Could not save article. \(nsError), \(nsError.userInfo)")
            // Optionally, remove the object from context if save failed to prevent inconsistent state
            // viewContext.delete(newSavedArticle)
        }
    }

    func unsaveArticle(articleID: Int) {
        guard let articleToUnsave = savedArticles.first(where: { $0.articleID == Int64(articleID) }) else {
            print("Could not find article with ID \(articleID) to unsave.")
            return
        }
        
        viewContext.delete(articleToUnsave)
        
        do {
            try viewContext.save()
            fetchSavedArticles() // Refresh the saved articles list
            print("Article with ID \(articleID) unsaved successfully.")
        } catch {
            let nsError = error as NSError
            // Consider more robust error handling
            print("Could not unsave article. \(nsError), \(nsError.userInfo)")
            // If save fails, you might want to re-fetch or handle the UI state
        }
    }

    func fetchSavedArticles() {
        let request = NSFetchRequest<SavedArticle>(entityName: "SavedArticle")
        // Temporarily remove sort descriptor for diagnostics
        // let sortDescriptor = NSSortDescriptor(keyPath: \SavedArticle.savedAt, ascending: false)
        // request.sortDescriptors = [sortDescriptor]
        
        do {
            savedArticles = try viewContext.fetch(request)
            print("Fetched \(savedArticles.count) saved articles.")
        } catch {
            print("Failed to fetch saved articles: \(error.localizedDescription)")
            // Handle the error appropriately, e.g., update UI to show an error state
            // errorMessage = "Could not load saved articles."
        }
    }
}
