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
        VStack(alignment: .leading, spacing: 10) {
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
            .padding(.bottom, 2)

            Text(newsItem.title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(3)

            Text(newsItem.summary)
                .font(.callout)
                .foregroundColor(.secondary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)

            if !newsItem.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(newsItem.tags.prefix(6), id: \.self) { tag in
                            Text("#\(tag.trimmingCharacters(in: .whitespacesAndNewlines))")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.gray.opacity(colorScheme == .dark ? 0.25 : 0.1))
                                .clipShape(Capsule())
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 32)
                .padding(.top, 6)
            }
            
            if let url = URL(string: newsItem.url) {
                Link(destination: url) {
                    HStack {
                        Text("Read more")
                        Image(systemName: "arrow.up.right.square.fill")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.accentColor)
                    .padding(.vertical, 6)
                }
                .padding(.top, 6)
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
            image: nil, url: "https://example.com", usecases: [], significance: "HIGH", impact: "Huge"
        )
        
        let previewItemMediumUnknownDate = NewsItem(
            id: 2,
            title: "Ethical Considerations in AI: A New Framework Proposed",
            summary: "A consortium of ethicists and AI developers has proposed a new framework for guiding the ethical development and deployment of artificial intelligence systems, aiming to address biases and ensure fairness.",
            subreddit: "[Ethics]", post_id: "p2", created_at: nil, date_posted: nil,
            tags: ["AI Ethics", "Framework", "Bias", "Fairness"],
            image: nil, url: "https://example.com", usecases: [], significance: "MEDIUM", impact: "Moderate"
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
