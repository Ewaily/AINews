#if os(iOS) || os(macOS)
import SwiftUI
import WebKit

#if os(iOS)
struct ArticleWebView: UIViewRepresentable {
    let urlString: String
    var fontSizeMultiplier: CGFloat = 1.0
    @ObservedObject var viewModel: WebViewViewModel

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        DispatchQueue.main.async {
            self.viewModel.webView = webView
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString), uiView.url?.absoluteString != url.absoluteString {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel)
    }
}
#elseif os(macOS)
struct ArticleWebView: NSViewRepresentable {
    let urlString: String
    var fontSizeMultiplier: CGFloat = 1.0
    @ObservedObject var viewModel: WebViewViewModel

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        DispatchQueue.main.async {
            self.viewModel.webView = webView
        }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if let url = URL(string: urlString), nsView.url?.absoluteString != url.absoluteString {
            let request = URLRequest(url: url)
            nsView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel)
    }
}
#endif

// Common Coordinator for both iOS and macOS
// The Coordinator needs access to the viewModel to set the webView
class Coordinator: NSObject, WKNavigationDelegate {
    var parentWebView: Any // Store ArticleWebView (either UIViewRepresentable or NSViewRepresentable)
    weak var webView: WKWebView?
    var viewModel: WebViewViewModel // viewModel passed from parent

    init(_ parent: Any, viewModel: WebViewViewModel) {
        self.parentWebView = parent
        self.viewModel = viewModel
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView = webView
        self.viewModel.webView = webView
        
        // --- Step 1: Load Readability.js library ---
        // Placeholder - actual Readability.js code needed
        let readabilityJSLibraryScript = "// --- Minified Readability.js library code would go here ---"
        
        webView.evaluateJavaScript(readabilityJSLibraryScript) { _, error in
            if let error = error {
                print("Error injecting Readability.js library: \(error.localizedDescription)")
                self.applyBasicStyling(webView: webView)
                return
            }
            
            let extractionScript = """
                var documentClone = document.cloneNode(true);
                var article = new Readability(documentClone).parse();
                if (article && article.content) {
                    document.body.innerHTML = article.content;
                    document.title = article.title;
                } else {
                    console.log('Readability parsing failed or returned no content.');
                }
            """
            
            webView.evaluateJavaScript(extractionScript) { _, error in
                if let error = error {
                    print("Error executing Readability extraction: \(error.localizedDescription)")
                }
                self.applyBasicStyling(webView: webView)
            }
        }
    }

    func applyBasicStyling(webView: WKWebView) {
        var currentFontSizeMultiplier: CGFloat = 1.0
        #if os(iOS)
        if let parent = parentWebView as? ArticleWebView { // Still need to cast to the correct type
            currentFontSizeMultiplier = parent.fontSizeMultiplier
        }
        #elseif os(macOS)
        if let parent = parentWebView as? ArticleWebView { // Still need to cast to the correct type
             currentFontSizeMultiplier = parent.fontSizeMultiplier
        }
        #endif

        let script = """
            function updateReaderModeStyles(fontSizeMult) {
                const isDarkMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
                const baseFontSize = 1.1; // em
                const currentFontSize = baseFontSize * fontSizeMult;
                
                var selectorsToRemove = [
                    'header', 'footer', 'nav', '.nav', '#nav',
                    '.sidebar', '#sidebar', '.ads', '#ads', '.advertisement', '#advertisement',
                    '.comments', '#comments', '.social', '#social', '.share', '#share',
                    '.related-posts', '#related-posts', '.cookie-banner', '#cookie-banner'
                ];
                selectorsToRemove.forEach(function(selector) {
                    document.querySelectorAll(selector).forEach(function(element) {
                        element.style.display = 'none';
                    });
                });

                document.body.style.margin = '0 auto';
                document.body.style.padding = '20px';
                document.body.style.maxWidth = '800px';
                #if os(iOS)
                document.body.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Helvetica Neue", "San Francisco", sans-serif';
                #elseif os(macOS)
                document.body.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Helvetica Neue", "San Francisco", sans-serif'; // Same for macOS for consistency
                #endif
                document.body.style.fontSize = currentFontSize + 'em';
                document.body.style.lineHeight = '1.6';

                if (isDarkMode) {
                    document.body.style.backgroundColor = '#1c1c1e';
                    document.body.style.color = '#ebebf5';
                } else {
                    document.body.style.backgroundColor = '#FFFFFF';
                    document.body.style.color = '#333333';
                }
                
                document.querySelectorAll('body img, body video, body iframe').forEach(function(img) {
                    img.style.maxWidth = '100%';
                    img.style.height = 'auto';
                    img.style.borderRadius = '8px';
                    img.style.marginTop = '1em';
                    img.style.marginBottom = '1em';
                });

                document.querySelectorAll('body figure figcaption').forEach(function(caption) {
                    caption.style.fontSize = '0.9em';
                    caption.style.color = isDarkMode ? '#a0a0a5' : '#555555';
                    caption.style.textAlign = 'center';
                    caption.style.marginTop = '0.5em';
                    caption.style.fontStyle = 'italic';
                });
                
                document.querySelectorAll('body p').forEach(function(p) {
                    p.style.marginBottom = '1em';
                });

                document.querySelectorAll('*').forEach(function(el) {
                    if (getComputedStyle(el).position === 'fixed' || getComputedStyle(el).position === 'sticky') {
                        if (el.tagName.toLowerCase() !== 'body' && el.tagName.toLowerCase() !== 'html') {
                            if (document.body.contains(el)) { 
                               el.style.display = 'none'; 
                            }
                        }
                    }
                });

                document.documentElement.style.height = 'auto';
                document.documentElement.style.overflow = 'auto';
                document.body.style.height = 'auto';
                document.body.style.overflow = 'auto';
                
                window.scrollTo(0, 0); 
            }
            
            window.setReaderFontSize = function(fontSizeMult) {
                const baseFontSize = 1.1; // em
                const newFontSize = baseFontSize * fontSizeMult;
                document.body.style.fontSize = newFontSize + 'em';
            }

            updateReaderModeStyles(\(currentFontSizeMultiplier));

            if (window.matchMedia) {
                window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function() {
                    updateReaderModeStyles(\(currentFontSizeMultiplier)); 
                });
            }
        """
        webView.evaluateJavaScript(script) { (result, error) in
             if let error = error {
                print("Error applying basic styling: \(error.localizedDescription)")
            }
        }
    }
}

// ViewModel to facilitate communication (e.g., calling JS)
class WebViewViewModel: ObservableObject {
    weak var webView: WKWebView?

    func updateFontSize(multiplier: CGFloat) {
        guard let webView = webView else {
            print("WebView not available to update font size")
            return
        }
        let js = "window.setReaderFontSize(\(multiplier));"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("Error setting font size: \(error.localizedDescription)")
            }
        }
    }
}

#if os(iOS) // ArticleDetailView is iOS-specific due to share sheet and presentationMode
struct ArticleDetailView: View {
    let newsItem: NewsItem
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var fontSizeMultiplier: CGFloat = 1.0
    @StateObject private var webViewViewModel = WebViewViewModel()
    @ObservedObject var viewModel: NewsViewModel
    
    var body: some View {
        NavigationView { // NavigationView needed for .toolbar and navigationTitle
            VStack(alignment: .leading, spacing: 0) {
                // AI Summary card at the top with enhanced prominence
                if let aiSummary = newsItem.aiSummary {
                    VStack(alignment: .leading, spacing: 12) {
                        // Enhanced badge header
                        HStack(spacing: 6) {
                            Image(systemName: "brain.head.profile")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Summarized by On-Device AI")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.purple)
                        .clipShape(Capsule())
                        
                        Text(aiSummary)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.top, 4)
                    }
                    .padding(16)
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                } else if newsItem.isGeneratingAISummary {
                    VStack(spacing: 12) {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.9)
                            Text("Generating AI Summary...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                        }
                        Text("Our on-device AI is analyzing this article to create a concise summary.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                } else {
                    Button {
                        viewModel.generateAISummary(for: newsItem)
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.headline)
                            Text("Generate On-Device AI Summary")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.purple)
                        .padding(16)
                        .background(Color.purple.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
                
                // Web view with the article content
                ArticleWebView(urlString: newsItem.url, fontSizeMultiplier: fontSizeMultiplier, viewModel: webViewViewModel)
            }
            .navigationTitle(Text(newsItem.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        adjustFontSize(by: -0.1)
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                    }
                    
                    Button {
                        adjustFontSize(by: 0.1)
                    } label: {
                        Image(systemName: "textformat.size.larger")
                    }

                    Button {
                        shareArticle()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private func adjustFontSize(by amount: CGFloat) {
        let newMultiplier = max(0.5, min(2.5, fontSizeMultiplier + amount)) // Clamp between 0.5x and 2.5x
        fontSizeMultiplier = newMultiplier
        webViewViewModel.updateFontSize(multiplier: newMultiplier)
    }

    private func shareArticle() {
        guard let url = URL(string: newsItem.url) else { return }
        let activityItemSource = ArticleActivityItemSource(title: newsItem.title, url: url, summary: newsItem.summary)
        
        let activityViewController = UIActivityViewController(activityItems: [activityItemSource, url], applicationActivities: nil)

        // Find the top-most view controller to present the share sheet
        var topController = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        topController?.present(activityViewController, animated: true, completion: nil)
    }
}

// Preview for ArticleDetailView (iOS only)
struct ArticleDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let previewPreferencesService = UserPreferencesService()
        let previewViewModel = NewsViewModel(context: PersistenceController.preview.container.viewContext, preferencesService: previewPreferencesService)
        
        ArticleDetailView(newsItem: NewsItem(id: 1, title: "Sample Article Title", summary: "This is a sample summary.", subreddit: "Tech", post_id: "123", created_at: "2023-01-01", date_posted: "2023-01-01", tags: ["sample", "tech"], image: nil, url: "https://www.apple.com", usecases: [], significance: "HIGH", impact: "Major"), viewModel: previewViewModel)
    }
}
#endif // os(iOS) for ArticleDetailView

#endif // os(iOS) || os(macOS) 