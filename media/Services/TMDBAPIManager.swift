import Foundation
import Combine

// MARK: - TMDB API Manager
@MainActor
class TMDBAPIManager: ObservableObject {
    static let shared = TMDBAPIManager()
    
    private let bearerToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0ODM3M2M0YzgzY2IyMzBjOGFhNjc3MzliZTcxYmI0NSIsIm5iZiI6MTc0NDg1Mjg4Ny45NzQwMDAyLCJzdWIiOiI2ODAwNTc5N2YzOWM3MzAxMjVkOTM4NWYiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.PAvs_SkLxs4iOg1uAkBRKYKgsZZ4oRs0IpN1e6BYWbE"
    private let language = "en-US"
    private let baseURL = "https://api.themoviedb.org/3"
    private let imageBaseURL = "https://image.tmdb.org/t/p"
    
    private init() {}
    
    private var hasBearerToken: Bool {
        return !bearerToken.isEmpty
    }
    
    private func createAuthenticatedRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "Authorization": "Bearer \(bearerToken)"
        ]
        return request
    }
    
    private func getEndpoint(_ path: String) -> String {
        return baseURL + path
    }
    
    // MARK: - Movie Search
    func searchMovies(query: String, page: Int = 1) async throws -> TMDBSearchResponse {
        print("🎬 TMDBAPIManager: Starting movie search for query: '\(query)', page: \(page)")
        
        guard hasBearerToken else {
            print("❌ TMDBAPIManager: Missing bearer token")
            throw TMDBError.missingBearerToken
        }
        print("✅ TMDBAPIManager: Bearer token is available")
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ TMDBAPIManager: Empty query, returning empty results")
            return TMDBSearchResponse(page: 1, results: [], totalPages: 0, totalResults: 0)
        }
        
        let url = URL(string: getEndpoint("/search/movie"))!
        print("🌐 TMDBAPIManager: Base URL: \(url)")
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "page", value: String(page))
        ]
        components.queryItems = queryItems
        
        guard let finalURL = components.url else {
            print("❌ TMDBAPIManager: Failed to create final URL")
            throw TMDBError.invalidURL
        }
        
        print("🔗 TMDBAPIManager: Final URL: \(finalURL)")
        
        let request = createAuthenticatedRequest(for: finalURL)
        print("📝 TMDBAPIManager: Request headers: \(request.allHTTPHeaderFields ?? [:])")
        print("🔧 TMDBAPIManager: Request method: \(request.httpMethod ?? "nil")")
        print("⏱️ TMDBAPIManager: Request timeout: \(request.timeoutInterval)")
        
        print("🚀 TMDBAPIManager: Starting network request...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("📡 TMDBAPIManager: Network request completed")
            print("📊 TMDBAPIManager: Response data size: \(data.count) bytes")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📈 TMDBAPIManager: HTTP Status Code: \(httpResponse.statusCode)")
                print("📋 TMDBAPIManager: Response headers: \(httpResponse.allHeaderFields)")
                
                guard httpResponse.statusCode == 200 else {
                    print("❌ TMDBAPIManager: HTTP error - status code: \(httpResponse.statusCode)")
                    if data.count > 0 {
                        print("📄 TMDBAPIManager: Error response body: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                    }
                    throw TMDBError.networkError
                }
            } else {
                print("⚠️ TMDBAPIManager: Response is not HTTPURLResponse")
                throw TMDBError.networkError
            }
            
            print("🔍 TMDBAPIManager: Attempting to decode JSON response...")
            let searchResponse = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)
            print("✅ TMDBAPIManager: Successfully decoded response with \(searchResponse.results.count) results")
            print("📄 TMDBAPIManager: Total results: \(searchResponse.totalResults), Total pages: \(searchResponse.totalPages)")
            
            return searchResponse
        } catch {
            print("💥 TMDBAPIManager: Network request failed with error: \(error)")
            print("🔍 TMDBAPIManager: Error details: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("🌐 TMDBAPIManager: URLError code: \(urlError.code.rawValue)")
                print("🌐 TMDBAPIManager: URLError domain: \(urlError.errorCode)")
            }
            throw error
        }
    }
    
    // Convenience method for getting just the results (for backward compatibility)
    func searchMovieResults(query: String, page: Int = 1) async throws -> [TMDBMovieSearchResult] {
        let response = try await searchMovies(query: query, page: page)
        return response.results
    }
    
    // MARK: - Get Movie Details
    func getMovie(id: Int) async throws -> TMDBMovieDetails {
        guard hasBearerToken else {
            throw TMDBError.missingBearerToken
        }
        
        let url = URL(string: getEndpoint("/movie/\(id)"))!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "language", value: language)
        ]
        components.queryItems = components.queryItems.map { $0 + queryItems } ?? queryItems
        
        guard let finalURL = components.url else {
            throw TMDBError.invalidURL
        }
        
        let request = createAuthenticatedRequest(for: finalURL)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TMDBError.networkError
        }
        
        let movieDetails = try JSONDecoder().decode(TMDBMovieDetails.self, from: data)
        
        // Fetch credits separately
        let credits = try await getMovieCredits(id: id)
        
        return TMDBMovieDetails(
            id: movieDetails.id,
            title: movieDetails.title,
            overview: movieDetails.overview,
            releaseDate: movieDetails.releaseDate,
            runtime: movieDetails.runtime,
            genres: movieDetails.genres,
            posterPath: movieDetails.posterPath,
            backdropPath: movieDetails.backdropPath,
            voteAverage: movieDetails.voteAverage,
            credits: credits
        )
    }
    
    // MARK: - Get Movie Credits
    private func getMovieCredits(id: Int) async throws -> TMDBCredits {
        let url = URL(string: getEndpoint("/movie/\(id)/credits"))!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "language", value: language)
        ]
        components.queryItems = components.queryItems.map { $0 + queryItems } ?? queryItems
        
        guard let finalURL = components.url else {
            throw TMDBError.invalidURL
        }
        
        let request = createAuthenticatedRequest(for: finalURL)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TMDBError.networkError
        }
        
        return try JSONDecoder().decode(TMDBCredits.self, from: data)
    }
    
    // MARK: - Image URL Generation
    func imageURL(path: String?, size: String = "original") -> URL? {
        guard let path = path else { return nil }
        return URL(string: "\(imageBaseURL)/\(size)\(path)")
    }
    
    func thumbnailURL(path: String?) -> URL? {
        return imageURL(path: path, size: "w500")
    }
}

// MARK: - Data Models

struct TMDBSearchResponse: Codable {
    let page: Int
    let results: [TMDBMovieSearchResult]
    let totalPages: Int
    let totalResults: Int
    
    private enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBMovieSearchResult: Codable, Identifiable {
    let adult: Bool
    let backdropPath: String?
    let genreIds: [Int]
    let id: Int
    let originalLanguage: String
    let originalTitle: String
    let overview: String?
    let popularity: Double
    let posterPath: String?
    let releaseDate: String?
    let title: String
    let video: Bool
    let voteAverage: Double
    let voteCount: Int
    
    private enum CodingKeys: String, CodingKey {
        case adult, id, overview, popularity, title, video
        case backdropPath = "backdrop_path"
        case genreIds = "genre_ids"
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
    
    var year: Int? {
        guard let releaseDate = releaseDate, !releaseDate.isEmpty,
              let date = DateFormatter.tmdbDateFormatter.date(from: releaseDate) else {
            return nil
        }
        return Calendar.current.component(.year, from: date)
    }
    
    var thumbnailURL: URL? {
        return TMDBAPIManager.shared.thumbnailURL(path: posterPath)
    }
    
    var backdropURL: URL? {
        return TMDBAPIManager.shared.imageURL(path: backdropPath)
    }
}

struct TMDBMovieDetails: Codable {
    let id: Int
    let title: String
    let overview: String?
    let releaseDate: String?
    let runtime: Int?
    let genres: [TMDBGenre]
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    var credits: TMDBCredits?
    
    private enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
    }
    
    var year: Int? {
        guard let releaseDate = releaseDate,
              let date = DateFormatter.tmdbDateFormatter.date(from: releaseDate) else {
            return nil
        }
        return Calendar.current.component(.year, from: date)
    }
    
    var genreNames: String {
        return genres.map { $0.name }.joined(separator: ", ")
    }
    
    var posterURL: URL? {
        return TMDBAPIManager.shared.imageURL(path: posterPath)
    }
    
    var thumbnailURL: URL? {
        return TMDBAPIManager.shared.thumbnailURL(path: posterPath)
    }
    
    var directors: [TMDBCastMember] {
        return credits?.crew.filter { $0.job == "Director" } ?? []
    }
    
    var cast: [TMDBCastMember] {
        return credits?.cast ?? []
    }
    
    // Convert to local Movie model for saving
    func toMovie() -> Movie {
        return Movie(
            title: title,
            year: year,
            tmdbRating: voteAverage,
            posterPath: posterPath,
            backdropPath: backdropPath,
            runtime: runtime,
            genres: genreNames.isEmpty ? nil : genreNames,
            overview: overview,
            releaseDate: releaseDate,
            tmdbId: String(id),
            directors: directors.map { $0.name }.joined(separator: ", "),
            cast: cast.prefix(5).map { $0.name }.joined(separator: ", ")
        )
    }
}

struct TMDBGenre: Codable {
    let id: Int
    let name: String
}

struct TMDBCredits: Codable {
    let cast: [TMDBCastMember]
    let crew: [TMDBCastMember]
}

struct TMDBCastMember: Codable, Identifiable {
    let id: Int
    let name: String
    let character: String?
    let job: String?
    let profilePath: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, character, job
        case profilePath = "profile_path"
    }
    
    var profileURL: URL? {
        return TMDBAPIManager.shared.thumbnailURL(path: profilePath)
    }
}

// MARK: - Errors
enum TMDBError: LocalizedError {
    case missingBearerToken
    case invalidURL
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .missingBearerToken:
            return "TMDB Bearer token is required. Please get your Read Access Token from developer.themoviedb.org"
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network request failed"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let tmdbDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
} 
