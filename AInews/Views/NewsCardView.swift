//
//  NewsCardView.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import SwiftUI

struct NewsCardView: View {
    let newsItem: NewsItem
    @ObservedObject var viewModel: NewsViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingArticleDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: newsItem.imageURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image("placeholder")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: newsItem.significanceEnum.iconName)
                            .font(.caption.weight(.medium))
                        Text(newsItem.significanceEnum.rawValue)
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(newsItem.significanceEnum.color.opacity(colorScheme == .dark ? 0.3 : 0.2))
                    .foregroundColor(newsItem.significanceEnum.color)
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button {
                        if viewModel.isArticleSaved(articleID: newsItem.id) {
                            viewModel.unsaveArticle(articleID: newsItem.id)
                        } else {
                            viewModel.saveArticle(newsItem: newsItem)
                        }
                    } label: {
                        Image(systemName: viewModel.isArticleSaved(articleID: newsItem.id) ? "bookmark.fill" : "bookmark")
                            .font(.title2)
                            .foregroundColor(viewModel.isArticleSaved(articleID: newsItem.id) ? .accentColor : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.leading, 5)
                    .contentShape(Rectangle())
                }

                if newsItem.displayDate != "Unknown Date" {
                    Text(newsItem.displayDate)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)
                }

                Text(newsItem.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        #if os(iOS)
                        showingArticleDetail = true
                        #elseif os(macOS)
                        if let url = URL(string: newsItem.url) {
                            NSWorkspace.shared.open(url)
                        }
                        #endif
                    }
                
                #if os(iOS) || os(macOS)
                // Move AI Summary component to top position for prominence
                // Wrap in a non-interactive container to isolate touch events
                AISummaryView(newsItem: newsItem, viewModel: viewModel)
                    .padding(.vertical, 4)
                    // This prevents the summary view touches from propagating to parent views
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)
                #endif

                Text(newsItem.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        #if os(iOS)
                        showingArticleDetail = true
                        #elseif os(macOS)
                        if let url = URL(string: newsItem.url) {
                            NSWorkspace.shared.open(url)
                        }
                        #endif
                    }

                if !newsItem.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(newsItem.tags.prefix(4), id: \.self) { tag in
                                Text("#\(tag.trimmingCharacters(in: .whitespacesAndNewlines))")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(colorScheme == .dark ? 0.25 : 0.1))
                                    .clipShape(Capsule())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 28)
                }
                
                if let url = URL(string: newsItem.url) {
                    Button(action: {
                        #if os(iOS)
                        showingArticleDetail = true
                        #elseif os(macOS)
                        // On macOS, open in browser for now
                        if let nsUrl = URL(string: newsItem.url) {
                            NSWorkspace.shared.open(nsUrl)
                        }
                        #else
                        // On watchOS, do nothing or log that feature is unavailable
                        print("Article detail view not available on watchOS")
                        #endif
                    }) {
                        HStack {
                            Text("Read more")
                            Image(systemName: "arrow.up.right.square.fill")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    #if os(iOS) // Sheet for ArticleDetailView is iOS-only
                    .sheet(isPresented: $showingArticleDetail) {
                        ArticleDetailView(newsItem: newsItem, viewModel: viewModel)
                    }
                    #endif
                    // Updated contextMenu to be conditional for watchOS
                    #if os(iOS) || os(macOS)
                    .contextMenu {
                        Button {
                            #if os(iOS)
                            if let actualURL = URL(string: newsItem.url) { UIApplication.shared.open(actualURL) }
                            #elseif os(macOS)
                            if let actualURL = URL(string: newsItem.url) { NSWorkspace.shared.open(actualURL) }
                            #endif
                        } label: {
                            Label("Open in Browser", systemImage: "safari")
                        }

                        Button {
                            #if os(iOS)
                            UIPasteboard.general.string = newsItem.url
                            #elseif os(macOS)
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(newsItem.url, forType: .string)
                            #endif
                        } label: {
                            Label("Copy Link", systemImage: "doc.on.doc")
                        }
                    }
                    #else // watchOS - contextMenu might be different or not needed
                    // .contextMenu { Text("No actions available") } // Example for watchOS if needed
                    #endif
                }
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .background(.thinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(colorScheme == .dark ? 0.2 : 0.15), lineWidth: 1)
        )
    }
}

struct NewsCardView_Previews: PreviewProvider {
    static var previews: some View {
        let previewItemHigh = NewsItem(
            id: 1,
            title: "Groundbreaking AI Model Redefines Natural Language Understanding and it has a very long title to show how it wraps",
            summary: "This new model, developed by leading researchers, showcases unprecedented capabilities in understanding context, nuance, and even humor in human language. It's expected to revolutionize chatbots, translation services, and content generation.",
            subreddit: "[AI]", post_id: "p1", created_at: nil, date_posted: "2024-05-12",
            tags: ["AI Breakthrough", "NLP", "Machine Learning", "Innovation", "Deep Learning", "Research"],
            image: "https://picsum.photos/seed/ainews1/200/200",
            url: "https://example.com", usecases: [], significance: "HIGH", impact: "Huge"
        )
        
        let previewPreferencesService = UserPreferencesService()
        let previewViewModel = NewsViewModel(context: PersistenceController.preview.container.viewContext, preferencesService: previewPreferencesService)

        return Group {
            NewsCardView(newsItem: previewItemHigh, viewModel: previewViewModel)
                .padding()
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .light)
                .previewDisplayName("Light Mode - Not Saved")

            NewsCardView(newsItem: previewItemHigh, viewModel: previewViewModel)
                .padding()
                .background(Color.black)
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode - Potentially Saved")
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
