import Foundation
import Combine

// MARK: - Apple Books API Manager
@MainActor
class AppleBooksAPIManager: ObservableObject {
    static let shared = AppleBooksAPIManager()
    
    private let baseSearchURL = "https://itunes.apple.com/search"
    private let baseLookupURL = "https://itunes.apple.com/lookup"
    private let defaultCountry = "US"
    private init() {}
    
    // MARK: - Book Search
    func searchBooks(term: String, limit: Int = 25, country: String? = nil) async throws -> [AppleBookSearchResult] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard var components = URLComponents(string: baseSearchURL) else { throw AppleBooksError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "media", value: "ebook"),
            URLQueryItem(name: "term", value: trimmed),
            URLQueryItem(name: "country", value: country ?? defaultCountry),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let url = components.url else { throw AppleBooksError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw AppleBooksError.networkError }
        let decoded = try JSONDecoder().decode(AppleBookSearchResponse.self, from: data)
        return decoded.results
    }
    
    // MARK: - Lookup Book Details
    func getBook(id: Int, country: String? = nil) async throws -> AppleBookDetails {
        guard var components = URLComponents(string: baseLookupURL) else { throw AppleBooksError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "id", value: String(id)),
            URLQueryItem(name: "entity", value: "ebook"),
            URLQueryItem(name: "country", value: country ?? defaultCountry)
        ]
        guard let url = components.url else { throw AppleBooksError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw AppleBooksError.networkError }
        let decoded = try JSONDecoder().decode(AppleBookSearchResponse.self, from: data)
        guard let first = decoded.results.first else { throw AppleBooksError.decodingError }
        return first.toDetails()
    }
}

// MARK: - Response & Models
struct AppleBookSearchResponse: Codable {
    let resultCount: Int
    let results: [AppleBookSearchResult]
}

struct AppleBookSearchResult: Codable, Identifiable {
    let trackId: Int
    let trackName: String?
    let artistName: String?
    let description: String?
    let releaseDate: String?
    let averageUserRating: Double?
    let artworkUrl100: String?
    let genres: [String]?
    let formattedPrice: String?
    
    var id: Int { trackId }
    
    // Convenience helpers
    var coverURL: URL? { URL(string: artworkUrl100 ?? "") }
    var year: Int? {
        guard let release = releaseDate, let date = ISO8601DateFormatter().date(from: release) else { return nil }
        return Calendar.current.component(.year, from: date)
    }
    
    func toDetails() -> AppleBookDetails {
        return AppleBookDetails(trackId: trackId, trackName: trackName, artistName: artistName, description: description, releaseDate: releaseDate, averageUserRating: averageUserRating, artworkUrl100: artworkUrl100, genres: genres, formattedPrice: formattedPrice)
    }
}

struct AppleBookDetails: Codable, Identifiable {
    let trackId: Int
    let trackName: String?
    let artistName: String?
    let description: String?
    let releaseDate: String?
    let averageUserRating: Double?
    let artworkUrl100: String?
    let genres: [String]?
    let formattedPrice: String?
    
    var id: Int { trackId }
    var coverURL: URL? { URL(string: artworkUrl100 ?? "") }
    var year: Int? {
        guard let release = releaseDate, let date = ISO8601DateFormatter().date(from: release) else { return nil }
        return Calendar.current.component(.year, from: date)
    }
    var genreNames: String { genres?.joined(separator: ", ") ?? "" }
}

// MARK: - Errors
enum AppleBooksError: LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkError: return "Network request failed"
        case .decodingError: return "Failed to decode response"
        }
    }
} 