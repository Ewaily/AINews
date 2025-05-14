import SwiftUI
import CoreData

struct SavedArticlesView: View {
    @ObservedObject var viewModel: NewsViewModel
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            Group {
                if viewModel.savedArticles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark.slash.fill") // Or another appropriate icon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.secondary)
                        Text("No Saved Articles")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("You haven't bookmarked any articles yet. Tap the bookmark icon on an article to save it for later.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.savedArticles) { savedArticle in
                            // We need a way to convert SavedArticle back to a NewsItem-like structure
                            // or adapt NewsCardView to take a SavedArticle.
                            // For now, let's create a simple display.
                            // Ideally, NewsCardView would be adapted or a similar card for SavedArticle created.
                            VStack(alignment: .leading, spacing: 8) {
                                Text(savedArticle.title ?? "No Title")
                                    .font(.headline)
                                Text(savedArticle.summary ?? "No Summary")
                                    .font(.subheadline)
                                    .lineLimit(3)
                                HStack {
                                    Text("Saved: \(savedArticle.savedAt ?? Date(), style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button {
                                        viewModel.unsaveArticle(articleID: Int(savedArticle.articleID))
                                    } label: {
                                        Image(systemName: "bookmark.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Bookmarks")
            #if os(macOS)
            .frame(minWidth: 350, idealWidth: 450, maxWidth: .infinity, minHeight: 300, idealHeight: 600, maxHeight: .infinity)
            #endif
            .toolbar {
                #if os(iOS)
                // Only show EditButton if there are saved articles
                if !viewModel.savedArticles.isEmpty {
                    EditButton()
                }
                #endif
            }
            .onAppear {
                // Ensure saved articles are up-to-date when the view appears
                viewModel.fetchSavedArticles()
                #if os(iOS) || os(macOS) // Conditionally donate shortcut
                ShortcutDonator.donateShowBookmarksShortcut()
                #endif
            }
        }
        // Apply the same navigationViewStyle as NewsFeedView for consistency on iPad
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { viewModel.savedArticles[$0] }.forEach {
                viewModel.unsaveArticle(articleID: Int($0.articleID))
            }
        }
    }
}

struct SavedArticlesView_Previews: PreviewProvider {
    static var previews: some View {
        let previewContext = PersistenceController.preview.container.viewContext
        let previewPreferencesService = UserPreferencesService() // Create for preview
        let previewViewModel = NewsViewModel(context: previewContext, preferencesService: previewPreferencesService) // Pass service
        
        // For preview, let's ensure there are some saved articles in the preview context
        // This is typically done by adding sample data directly in PersistenceController.preview
        // or by calling saveArticle here if your saveArticle is synchronous enough for previews.
        // For simplicity, we rely on the sample data in PersistenceController.preview

        return SavedArticlesView(viewModel: previewViewModel)
            .environment(\.managedObjectContext, previewContext)
    }
} 