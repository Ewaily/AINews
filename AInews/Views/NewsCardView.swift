//
//  NewsCardView.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import SwiftUI

struct NewsCardView: View {
    let newsItem: NewsItem
    @Environment(\.colorScheme) var colorScheme

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
                    
                    if newsItem.displayDate != "Unknown Date" {
                        Text(newsItem.displayDate)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }

                Text(newsItem.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(newsItem.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

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
                
                // "Read more" button with context menu
                if let url = URL(string: newsItem.url) {
                    Button(action: {
                        // Action for normal tap: open the URL
                        #if os(iOS)
                        UIApplication.shared.open(url)
                        #elseif os(macOS)
                        NSWorkspace.shared.open(url)
                        #endif
                    }) {
                        HStack {
                            Text("Read more")
                            Image(systemName: "arrow.up.right.square.fill")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.blue) // Consistent with previous fix
                    }
                    .contextMenu {
                        Button {
                            #if os(iOS)
                            UIApplication.shared.open(url)
                            #elseif os(macOS)
                            NSWorkspace.shared.open(url)
                            #endif
                        } label: {
                            Label("Open Link", systemImage: "safari")
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
                    // Removed .padding(.vertical, 6) and .padding(.top, 6) as VStack spacing handles it
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
        
        let previewItemMediumUnknownDate = NewsItem(
            id: 2,
            title: "Ethical Considerations in AI: A New Framework Proposed",
            summary: "A consortium of ethicists and AI developers has proposed a new framework for guiding the ethical development and deployment of artificial intelligence systems, aiming to address biases and ensure fairness.",
            subreddit: "[Ethics]", post_id: "p2", created_at: nil, date_posted: nil,
            tags: ["AI Ethics", "Framework", "Bias", "Fairness"],
            image: nil,
            url: "https://example.com", usecases: [], significance: "MEDIUM", impact: "Moderate"
        )

        return Group {
            NewsCardView(newsItem: previewItemHigh)
                .padding()
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .light)
                .previewDisplayName("Light Mode - With Date")

            NewsCardView(newsItem: previewItemMediumUnknownDate)
                .padding()
                .background(Color.black)
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode - Unknown Date")
        }
    }
}
