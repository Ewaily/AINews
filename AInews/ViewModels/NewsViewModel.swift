//
//  NewsViewModel.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import Foundation
import Combine
import CoreData
import SwiftUI

class NewsViewModel: ObservableObject {
    @Published var newsItems: [NewsItem] = []
    @Published var filteredNewsItems: [NewsItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var savedArticles: [SavedArticle] = []

    private var newsService = NewsService()
    private var cancellables = Set<AnyCancellable>()

    // Core Data Managed Object Context
    private var viewContext: NSManagedObjectContext
    private let preferencesService: UserPreferencesService

    // Designated Initializer
    init(newsItems: [NewsItem] = [], isLoading: Bool = false, errorMessage: String? = nil, context: NSManagedObjectContext, preferencesService: UserPreferencesService) {
        self.newsItems = newsItems
        self.filteredNewsItems = [] // Initialize filteredNewsItems
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.viewContext = context
        self.preferencesService = preferencesService
        
        // Observe changes from preferencesService to re-filter news
        preferencesService.$preferences
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in // We get the new preferences, but just need to trigger a re-filter
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Initial filter application
        applyFilters()
        
        // Fetch saved articles on init to have them available early
        // We might also call this when online fetching fails or after saving/unsaving.
        fetchSavedArticles()
    }
    
    // Convenience init for general use (e.g., in AInewsApp)
    convenience init(context: NSManagedObjectContext, preferencesService: UserPreferencesService) {
        self.init(newsItems: [], isLoading: false, errorMessage: nil, context: context, preferencesService: preferencesService)
    }

    @MainActor
    func fetchNews(isRefresh: Bool = false) {
        if isRefresh {
            // Optionally clear items or handle refresh state differently
        }
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
                    // Instead of assigning to newsItems directly, or in addition, apply filters
                    self.applyFilters() // Apply filters after fetching new items
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
        fetchNews(isRefresh: true)
    }

    fileprivate func applyFilters() {
        let currentPreferences = preferencesService.preferences // Get current preferences
        
        if currentPreferences.followedTopics.isEmpty && 
           currentPreferences.mutedTopics.isEmpty && 
           currentPreferences.mutedSources.isEmpty {
            self.filteredNewsItems = self.newsItems // No filters, show all
            return
        }
        
        self.filteredNewsItems = self.newsItems.filter { item in
            // Muted Sources Check (Case-insensitive)
            if currentPreferences.mutedSources.contains(where: { item.subreddit.lowercased().contains($0) }) {
                return false // Item's source is muted
            }

            let itemContent = "\(item.title) \(item.summary) \(item.tags.joined(separator: " "))".lowercased()

            // Muted Topics/Keywords Check (Case-insensitive)
            if !currentPreferences.mutedTopics.isEmpty {
                if currentPreferences.mutedTopics.contains(where: { keyword in itemContent.contains(keyword) }) {
                    return false // Item contains a muted keyword
                }
            }
            
            // Followed Topics/Keywords Check (Case-insensitive)
            if !currentPreferences.followedTopics.isEmpty {
                if !currentPreferences.followedTopics.contains(where: { keyword in itemContent.contains(keyword) }) {
                    return false // Item does NOT contain any of the followed keywords, and followed list is not empty
                }
            }
            
            return true // Item passes all filters
        }
    }

    // MARK: - AI Summarization
    
    func generateAISummary(for newsItem: NewsItem, retryCount: Int = 0) {
        #if os(iOS) || os(macOS)
        // Check if we already have a summary or are generating one
        guard newsItem.aiSummary == nil && !newsItem.isGeneratingAISummary else {
            return
        }
        
        // Find the index of the newsItem in the arrays
        guard let index = newsItems.firstIndex(where: { $0.id == newsItem.id }) else {
            return
        }
        
        // Flag that we're generating a summary
        newsItems[index].isGeneratingAISummary = true
        
        // Also update in filteredNewsItems if present
        if let filteredIndex = filteredNewsItems.firstIndex(where: { $0.id == newsItem.id }) {
            filteredNewsItems[filteredIndex].isGeneratingAISummary = true
        }
        
        // Trigger UI update
        objectWillChange.send()
        
        // Generate the summary
        ArticleSummarizer.shared.summarizeArticleFromURL(newsItem.url) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Find the index again as it might have changed
                guard let index = self.newsItems.firstIndex(where: { $0.id == newsItem.id }) else {
                    return
                }
                
                switch result {
                case .success(let summary):
                    // Check if the summary contains CSS styling code or other garbage
                    let containsCSSPatterns = summary.contains(":first-child") || 
                                              summary.contains("[&>") || 
                                              summary.contains("h-full") ||
                                              summary.contains("w-full") ||
                                              summary.contains("overflow-hidden") ||
                                              summary.range(of: "\\[&>:[^]]*\\]", options: .regularExpression) != nil
                    
                    if containsCSSPatterns || summary.count < 20 {
                        // If the summary contains CSS patterns or is too short, mark as failed and retry
                        print("Summary contains CSS patterns or is too short - retrying")
                        
                        let maxRetries = 2
                        if retryCount < maxRetries {
                            // Retry with different approach
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                self?.generateAISummary(for: newsItem, retryCount: retryCount + 1)
                            }
                            return
                        } else {
                            // Max retries exceeded, use fallback message
                            self.newsItems[index].isGeneratingAISummary = false
                            self.newsItems[index].aiSummary = "Unable to generate a high-quality summary for this article format."
                        }
                    } else {
                        // Set the AI summary for valid result
                        self.newsItems[index].isGeneratingAISummary = false
                        self.newsItems[index].aiSummary = summary
                    }
                    
                    // Also update in filteredNewsItems if present
                    if let filteredIndex = self.filteredNewsItems.firstIndex(where: { $0.id == newsItem.id }) {
                        self.filteredNewsItems[filteredIndex].isGeneratingAISummary = false
                        self.filteredNewsItems[filteredIndex].aiSummary = self.newsItems[index].aiSummary
                    }
                case .failure(let error):
                    // If we haven't exceeded max retries, try again with a delay
                    let maxRetries = 2
                    if retryCount < maxRetries {
                        print("Failed to generate AI summary (attempt \(retryCount + 1) of \(maxRetries + 1)): \(error.localizedDescription)")
                        print("Retrying in 1 second...")
                        
                        // Keep the generating state on
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            self?.generateAISummary(for: newsItem, retryCount: retryCount + 1)
                        }
                        return
                    }
                    
                    // Max retries exceeded, update state to reflect failure
                    print("Failed to generate AI summary after \(maxRetries + 1) attempts: \(error.localizedDescription)")
                    
                    self.newsItems[index].isGeneratingAISummary = false
                    // Set a fallback summary to indicate the failure
                    if let articleSummarizerError = error as? ArticleSummarizer.SummarizerError, 
                       articleSummarizerError == ArticleSummarizer.SummarizerError.preprocessingError {
                        self.newsItems[index].aiSummary = "This content cannot be summarized. It may be an image or unsupported format."
                    } else {
                        self.newsItems[index].aiSummary = "Unable to generate summary. The article format may not be compatible."
                    }
                    
                    // Also update in filteredNewsItems if present
                    if let filteredIndex = self.filteredNewsItems.firstIndex(where: { $0.id == newsItem.id }) {
                        self.filteredNewsItems[filteredIndex].isGeneratingAISummary = false
                        self.filteredNewsItems[filteredIndex].aiSummary = self.newsItems[index].aiSummary
                    }
                }
                
                // Trigger UI update
                self.objectWillChange.send()
            }
        }
        #else
        // watchOS implementation - do nothing or show error
        print("AI summary generation not supported on this platform")
        #endif
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

#if DEBUG // Only compile PreviewNewsViewModel for Debug builds (where Previews are used)
// Now update the PreviewNewsViewModel to also accept and pass preferencesService
class PreviewNewsViewModel: NewsViewModel {
    // This convenience init is the primary way to set up PreviewNewsViewModel
    convenience init(context: NSManagedObjectContext = PersistenceController.preview.container.viewContext, 
                     preferencesService: UserPreferencesService = UserPreferencesService(), 
                     isLoading: Bool = false, 
                     errorMessage: String? = nil, 
                     items: [NewsItem]? = nil) {
        let defaultItems = [
            NewsItem(id: 1, title: "Preview: Exciting AI News with topic_alpha", summary: "Summary of exciting AI news for preview...", subreddit: "[AI]", post_id: "p1", created_at: "2023-01-01T12:00:00Z", date_posted: "2023-01-01", tags: ["AI", "ML", "topic_alpha"], image: nil, url: "http://example.com", usecases: ["GenAI"], significance: "HIGH", impact: "Big impact."),
            NewsItem(id: 2, title: "Preview: Another AI Update with topic_beta", summary: "More AI updates for preview...", subreddit: "[Tech]", post_id: "p2", created_at: "2023-01-02T12:00:00Z", date_posted: "2023-01-02", tags: ["Tech", "Update", "topic_beta"], image: nil, url: "http://example.com", usecases: ["Automation"], significance: "MEDIUM", impact: "Medium impact."),
            NewsItem(id: 3, title: "News about a Muted Source", summary: "Content from a source that might be muted.", subreddit: "[MutedSourceExample]", post_id: "p3", created_at: "2023-01-01T12:00:00Z", date_posted: "2023-01-01", tags: ["AI"], image: nil, url: "http://example.com", usecases: [], significance: "LOW", impact: "Low impact.")
        ]
        // Calls the designated initializer of the superclass (NewsViewModel)
        self.init(newsItems: items ?? defaultItems, isLoading: isLoading, errorMessage: errorMessage, context: context, preferencesService: preferencesService)
    }
    
    // Override fetchNews and refreshNews for preview specific behavior (no network calls)
    @MainActor
    override func fetchNews(isRefresh: Bool = false) { 
        print("PreviewNewsViewModel: fetchNews() called, network request disabled.")
        self.isLoading = true // Simulate loading start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Simulate delay
            self.isLoading = false
            self.applyFilters() // Apply filters after simulated load
        }
    }

    @MainActor
    override func refreshNews() {
        print("PreviewNewsViewModel: refreshNews() called, network request disabled.")
        self.isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            self.applyFilters()
        }
    }
}
#endif // DEBUG
