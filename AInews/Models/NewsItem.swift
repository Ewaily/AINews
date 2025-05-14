//
//  SignificanceLevel.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import SwiftUI

// Enum for Significance to make it type-safe
enum SignificanceLevel: String, Codable, CaseIterable {
    case HIGH
    case MEDIUM
    case LOW
    case UNKNOWN // Added for robustness in case of unexpected API values

    var color: Color {
        switch self {
        case .HIGH:
            return .red
        case .MEDIUM:
            return .orange
        case .LOW:
            return .blue
        case .UNKNOWN:
            return .gray
        }
    }

    // Icon for significance level
    var iconName: String {
        switch self {
        case .HIGH:
            return "flame.fill" // Example icon
        case .MEDIUM:
            return "exclamationmark.triangle.fill" // Example icon
        case .LOW:
            return "info.circle.fill" // Example icon
        case .UNKNOWN:
            return "questionmark.circle.fill" // Example icon
        }
    }
}

struct NewsItem: Codable, Identifiable {
    let id: Int
    let title: String
    let summary: String
    // The 'subreddit' field in JSON is a string like "[\"singularity\"]".
    // For simplicity, we'll decode it as String. If specific parsing is needed for the array elements,
    // a custom decoder or a computed property can be added later.
    let subreddit: String
    let post_id: String?
    let created_at: String? // ENSURE THIS IS OPTIONAL
    let date_posted: String? // MODIFIED: Made optional
    let tags: [String]
    let image: String? // URL for an image, optional
    let url: String // URL to the news source
    let usecases: [String]
    let significance: String // "HIGH", "MEDIUM", "LOW"
    let impact: String

    // Computed property to convert image string to URL
    var imageURL: URL? {
        guard let imageString = image else { return nil }
        return URL(string: imageString)
    }

    // To conform to Identifiable, 'id' is already unique.

    // Computed property to get SignificanceLevel enum
    var significanceEnum: SignificanceLevel {
        SignificanceLevel(rawValue: significance.uppercased()) ?? .UNKNOWN
    }

    // Computed property for a user-friendly display date
    var displayDate: String {
        guard let actualDatePosted = date_posted else {
            return "Unknown Date" // Or some other placeholder string
        }

        // Attempt to parse common date formats
        let inputFormatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }()
        ]

        for formatter in inputFormatters {
            if let date = formatter.date(from: actualDatePosted) {
                let outputFormatter = DateFormatter()
                outputFormatter.dateStyle = .medium
                outputFormatter.timeStyle = .none
                return outputFormatter.string(from: date)
            }
        }
        return actualDatePosted // Fallback to original string if parsing fails
    }
}
