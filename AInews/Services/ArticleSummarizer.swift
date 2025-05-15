#if os(iOS) || os(macOS)
import Foundation
import CoreML
import NaturalLanguage

// Move the helper extensions to file scope
// Helper extension to count regex pattern matches
private extension String {
    func ranges(of pattern: String, options: NSRegularExpression.Options = []) -> [Range<String.Index>] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let nsRange = NSRange(startIndex..<endIndex, in: self)
        return regex.matches(in: self, options: [], range: nsRange).map { match in
            let range = Range(match.range, in: self)!
            return range
        }
    }
}

// Add extension to help detect non-printable characters
private extension Character {
    var isPrintable: Bool {
        let isControl = self.isASCII && self.asciiValue! < 32
        let isPrivateOrSpecial = self.unicodeScalars.contains { 
            $0.properties.generalCategory == .privateUse || 
            $0.properties.generalCategory == .surrogate ||
            $0.properties.generalCategory == .unassigned
        }
        return !isControl && !isPrivateOrSpecial
    }
}

class ArticleSummarizer {
    enum SummarizerError: Error {
        case preprocessingError
        case modelLoadingError
        case summarizationError
        case emptyContent
        case networkError
        case serverError
        case parsingError
    }
    
    // Singleton instance
    static let shared = ArticleSummarizer()
    
    // Private initializer for the singleton
    private init() {}
    
    // MARK: - Summary Generation
    
    /// Generates a summary for article content using CoreML
    /// - Parameters:
    ///   - content: The HTML content of the article to summarize
    ///   - completion: Callback with the generated summary or error
    func summarizeArticleContent(_ content: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Clean the HTML content
        let cleanContent = cleanHtmlContent(content)
        
        // Validate the cleaned content
        guard !cleanContent.isEmpty else {
            print("ArticleSummarizer: Empty content after cleaning HTML")
            completion(.failure(SummarizerError.emptyContent))
            return
        }
        
        // Process in background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // For now, use a simpler sentence extraction approach until we integrate a CoreML model
            
            // If the content is too long, truncate it to a reasonable size
            let truncatedContent = self.truncateIfNeeded(text: cleanContent, maxLength: 10000)
            
            let summary = self.generateSummaryWithNLP(from: truncatedContent)
            
            // Validate the summary is not empty
            guard !summary.isEmpty else {
                DispatchQueue.main.async {
                    print("ArticleSummarizer: Empty summary generated")
                    completion(.failure(SummarizerError.summarizationError))
                }
                return
            }
            
            // Return the result on the main thread
            DispatchQueue.main.async {
                completion(.success(summary))
            }
        }
    }
    
    /// Extracts a url and returns the article content
    /// - Parameters:
    ///   - urlString: The URL of the article to fetch and summarize
    ///   - completion: Callback with the generated summary or error
    func summarizeArticleFromURL(_ urlString: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if the URL is an image first
        let imageExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".svg"]
        if imageExtensions.contains(where: { urlString.lowercased().hasSuffix($0) }) {
            print("ArticleSummarizer: URL appears to be an image, cannot summarize")
            DispatchQueue.main.async {
                completion(.failure(SummarizerError.preprocessingError))
            }
            return
        }
        
        guard let url = URL(string: urlString) else {
            print("ArticleSummarizer: Invalid URL: \(urlString)")
            completion(.failure(NSError(domain: "ArticleSummarizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Use a timeout for the request
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15 // 15 seconds timeout
        let session = URLSession(configuration: config)
        
        print("ArticleSummarizer: Fetching content from: \(urlString)")
        
        // Fetch the content
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("ArticleSummarizer: Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(SummarizerError.networkError))
                }
                return
            }
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 400 {
                    print("ArticleSummarizer: HTTP error status code: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        completion(.failure(SummarizerError.serverError))
                    }
                    return
                }
                
                // Check content type to filter out non-text content
                if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                    let unsupportedTypes = ["image/", "video/", "audio/", "application/octet-stream", "application/pdf"]
                    if unsupportedTypes.contains(where: { contentType.contains($0) }) {
                        print("ArticleSummarizer: Unsupported content type: \(contentType)")
                        DispatchQueue.main.async {
                            completion(.failure(SummarizerError.preprocessingError))
                        }
                        return
                    }
                }
            }
            
            guard let data = data, !data.isEmpty else {
                print("ArticleSummarizer: No data received from URL")
                DispatchQueue.main.async {
                    completion(.failure(SummarizerError.emptyContent))
                }
                return
            }
            
            // Try to decode as UTF-8, but fall back to other encodings if needed
            var htmlString: String?
            
            // Try UTF-8 first
            htmlString = String(data: data, encoding: .utf8)
            
            // If UTF-8 fails, try other common encodings
            if htmlString == nil {
                let encodings: [String.Encoding] = [.ascii, .isoLatin1, .isoLatin2, .macOSRoman, .windowsCP1250, .windowsCP1251, .windowsCP1252]
                
                for encoding in encodings {
                    if let decodedString = String(data: data, encoding: encoding) {
                        htmlString = decodedString
                        break
                    }
                }
            }
            
            guard let content = htmlString else {
                print("ArticleSummarizer: Failed to decode HTML data")
                DispatchQueue.main.async {
                    completion(.failure(SummarizerError.parsingError))
                }
                return
            }
            
            // If there's very little content, it's likely not a proper article
            if content.count < 100 {
                print("ArticleSummarizer: Content too short (likely not an article)")
                DispatchQueue.main.async {
                    completion(.failure(SummarizerError.emptyContent))
                }
                return
            }
            
            // Use a fallback extraction method if the content doesn't appear to be HTML
            if !content.contains("<html") && !content.contains("<body") {
                print("ArticleSummarizer: Content doesn't appear to be HTML, using fallback")
                self.generateFallbackSummary(from: content, completion: completion)
                return
            }
            
            // Process the HTML content
            self.summarizeArticleContent(content, completion: completion)
        }
        
        task.resume()
    }
    
    // MARK: - Helper Methods
    
    private func truncateIfNeeded(text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        
        // If we need to truncate, try to do it at a sensible point like a period
        let truncatedIndex = text.index(text.startIndex, offsetBy: maxLength)
        if let periodIndex = text[..<truncatedIndex].lastIndex(where: { $0 == "." }) {
            return String(text[..<periodIndex]) + "."
        } else {
            return String(text[..<truncatedIndex]) + "..."
        }
    }
    
    private func generateFallbackSummary(from text: String, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Check if the text contains a high percentage of non-printable or unusual characters
            // which would indicate it's binary or encoded data rather than actual text
            let nonPrintableCharCount = text.filter { !$0.isPrintable }.count
            let percentNonPrintable = Double(nonPrintableCharCount) / Double(text.count)
            
            if percentNonPrintable > 0.15 || text.count < 50 {
                // If more than 15% of characters are non-printable or text is too short,
                // this is likely not text content that can be summarized
                DispatchQueue.main.async {
                    print("ArticleSummarizer: Content appears to be binary or non-text data")
                    completion(.failure(SummarizerError.preprocessingError))
                }
                return
            }
            
            // Simple fallback: Take first few sentences or generate a general message
            let fallbackSummary = self.generateSummaryWithNLP(from: text)
            
            if !fallbackSummary.isEmpty {
                DispatchQueue.main.async {
                    completion(.success(fallbackSummary))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(SummarizerError.summarizationError))
                }
            }
        }
    }
    
    /// Cleans HTML content and extracts the meaningful text
    /// - Parameter html: Raw HTML content
    /// - Returns: Cleaned text content
    private func cleanHtmlContent(_ html: String) -> String {
        // First, check if this looks like a Reddit page (which has special formatting)
        let isReddit = html.contains("www.reddit.com") || html.contains("r/LocalLLaMA") || html.contains("subreddit")
        
        // First, try to focus on the main content by extracting key sections
        var mainContent = html
        
        // Try to remove script, style tags, and SVG elements which contain non-visible content
        mainContent = mainContent.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        mainContent = mainContent.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        mainContent = mainContent.replacingOccurrences(of: "<svg[^>]*>[\\s\\S]*?</svg>", with: "", options: .regularExpression)
        
        // Remove all CSS class attributes which often contain styling code that gets mixed into text
        mainContent = mainContent.replacingOccurrences(of: "class=\"[^\"]*\"", with: "", options: .regularExpression)
        mainContent = mainContent.replacingOccurrences(of: "class='[^']*'", with: "", options: .regularExpression)
        
        // Remove all style attributes
        mainContent = mainContent.replacingOccurrences(of: "style=\"[^\"]*\"", with: "", options: .regularExpression)
        mainContent = mainContent.replacingOccurrences(of: "style='[^']*'", with: "", options: .regularExpression)
        
        // Remove common CSS patterns that are being incorrectly captured
        mainContent = mainContent.replacingOccurrences(of: "\\[&>:[^]]*\\]", with: "", options: .regularExpression)
        mainContent = mainContent.replacingOccurrences(of: "\\[&>\\s*:[^]]*\\]", with: "", options: .regularExpression)
        mainContent = mainContent.replacingOccurrences(of: "\\[&:[^]]*\\]", with: "", options: .regularExpression)
        
        // Special case for Reddit content
        if isReddit {
            // Extract post title and content from Reddit pages
            if let titleMatch = mainContent.range(of: "<h1[^>]*>([^<]+)</h1>", options: .regularExpression) {
                let title = String(mainContent[titleMatch])
                    .replacingOccurrences(of: "<h1[^>]*>", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "</h1>", with: "", options: .regularExpression)
                
                if let contentMatch = mainContent.range(of: "<div[^>]*data-testid=\"post-content[^\"]*\"[^>]*>([\\s\\S]*?)</div>", options: .regularExpression) {
                    let content = String(mainContent[contentMatch])
                    mainContent = "\(title) - \(content)"
                }
            }
        } else {
            // Try to extract content from articles, main sections, or divs with content
            if let articleMatch = mainContent.range(of: "<article[^>]*>([\\s\\S]*?)</article>", options: .regularExpression) {
                mainContent = String(mainContent[articleMatch])
            } else if let mainMatch = mainContent.range(of: "<main[^>]*>([\\s\\S]*?)</main>", options: .regularExpression) {
                mainContent = String(mainContent[mainMatch])
            } else if let contentMatch = mainContent.range(of: "<div[^>]*content[^>]*>([\\s\\S]*?)</div>", options: .regularExpression) {
                mainContent = String(mainContent[contentMatch])
            }
        }
        
        // Basic HTML tag removal
        var content = mainContent
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression) // Replace tags with spaces to avoid word joining
            .replacingOccurrences(of: "&[^;]+;", with: " ", options: .regularExpression) // Replace entities with spaces
        
        // Remove any CSS-like patterns that may have survived
        content = content.replacingOccurrences(of: "\\[&>:[^]]*\\]", with: "", options: .regularExpression)
        content = content.replacingOccurrences(of: "\\[&>\\s*:[^]]*\\]", with: "", options: .regularExpression)
        content = content.replacingOccurrences(of: "\\[&:[^]]*\\]", with: "", options: .regularExpression)
        content = content.replacingOccurrences(of: ":first-child[^\\s]*", with: "", options: .regularExpression)
        content = content.replacingOccurrences(of: "h-full|w-full|mb-\\d+|rounded-\\[inherit\\]|overflow-hidden|max-[hw]-full", with: "", options: .regularExpression)
        
        // Remove URLs and markup that often appears in text
        content = content.replacingOccurrences(of: "https?://\\S+", with: "", options: .regularExpression)
        content = content.replacingOccurrences(of: "www\\.\\S+", with: "", options: .regularExpression)
        content = content.replacingOccurrences(of: "r/\\w+", with: "", options: .regularExpression)
        
        // Clean up excessive whitespace
        content = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            
        // Remove any remaining CSS-like patterns
        content = content.replacingOccurrences(of: "\\s*\\[&>[^\\]]+\\]\\s*", with: " ", options: .regularExpression)
        
        // If we still have very little content, try a different approach
        if content.count < 50 && content.count < html.count / 100 {
            content = html
                .replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "class=\"[^\"]*\"", with: "", options: .regularExpression)
                .replacingOccurrences(of: "style=\"[^\"]*\"", with: "", options: .regularExpression)
                .replacingOccurrences(of: "&[^;]+;", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\[&>:[^]]*\\]", with: "", options: .regularExpression)
                .replacingOccurrences(of: ":first-child[^\\s]*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "h-full|w-full|mb-\\d+|rounded-\\[inherit\\]|overflow-hidden|max-[hw]-full", with: "", options: .regularExpression)
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty && $0.count > 2 } // Only keep substantive words
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Final cleanup - remove consecutive spaces and check for quality
        content = content.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If the content is garbage (contains mostly CSS-like patterns), return empty string
        let cssPatternCount = content.ranges(of: "\\[&>:|h-full|w-full|mb-\\d|overflow-hidden").count
        let wordCount = content.components(separatedBy: .whitespaces).count
        
        if cssPatternCount > wordCount / 5 || content.contains(":first-child") {
            print("Content appears to be mostly CSS patterns, returning empty result")
            return ""
        }
        
        return content
    }
}

extension ArticleSummarizer {
    /// Generates a summary using NLP techniques
    /// - Parameter text: The text to summarize
    /// - Returns: A summary of the text
    private func generateSummaryWithNLP(from text: String) -> String {
        // Split the text into sentences
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var sentences = [String]()
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty && sentence.count > 10 { // Only include substantive sentences
                sentences.append(sentence)
            }
            return true
        }
        
        // If no sentences were found, return an empty string
        if sentences.isEmpty {
            return ""
        }
        
        // If there are lots of sentences, try to identify important ones using basic heuristics
        if sentences.count > 5 {
            let keywords = extractKeywords(from: text)
            if !keywords.isEmpty {
                // Score sentences based on keyword presence
                let scoredSentences = sentences.map { sentence -> (String, Double) in
                    let sentenceLower = sentence.lowercased()
                    let score = keywords.reduce(0.0) { total, keyword in
                        if sentenceLower.contains(keyword) {
                            return total + 1.0
                        }
                        return total
                    }
                    return (sentence, score)
                }
                
                // Take the highest scoring sentences
                let sortedSentences = scoredSentences.sorted { $0.1 > $1.1 }
                let topSentences = Array(sortedSentences.prefix(3))
                
                if !topSentences.isEmpty {
                    return topSentences.map { $0.0 }.joined(separator: " ")
                }
            }
        }
        
        // Fallback to basic approach: take the first few sentences
        let summaryLength = min(3, sentences.count)
        let summarySentences = Array(sentences.prefix(summaryLength))
        
        return summarySentences.joined(separator: " ")
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text.lowercased()
        
        var keywords = [String: Int]()
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if tag == .noun || tag == .verb || tag == .adjective {
                let word = String(text[range]).lowercased()
                if word.count > 3 { // Only consider substantial words
                    keywords[word, default: 0] += 1
                }
            }
            return true
        }
        
        // Return the most frequent keywords
        return Array(keywords.sorted { $0.value > $1.value }.prefix(10).map { $0.key })
    }
    
    // MARK: - CoreML Integration
    
    // This would be where you'd add CoreML model loading and inference
    // For now, we'll use the simpler approach above
    // In a future update, you would replace generateSummaryWithNLP with this method
    private func summarizeWithCoreML(_ text: String) -> String {
        // TODO: Implement CoreML-based summarization
        // This is just a placeholder for now
        return text
    }
}
#else
// Dummy implementation for watchOS
import Foundation

class ArticleSummarizer {
    static let shared = ArticleSummarizer()
    private init() {}
    
    func summarizeArticleFromURL(_ urlString: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Simplified implementation for watchOS
        completion(.failure(NSError(domain: "ArticleSummarizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not available on watchOS"])))
    }
}
#endif 