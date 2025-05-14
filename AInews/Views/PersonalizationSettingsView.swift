#if os(iOS) || os(macOS)

import SwiftUI

struct PersonalizationSettingsView: View {
    @StateObject var preferencesService: UserPreferencesService // Inject the service
    @Environment(\.presentationMode) var presentationMode

    // State for new entries
    @State private var newFollowedTopic: String = ""
    @State private var newMutedTopic: String = ""
    @State private var newMutedSource: String = ""

    var body: some View {
        #if os(iOS)
        NavigationView {
            formContent
            .navigationTitle("Personalize Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack) // Good for modal presentation
        #else // macOS
        formContent
            .navigationTitle("Personalize Feed") // Keep for macOS if view is in a window with a title bar
            // macOS sheets typically have their own close button, or can be dismissed by other means.
            // If a specific button is needed, it would be added here, possibly in a different style.
            .toolbar { // Example of a macOS-compatible toolbar item if needed
                ToolbarItem(placement: .confirmationAction) { // Or .cancellationAction, .primaryAction etc.
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        #endif
    }

    var formContent: some View { // Extracted Form content to avoid duplication
        Form {
            // MARK: - Followed Topics
            Section(header: Text("Followed Topics/Keywords"), footer: Text("News items must contain at least one of these to be shown, if this list is not empty.")) {
                ForEach(preferencesService.preferences.followedTopics, id: \.self) { topic in
                    Text(topic)
                }
                .onDelete(perform: removeFollowedTopic)
                
                HStack {
                    TextField("Add topic/keyword to follow...", text: $newFollowedTopic)
                    Button("Add") {
                        if !newFollowedTopic.isEmpty {
                            preferencesService.addFollowedTopic(newFollowedTopic)
                            newFollowedTopic = ""
                        }
                    }
                    .disabled(newFollowedTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            // MARK: - Muted Topics
            Section(header: Text("Muted Topics/Keywords"), footer: Text("News items containing any of these will be hidden.")) {
                ForEach(preferencesService.preferences.mutedTopics, id: \.self) { topic in
                    Text(topic)
                }
                .onDelete(perform: removeMutedTopic)
                
                HStack {
                    TextField("Add topic/keyword to mute...", text: $newMutedTopic)
                    Button("Add") {
                        if !newMutedTopic.isEmpty {
                            preferencesService.addMutedTopic(newMutedTopic)
                            newMutedTopic = ""
                        }
                    }
                    .disabled(newMutedTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            // MARK: - Muted Sources
            Section(header: Text("Muted Sources"), footer: Text("News items from these sources (e.g., subreddits) will be hidden.")) {
                ForEach(preferencesService.preferences.mutedSources, id: \.self) { source in
                    Text(source)
                }
                .onDelete(perform: removeMutedSource)
                
                HStack {
                    TextField("Add source to mute...", text: $newMutedSource)
                    Button("Add") {
                        if !newMutedSource.isEmpty {
                            preferencesService.addMutedSource(newMutedSource)
                            newMutedSource = ""
                        }
                    }
                    .disabled(newMutedSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func removeFollowedTopic(at offsets: IndexSet) {
        offsets.forEach { index in
            let topic = preferencesService.preferences.followedTopics[index]
            preferencesService.removeFollowedTopic(topic)
        }
    }

    private func removeMutedTopic(at offsets: IndexSet) {
        offsets.forEach { index in
            let topic = preferencesService.preferences.mutedTopics[index]
            preferencesService.removeMutedTopic(topic)
        }
    }

    private func removeMutedSource(at offsets: IndexSet) {
        offsets.forEach { index in
            let source = preferencesService.preferences.mutedSources[index]
            preferencesService.removeMutedSource(source)
        }
    }
}

struct PersonalizationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalizationSettingsView(preferencesService: UserPreferencesService())
    }
}

#endif 