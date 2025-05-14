#if os(iOS) || os(macOS)

#if os(iOS) // UIKit is only available on iOS
import UIKit
#endif
import LinkPresentation // For richer previews in some activities like Messages

#if os(iOS) // ArticleActivityItemSource and its UIKit dependencies are iOS-only
class ArticleActivityItemSource: NSObject, UIActivityItemSource {
    private let title: String
    private let url: URL
    private let summary: String? // Optional summary for richer previews

    init(title: String, url: URL, summary: String? = nil) {
        self.title = title
        self.url = url
        self.summary = summary
        super.init()
    }

    // MARK: - UIActivityItemSource

    // Placeholder item returned when the share sheet is gathering information.
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return title // Or url, a simple placeholder
    }

    // The actual item to be shared.
    // This is where we customize based on activityType.
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        guard let activityType = activityType else {
            // Default representation if activityType is nil (shouldn't usually happen for common shares)
            return "\(title) - \(url.absoluteString)"
        }

        switch activityType {
        case .postToTwitter, .postToFacebook, UIActivity.ActivityType(rawValue: "com.atebits.Tweetie2.compose"), UIActivity.ActivityType(rawValue: "com.facebook.Facebook.ShareExtension"), UIActivity.ActivityType(rawValue: "com.apple.social.twitter"), UIActivity.ActivityType(rawValue: "com.apple.social.facebook"): // Add other social media if needed
            // For social media, a concise message might be better.
            // You could add hashtags here too.
            return "Check out this article: \(title) \(url.absoluteString) #AINews"
        case .mail:
            // For email, we can provide a more detailed body.
            // The subject will be handled by activityViewController:subjectForActivityType:
            return "I thought you might be interested in this article: \(title)\n\n\(url.absoluteString)\n\nSummary: \(summary ?? "N/A")"
        case .message: // iMessage
            // For iMessage, just the URL often results in a rich link preview automatically (LPLinkMetadata).
            // If we return a string, it might override the rich preview.
            // Returning the URL directly is often best for Messages.
            return url
        case .copyToPasteboard:
            return url.absoluteString
        default:
            // Generic case: title and URL
            return "\(title) - \(url.absoluteString)"
        }
    }

    // Optional: Subject for activities like Mail.
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        if activityType == .mail {
            return "Interesting Article: \(title)"
        }
        return title // Default subject
    }
    
    #if os(iOS)
    // Optional: For richer previews (e.g., in Messages, Notes), provide LPLinkMetadata.
    // This requires iOS 13+ and LinkPresentation framework.
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.url = url
        // metadata.iconProvider = ... (if you have a custom icon)
        // metadata.imageProvider = ... (if you have an image URL, fetch it and provide NSItemProvider)
        
        // Create a simple icon from the app icon (or a generic news icon)
        if let appIcon = UIImage(named: "AppIcon") { // Ensure you have AppIcon in your assets
            metadata.iconProvider = NSItemProvider(object: appIcon)
        } else if let newsIcon = UIImage(systemName: "newspaper") {
             metadata.iconProvider = NSItemProvider(object: newsIcon)
        }
        
        // You could add a summary to the metadata if desired, though title and URL usually suffice for previews.
        // If you have an image URL for the article, you could fetch it and provide it here for an even richer preview.
        // For example, if newsItem.imageURL is available:
        // if let imageURL = articleImageURL {
        //     metadata.imageProvider = NSItemProvider(contentsOf: imageURL)
        // }
        
        return metadata
    }
    #endif
}
#endif // ArticleActivityItemSource class for iOS only

#endif // Top-level for LinkPresentation (iOS or macOS) 