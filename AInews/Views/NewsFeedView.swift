//
//  NewsFeedView.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import SwiftUI

struct NewsFeedView: View {
    @StateObject var viewModel: NewsViewModel

    // Initializer to allow injecting viewModel, defaulting to a new one for app use
    init(viewModel: NewsViewModel = NewsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                #if os(iOS)
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                #else // macOS
                // On macOS, the default window background is usually fine.
                // You could use Color(NSColor.windowBackgroundColor) if a specific color is desired.
                #endif

                Group {
                    if viewModel.isLoading && viewModel.newsItems.isEmpty {
                        ProgressView("Loading News...")
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.orange)
                            Text("Oops! Something went wrong.")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button {
                                viewModel.fetchNews()
                            } label: {
                                Text("Retry")
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.accentColor)
                                    .foregroundColor(Color.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding()
                    } else if viewModel.newsItems.isEmpty {
                        VStack(spacing: 16) {
                             Image(systemName: "newspaper.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.secondary)
                            Text("No News Yet")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Check back later for the latest AI developer news.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(viewModel.newsItems) { item in
                                NewsCardView(newsItem: item)
                                    .listRowInsets(EdgeInsets(top: 8, leading: horizontalPadding, bottom: 8, trailing: horizontalPadding))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                            // Section for Copyright Footer
                            Section {
                                // Empty content for the section, we only need the footer
                            } footer: {
                                Text("© \(currentYear) TrianglZ LLC. All rights reserved.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 20) // Add some space above the copyright
                                    .padding(.bottom, 10) // Add some space below
                            }
                        }
                        .listStyle(.plain)
                        #if os(iOS)
                        .refreshable {
                            await Task {
                                viewModel.refreshNews()
                            }.value
                        }
                        #endif
                    }
                }
            }
            .navigationTitle("AI Developer News")
            #if os(macOS)
            .frame(minWidth: 450, idealWidth: 600, maxWidth: .infinity, minHeight: 400, idealHeight: 700, maxHeight: .infinity)
            #endif
        }
        #if os(iOS)
        .navigationViewStyle(.automatic) // Adapts to iPhone/iPad
        #endif
    }
    
    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }

    private var horizontalPadding: CGFloat {
        #if os(macOS)
        return 16
        #else
        return 0
        #endif
    }
}

// Dedicated ViewModel for Previews to avoid actual network calls during design time
class PreviewNewsViewModel: NewsViewModel {
    convenience init(isLoading: Bool = false, errorMessage: String? = nil, items: [NewsItem]? = nil) {
        let defaultItems = [
            NewsItem(id: 1, title: "Preview: Exciting AI News", summary: "Summary of exciting AI news for preview...", subreddit: "[AI]", post_id: "p1", created_at: "2023-01-01T12:00:00Z", date_posted: "2023-01-01", tags: ["AI", "ML"], image: nil, url: "http://example.com", usecases: ["GenAI"], significance: "HIGH", impact: "Big impact."),
            NewsItem(id: 2, title: "Preview: Another AI Update", summary: "More AI updates for preview...", subreddit: "[Tech]", post_id: "p2", created_at: "2023-01-02T12:00:00Z", date_posted: "2023-01-02", tags: ["Tech", "Update"], image: nil, url: "http://example.com", usecases: ["Automation"], significance: "MEDIUM", impact: "Medium impact.")
        ]
        // Call the designated initializer of the superclass
        self.init(newsItems: items ?? defaultItems, isLoading: isLoading, errorMessage: errorMessage)
    }
    
    // Override to prevent network calls in previews
    override func fetchNews() {
        print("PreviewNewsViewModel: fetchNews() called, but network request is disabled for previews.")
    }
    override func refreshNews() {
        print("PreviewNewsViewModel: refreshNews() called, but network request is disabled for previews.")
    }
}

struct NewsFeedView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NewsFeedView(viewModel: PreviewNewsViewModel(items: nil))
                .environment(\.colorScheme, .light)
                .previewDisplayName("Light Mode - With Data")
            
            NewsFeedView(viewModel: PreviewNewsViewModel(items: nil))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode - With Data")

            NewsFeedView(viewModel: PreviewNewsViewModel(items: []))
                .previewDisplayName("Empty State")

            NewsFeedView(viewModel: PreviewNewsViewModel(isLoading: true, items: []))
                .previewDisplayName("Loading State")

            NewsFeedView(viewModel: PreviewNewsViewModel(errorMessage: "Could not connect. Please check internet.", items: []))
                .previewDisplayName("Error State")
        }
    }
} 
