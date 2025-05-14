#if os(iOS) || os(macOS)

import Foundation
import Intents
// CoreSpotlight might not be needed if we only rely on intent identifiers from generated classes
// import CoreSpotlight // For NSUserActivity constants

// Enum to define the tabs or deep link destinations
enum AppTab: Hashable {
    case newsFeed
    case bookmarks
}

// ObservableObject to manage app navigation state, especially for deep linking from intents
class AppNavigationManager: ObservableObject {
    @Published var activeTab: AppTab? = .newsFeed // Default to news feed
    // You could add more properties here if your intents carry parameters you need to pass to views
}

// MARK: - Intent Handler

class AINewsIntentHandler: NSObject, GetLatestNewsIntentHandling, ShowBookmarksIntentHandling {
    
    // MARK: - GetLatestNewsIntentHandling
    
    func handle(intent: GetLatestNewsIntent, completion: @escaping (GetLatestNewsIntentResponse) -> Void) {
        // This intent doesn't have parameters, so it's straightforward.
        // We'll signal the app to navigate to the news feed.
        // The actual navigation will be handled by the App structure observing AppNavigationManager.
        completion(GetLatestNewsIntentResponse(code: .success, userActivity: nil))
    }
    
    func confirm(intent: GetLatestNewsIntent, completion: @escaping (GetLatestNewsIntentResponse) -> Void) {
        // Basic confirmation, no complex validation needed here for now.
        completion(GetLatestNewsIntentResponse(code: .ready, userActivity: nil))
    }
    
    // MARK: - ShowBookmarksIntentHandling
    
    func handle(intent: ShowBookmarksIntent, completion: @escaping (ShowBookmarksIntentResponse) -> Void) {
        // Signal the app to navigate to bookmarks.
        completion(ShowBookmarksIntentResponse(code: .success, userActivity: nil))
    }
    
    func confirm(intent: ShowBookmarksIntent, completion: @escaping (ShowBookmarksIntentResponse) -> Void) {
        completion(ShowBookmarksIntentResponse(code: .ready, userActivity: nil))
    }
    
    // Optional: Provide a specific handler instance if needed by the App Delegate/Scene Delegate
    // For in-app intents that just open the app to a state, this might not be strictly necessary
    // if the intent handling logic is simple and can be managed by responding to NSUserActivity.
}

// MARK: - Shortcut Donation Utilities

class ShortcutDonator {
    static func donateGetLatestNewsShortcut() {
        let intent = GetLatestNewsIntent()
        intent.suggestedInvocationPhrase = "Show Latest AI News Feed"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate {
            error in
            if let error = error {
                print("Error donating GetLatestNewsIntent: \(error.localizedDescription)")
            }
        }
    }
    
    static func donateShowBookmarksShortcut() {
        let intent = ShowBookmarksIntent()
        intent.suggestedInvocationPhrase = "Show My AI News Bookmarks"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate {
            error in
            if let error = error {
                print("Error donating ShowBookmarksIntent: \(error.localizedDescription)")
            }
        }
    }
}

#endif 