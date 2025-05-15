import SwiftUI

struct AISummaryView: View {
    let newsItem: NewsItem
    @ObservedObject var viewModel: NewsViewModel
    @State private var isExpanded = true
    @State private var retryCount = 0
    
    // Check if the summary indicates a failure
    private var isSummaryFailed: Bool {
        newsItem.aiSummary?.starts(with: "Unable to generate summary") ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with badge
            HStack {
                // AI Badge
                HStack(spacing: 6) {
                    Image(systemName: isSummaryFailed ? "exclamationmark.triangle" : "brain.head.profile")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(isSummaryFailed ? "AI Summary Failed" : "Summarized by On-Device AI")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSummaryFailed ? Color.orange : Color.purple)
                .clipShape(Capsule())
                
                Spacer()
                
                // Only show the expand/collapse button if we have a summary
                if newsItem.aiSummary != nil {
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Tapping the header toggles the expanded state directly
                withAnimation {
                    isExpanded.toggle()
                }
            }
            
            // Summary content
            if isExpanded {
                if let summary = newsItem.aiSummary {
                    VStack(alignment: .leading, spacing: 12) {
                        // Show the AI summary
                        Text(summary)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // If it's a failed summary, show retry button
                        if isSummaryFailed {
                            Button {
                                retryCount += 1
                                // Clear the failed summary and retry
                                if let index = viewModel.newsItems.firstIndex(where: { $0.id == newsItem.id }) {
                                    viewModel.newsItems[index].aiSummary = nil
                                }
                                if let index = viewModel.filteredNewsItems.firstIndex(where: { $0.id == newsItem.id }) {
                                    viewModel.filteredNewsItems[index].aiSummary = nil
                                }
                                viewModel.generateAISummary(for: newsItem)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry Summary")
                                    Spacer()
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(.blue)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .disabled(newsItem.isGeneratingAISummary)
                        }
                    }
                    .transition(.opacity)
                    .contentShape(Rectangle())
                } else if newsItem.isGeneratingAISummary {
                    // Show loading state
                    VStack(spacing: 10) {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("Generating AI summary...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 12)
                    .transition(.opacity)
                    .contentShape(Rectangle())
                } else {
                    // Show generation button
                    Button {
                        viewModel.generateAISummary(for: newsItem)
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.headline)
                            Text("Generate AI Summary")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.purple)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .transition(.opacity)
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.07))
        .cornerRadius(12)
    }
}

struct AISummaryView_Previews: PreviewProvider {
    static var previews: some View {
        let previewPreferencesService = UserPreferencesService()
        let previewViewModel = NewsViewModel(context: PersistenceController.preview.container.viewContext, preferencesService: previewPreferencesService)
        
        func makeDefaultView() -> some View {
            let item = NewsItem(
                id: 1,
                title: "Test Article",
                summary: "This is a test article",
                subreddit: "[AI]",
                post_id: "p1",
                created_at: nil,
                date_posted: "2024-05-13",
                tags: ["AI"],
                image: nil,
                url: "https://example.com",
                usecases: [],
                significance: "HIGH",
                impact: "High"
            )
            
            return AISummaryView(newsItem: item, viewModel: previewViewModel)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Default State")
        }
        
        func makeViewWithSummary() -> some View {
            var item = NewsItem(
                id: 2,
                title: "Test Article with Summary",
                summary: "This is a test article",
                subreddit: "[AI]",
                post_id: "p1",
                created_at: nil,
                date_posted: "2024-05-13",
                tags: ["AI"],
                image: nil,
                url: "https://example.com",
                usecases: [],
                significance: "HIGH",
                impact: "High"
            )
            item.aiSummary = "This is an AI-generated summary of the article that provides a quick overview of the key points. It analyzes the content using on-device machine learning technology and natural language processing to extract the most important information."
            
            return AISummaryView(newsItem: item, viewModel: previewViewModel)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("With AI Summary")
        }
        
        func makeGeneratingView() -> some View {
            var item = NewsItem(
                id: 3,
                title: "Test Article Generating",
                summary: "This is a test article",
                subreddit: "[AI]",
                post_id: "p1",
                created_at: nil,
                date_posted: "2024-05-13",
                tags: ["AI"],
                image: nil,
                url: "https://example.com",
                usecases: [],
                significance: "HIGH",
                impact: "High"
            )
            item.isGeneratingAISummary = true
            
            return AISummaryView(newsItem: item, viewModel: previewViewModel)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Loading State")
        }
        
        return Group {
            makeDefaultView()
            makeViewWithSummary()
            makeGeneratingView()
        }
    }
} 