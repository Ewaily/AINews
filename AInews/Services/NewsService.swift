//
//  NewsService.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import Foundation

class NewsService {
    func fetchNews(completion: @escaping (Result<[NewsItem], Error>) -> Void) {
        guard let url = URL(string: Constants.newsApiUrl) else {
            // Ensure completion is on main thread even for early exit
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "NewsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
            }
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NewsService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response. Status code: \(statusCode)"])))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NewsService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase // Handles keys like post_id
                let newsItems = try decoder.decode([NewsItem].self, from: data)
                DispatchQueue.main.async { // Ensure completion is called on the main thread
                    completion(.success(newsItems))
                }
            } catch let decodingError {
                var errorDescription = "Failed to decode data: \(decodingError.localizedDescription)"
                #if DEBUG
                print("--- Decoding Error --- Services/NewsService.swift ---")
                print("Error: \(decodingError)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON String trying to be decoded:\n\(jsonString)")
                } else {
                    print("Could not convert data to UTF-8 string for debugging.")
                }
                errorDescription += " Check console for more details."
                print("--- End Decoding Error ---")
                #endif
                DispatchQueue.main.async { // Ensure completion is called on the main thread
                    completion(.failure(NSError(domain: "NewsService", code: -4, userInfo: [NSLocalizedDescriptionKey: errorDescription])))
                }
            }
        }.resume()
    }
} 
