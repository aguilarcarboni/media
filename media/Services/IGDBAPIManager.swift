import Foundation
import Combine

// MARK: - IGDB API Manager
@MainActor
class IGDBAPIManager: ObservableObject {
    static let shared = IGDBAPIManager()
    
    // MARK: - Credentials (Replace with your Twitch credentials)
    private let clientID: String = "fa77hibdqlllmnsbxfl1to13g0q9yw"
    private let clientSecret: String = "jck9p7wpsski9kzckpgw9a4s8qpdja"
    
    // MARK: - Private properties
    private let baseURL = "https://api.igdb.com/v4"
    private let imageBaseURL = "https://images.igdb.com/igdb/image/upload"
    private let tokenURL = "https://id.twitch.tv/oauth2/token"
    
    private var accessToken: String?
    private var tokenExpiration: Date?
    
    private init() {}
    
    // MARK: - Authorization Helpers
    private func validAccessToken() async throws -> String {
        // Reuse token if it exists and is still valid
        if let token = accessToken, let expiration = tokenExpiration {
            if expiration.timeIntervalSinceNow > 0 {
                return token
            }
        }
        // Otherwise fetch a new token
        return try await fetchAccessToken()
    }
    
    private func fetchAccessToken() async throws -> String {
        guard !clientID.isEmpty, !clientSecret.isEmpty else {
            throw IGDBError.missingCredentials
        }
        
        guard var components = URLComponents(string: tokenURL) else {
            throw IGDBError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "grant_type", value: "client_credentials")
        ]
        
        guard let url = components.url else { throw IGDBError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw IGDBError.networkError
        }
        
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        accessToken = decoded.access_token
        tokenExpiration = Date(timeIntervalSinceNow: TimeInterval(decoded.expires_in))
        
        return decoded.access_token
    }
    
    // MARK: - Request Helper
    private func createRequest(endpoint: String, body: String) async throws -> URLRequest {
        let token = try await validAccessToken()
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw IGDBError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(clientID, forHTTPHeaderField: "Client-ID")
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.httpBody = body.data(using: .utf8)
        return request
    }
    
    // MARK: - Game Search
    func searchGames(query: String, limit: Int = 20, offset: Int = 0) async throws -> [IGDBGameSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let escapedQuery = query.replacingOccurrences(of: "\"", with: "\\\"")
        let body = "search \"" + escapedQuery + "\"; fields name,cover.image_id,platforms.name,first_release_date,genres.name,summary; limit \(limit); offset \(offset);"
        let request = try await createRequest(endpoint: "/games", body: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw IGDBError.networkError
            }
            let results = try JSONDecoder().decode([IGDBGameSearchResult].self, from: data)
            return results
        } catch {
            throw error
        }
    }
    
    // Convenience method to get just the first page of results that map to local Game model (if created in the future)
    func searchGameResults(query: String, limit: Int = 20, offset: Int = 0) async throws -> [IGDBGameSearchResult] {
        return try await searchGames(query: query, limit: limit, offset: offset)
    }
    
    // MARK: - Get Game Details
    func getGame(id: Int) async throws -> IGDBGameDetails {
        let body = "fields name,cover.image_id,platforms.name,first_release_date,genres.name,summary; where id = \(id); limit 1;"
        let request = try await createRequest(endpoint: "/games", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw IGDBError.networkError
        }
        let decoded = try JSONDecoder().decode([IGDBGameDetails].self, from: data)
        guard let details = decoded.first else {
            throw IGDBError.decodingError
        }
        return details
    }
    
    // MARK: - Image Helpers
    func imageURL(imageID: String?, size: IGDBImageSize = .thumb) -> URL? {
        guard let imageID = imageID else { return nil }
        return URL(string: "\(imageBaseURL)/t_\(size.rawValue)/\(imageID).jpg")
    }
}

// MARK: - Image Size Enum
enum IGDBImageSize: String {
    case thumb = "cover_big"   // 264x374
    case original = "original"
}

// MARK: - Data Models

// Search & Detail share most fields, we separate if needed
struct IGDBGameSearchResult: Codable, Identifiable {
    let id: Int
    let name: String?
    let first_release_date: Int?
    let summary: String?
    let cover: IGDBCover?
    let platforms: [IGDBPlatform]?
    let genres: [IGDBGenre]?
    
    // Convenience
    var releaseDate: Date? {
        guard let timestamp = first_release_date else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
    
    var thumbnailURL: URL? {
        return IGDBAPIManager.shared.imageURL(imageID: cover?.image_id)
    }
    var platformNames: [String] {
        return platforms?.compactMap { $0.name } ?? []
    }
}

struct IGDBGameDetails: Codable, Identifiable {
    let id: Int
    let name: String?
    let first_release_date: Int?
    let summary: String?
    let cover: IGDBCover?
    let platforms: [IGDBPlatform]?
    let genres: [IGDBGenre]?
    
    var releaseDate: Date? {
        guard let timestamp = first_release_date else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
    
    var posterURL: URL? {
        return IGDBAPIManager.shared.imageURL(imageID: cover?.image_id, size: .original)
    }
    
    var thumbnailURL: URL? {
        return IGDBAPIManager.shared.imageURL(imageID: cover?.image_id)
    }
    
    var platformNames: [String] {
        return platforms?.compactMap { $0.name } ?? []
    }
    
    var genreNames: String {
        return genres?.compactMap { $0.name }.joined(separator: ", ") ?? ""
    }
}

struct IGDBCover: Codable { let image_id: String? }
struct IGDBPlatform: Codable { let id: Int?; let name: String? }
struct IGDBGenre: Codable { let id: Int?; let name: String? }

struct TokenResponse: Codable {
    let access_token: String
    let expires_in: Int
}

// MARK: - Errors
enum IGDBError: LocalizedError {
    case missingCredentials
    case invalidURL
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "IGDB Client ID and Client Secret are required."
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network request failed"
        case .decodingError:
            return "Failed to decode response"
        }
    }
} 
