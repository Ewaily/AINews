import Foundation

// Represents user's personalization preferences
struct UserPreferences: Codable {
    var followedTopics: [String] = []    // Keywords or topics the user wants to see
    var mutedTopics: [String] = []       // Keywords or topics the user wants to hide
    var mutedSources: [String] = []      // News sources (e.g., subreddits) the user wants to hide
    
    // Helper to check if a topic/keyword is effectively empty or whitespace
    private func isValid(_ item: String) -> Bool {
        return !item.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Add a topic to follow, ensuring no duplicates and it's valid
    mutating func addFollowedTopic(_ topic: String) {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if isValid(trimmedTopic) && !followedTopics.contains(trimmedTopic) {
            followedTopics.append(trimmedTopic)
        }
    }

    mutating func removeFollowedTopic(_ topic: String) {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        followedTopics.removeAll { $0 == trimmedTopic }
    }

    mutating func addMutedTopic(_ topic: String) {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if isValid(trimmedTopic) && !mutedTopics.contains(trimmedTopic) {
            mutedTopics.append(trimmedTopic)
        }
    }

    mutating func removeMutedTopic(_ topic: String) {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        mutedTopics.removeAll { $0 == trimmedTopic }
    }

    mutating func addMutedSource(_ source: String) {
        let trimmedSource = source.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if isValid(trimmedSource) && !mutedSources.contains(trimmedSource) {
            mutedSources.append(trimmedSource)
        }
    }

    mutating func removeMutedSource(_ source: String) {
        let trimmedSource = source.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        mutedSources.removeAll { $0 == trimmedSource }
    }
}

class UserPreferencesService: ObservableObject {
    @Published private(set) var preferences: UserPreferences {
        didSet {
            savePreferences()
        }
    }

    private let preferencesKey = "userNewsPreferences_v1"

    init() {
        self.preferences = Self.loadPreferences()
    }

    // Load preferences from UserDefaults
    private static func loadPreferences() -> UserPreferences {
        guard let data = UserDefaults.standard.data(forKey: "userNewsPreferences_v1"),
              let decodedPreferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return UserPreferences() // Return default if not found or decoding fails
        }
        return decodedPreferences
    }

    // Save preferences to UserDefaults
    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: preferencesKey)
        }
    }
    
    // MARK: - Public Methods to Modify Preferences (delegates to UserPreferences struct methods)

    func addFollowedTopic(_ topic: String) {
        objectWillChange.send() // Manually announce change before struct modification
        preferences.addFollowedTopic(topic)
    }

    func removeFollowedTopic(_ topic: String) {
        objectWillChange.send()
        preferences.removeFollowedTopic(topic)
    }

    func addMutedTopic(_ topic: String) {
        objectWillChange.send()
        preferences.addMutedTopic(topic)
    }

    func removeMutedTopic(_ topic: String) {
        objectWillChange.send()
        preferences.removeMutedTopic(topic)
    }

    func addMutedSource(_ source: String) {
        objectWillChange.send()
        preferences.addMutedSource(source)
    }

    func removeMutedSource(_ source: String) {
        objectWillChange.send()
        preferences.removeMutedSource(source)
    }
    
    // Method to get a fresh copy of preferences, useful for non-reactive parts of the code
    func getCurrentPreferences() -> UserPreferences {
        return Self.loadPreferences() // Always load the latest from UserDefaults
    }
} 