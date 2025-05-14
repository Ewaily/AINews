//
//  NewsFeedView.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import SwiftUI
import CoreData

struct NewsFeedView: View {
    @StateObject var viewModel: NewsViewModel
    @ObservedObject var preferencesService: UserPreferencesService
    @State private var showingPersonalizationSettings = false

    // Initializer to allow injecting viewModel, defaulting to a new one for app use
    init(viewModel: NewsViewModel, preferencesService: UserPreferencesService) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.preferencesService = preferencesService
    }

    var body: some View {
        NavigationView {
            ZStack {
                #if os(iOS)
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                #else // macOS
                // On macOS, the default window background is usually fine.
                // You could use Color(NSColor.windowBackgroundColor) if a specific color is desired.
                #endif

                Group {
                    if viewModel.isLoading && viewModel.newsItems.isEmpty {
                        ProgressView("Loading News...")
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        // If OFFLINE and we HAVE saved articles, show them instead of just the error.
                        if !viewModel.savedArticles.isEmpty {
                            List {
                                Section(header: Text("Offline Articles").font(.headline).padding(.leading, -8)) {
                                    Text("Showing saved articles. You are currently offline.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .listRowInsets(EdgeInsets(top: 0, leading: horizontalPadding, bottom: 8, trailing: horizontalPadding))

                                    ForEach(viewModel.savedArticles) { savedArticle in
                                        // Display saved articles using a simplified card or by adapting NewsCardView
                                        // For now, a simplified display like in SavedArticlesView
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
                                                // No direct unsave here, user can go to Bookmarks tab
                                                Image(systemName: "bookmark.fill")
                                                     .foregroundColor(.gray) // Indicate it's from saved, but not interactive here
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                            .listStyle(.plain)
                        } else {
                            // Standard error display if no saved articles or other error
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.orange)
                                Text("Oops! Something went wrong.")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                Button {
                                    viewModel.fetchNews()
                                } label: {
                                    Text("Retry")
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.accentColor)
                                        .foregroundColor(Color.white)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding()
                        }
                    } else if viewModel.filteredNewsItems.isEmpty {
                        VStack(spacing: 16) {
                             Image(systemName: "newspaper.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.secondary)
                            Text("No News Yet")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Check back later for the latest AI developer news.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(viewModel.filteredNewsItems) { item in
                                NewsCardView(newsItem: item, viewModel: viewModel)
                                    .listRowInsets(EdgeInsets(top: 8, leading: horizontalPadding, bottom: 8, trailing: horizontalPadding))
                                    #if !os(watchOS)
                                    .listRowSeparator(.hidden)
                                    #endif
                                    .listRowBackground(Color.clear)
                            }
                            // Section for Copyright Footer
                            Section {
                                // Empty content for the section, we only need the footer
                            } footer: {
                                Text("© \(currentYear) TrianglZ LLC. All rights reserved.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 20) // Add some space above the copyright
                                    .padding(.bottom, 10) // Add some space below
                            }
                        }
                        .listStyle(.plain)
                        #if os(iOS)
                        .refreshable {
                            await Task {
                                viewModel.refreshNews()
                            }.value
                        }
                        #endif
                    }
                }
            }
            .navigationTitle("AI Developer News")
            #if os(iOS) || os(macOS) // Only show toolbar and sheet on iOS and macOS
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingPersonalizationSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                #elseif os(macOS)
                ToolbarItem(placement: .primaryAction) { // Use a macOS compatible placement
                    Button {
                        showingPersonalizationSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingPersonalizationSettings) {
                PersonalizationSettingsView(preferencesService: preferencesService)
            }
            #endif
            #if os(macOS)
            .frame(minWidth: 450, idealWidth: 600, maxWidth: .infinity, minHeight: 400, idealHeight: 700, maxHeight: .infinity)
            #endif
            .onAppear {
                #if os(iOS) || os(macOS) // Conditionally donate shortcut
                ShortcutDonator.donateGetLatestNewsShortcut()
                #endif
            }
        }
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle()) // Adapts to iPhone/iPad, use Stack style for iPad
        #endif
    }
    
    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }

    private var horizontalPadding: CGFloat {
        #if os(macOS)
        return 16
        #else
        return 0
        #endif
    }
}

#if DEBUG // Ensure previews are only compiled for Debug builds
struct NewsFeedView_Previews: PreviewProvider {
    static var previews: some View {
        let previewContext = PersistenceController.preview.container.viewContext
        // Ensure UserPreferencesService is initialized for previews
        let previewPreferencesService = UserPreferencesService()

        // Use the PreviewNewsViewModel from NewsViewModel.swift (which expects preferencesService)
        let previewViewModel = PreviewNewsViewModel(context: previewContext, preferencesService: previewPreferencesService, items: nil)
        let previewViewModelEmpty = PreviewNewsViewModel(context: previewContext, preferencesService: previewPreferencesService, items: [])
        let previewViewModelLoading = PreviewNewsViewModel(context: previewContext, preferencesService: previewPreferencesService, isLoading: true, items: [])
        let previewViewModelError = PreviewNewsViewModel(context: previewContext, preferencesService: previewPreferencesService, errorMessage: "Could not connect. Please check internet.", items: [])


        Group {
            NewsFeedView(viewModel: previewViewModel, preferencesService: previewPreferencesService)
                .environment(\.colorScheme, .light)
                .previewDisplayName("Light Mode - With Data")
            
            NewsFeedView(viewModel: previewViewModel, preferencesService: previewPreferencesService)
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode - With Data")

            NewsFeedView(viewModel: previewViewModelEmpty, preferencesService: previewPreferencesService)
                .previewDisplayName("Empty State")

            NewsFeedView(viewModel: previewViewModelLoading, preferencesService: previewPreferencesService)
                .previewDisplayName("Loading State")

            NewsFeedView(viewModel: previewViewModelError, preferencesService: previewPreferencesService)
                .previewDisplayName("Error State")
        }
        .environment(\.managedObjectContext, previewContext)
    }
}
#endif // DEBUG for NewsFeedView_Previews
