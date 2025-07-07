//
//  MarvelAPIManager.swift
//  media
//
//  Created by Andrés on 6/7/2025.
//

import Foundation
import CryptoKit
import Combine

// MARK: - Marvel API Manager
@MainActor
class MarvelAPIManager: ObservableObject {
    static let shared = MarvelAPIManager()
    
    // TODO: Replace with your actual keys from developer.marvel.com
    private let publicKey: String = "691b557a8ccee7c6f11a0cc7a1d65fa8"
    private let privateKey: String = "008c5499e0b445baaf744289261544e25b1e4094"
    
    private let baseURL = "https://gateway.marvel.com/v1/public"
    private init() {}
    
    // MARK: - Authentication Helpers
    private func authQueryItems() -> [URLQueryItem] {
        // Marvel requires timestamp (ts) and MD5 hash of ts+privateKey+publicKey for every request.
        // We use millisecond precision for the timestamp to reduce the chance of collisions.
        let timestamp = Date().currentTimeInMillis()
        let ts = String(timestamp)
        let hash = (ts + privateKey + publicKey).md5Value
        print("🔐 ts=\(ts)  hash=\(hash)")
        return [
            URLQueryItem(name: "apikey", value: publicKey),
            URLQueryItem(name: "ts", value: ts),
            URLQueryItem(name: "hash", value: hash)
        ]
    }
    
    private func endpoint(_ path: String) -> URL { URL(string: baseURL + path)! }
    
    // MARK: - Request helper
    private func buildRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Ask for gzip to save bandwidth
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func performRequest<T: Decodable>(url: URL, decode type: T.Type) async throws -> T {
        let request = buildRequest(url: url)
        print("🚀 MarvelAPI: Request → \(request.url?.absoluteString ?? "nil")")
        let (data, response) = try await URLSession.shared.data(for: request)

        // Response diagnostics
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 MarvelAPI: HTTP \(httpResponse.statusCode)")
            print("📏 MarvelAPI: Received \(data.count) bytes")
            // ETag header if any
            if let etag = httpResponse.allHeaderFields["Etag"] ?? httpResponse.allHeaderFields["ETag"] {
                print("🔖 MarvelAPI: ETag = \(etag)")
            }
        }

        // Print the first 500 bytes of the JSON for quick inspection (safe-guard against huge dumps)
        if let snippet = String(data: data.prefix(500), encoding: .utf8) {
            print("📄 MarvelAPI: JSON snippet → \n\(snippet)\n…")
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MarvelError.networkError
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Comic Search
    func searchComics(query: String, limit: Int = 20, offset: Int = 0) async throws -> [MarvelComicSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        print("searchComics: \(query)")
        var components = URLComponents(url: endpoint("/comics"), resolvingAgainstBaseURL: true)!
        components.queryItems = authQueryItems() + [
            URLQueryItem(name: "titleStartsWith", value: query),
            URLQueryItem(name: "orderBy", value: "title"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        print("components: \(components)")
        guard let url = components.url else { throw MarvelError.invalidURL }
        print("url: \(url)")
        let wrapper: MarvelAPIWrapper<MarvelComic> = try await performRequest(url: url, decode: MarvelAPIWrapper<MarvelComic>.self)
        return wrapper.data.results.map { MarvelComicSearchResult(from: $0) }
    }
    
    // MARK: - Comic Details
    func getComic(id: Int) async throws -> MarvelComicDetails {
        var components = URLComponents(url: endpoint("/comics/\(id)"), resolvingAgainstBaseURL: true)!
        components.queryItems = authQueryItems()
        guard let url = components.url else { throw MarvelError.invalidURL }

        print("getComic: Fetching comic with ID \(id)")
        let wrapper: MarvelAPIWrapper<MarvelComic> = try await performRequest(url: url, decode: MarvelAPIWrapper<MarvelComic>.self)
        guard let comic = wrapper.data.results.first else { throw MarvelError.notFound }
        return MarvelComicDetails(from: comic)
    }
    
    // MARK: - Image Helpers
    func imageURL(path: String, ext: String, variant: String = "portrait_uncanny") -> URL? {
        URL(string: "\(path)/\(variant).\(ext)")
    }
}

// MARK: - Errors
enum MarvelError: Error {
    case invalidURL
    case networkError
    case notFound
}

// MARK: - Generic Response Containers
struct MarvelAPIWrapper<T: Codable>: Codable {
    let code: Int
    let status: String
    let data: MarvelAPIListContainer<T>
}

struct MarvelAPIListContainer<T: Codable>: Codable {
    let offset: Int
    let limit: Int
    let total: Int
    let count: Int
    let results: [T]
}

// MARK: - Core API Models
struct MarvelComic: Codable {
    let id: Int
    let digitalId: Int?
    let title: String
    let issueNumber: Double
    let variantDescription: String?
    let description: String?
    let pageCount: Int?
    let format: String?
    let thumbnail: MarvelImage?
    let images: [MarvelImage]?
    let series: MarvelSeriesSummary?
    let creators: MarvelResourceList<MarvelCreatorSummary>?
    let characters: MarvelResourceList<MarvelCharacterSummary>?
    let dates: [MarvelComicDate]?
}

struct MarvelImage: Codable { let path: String; let `extension`: String }
struct MarvelComicDate: Codable { let type: String; let date: String }
struct MarvelSeriesSummary: Codable { let resourceURI: String; let name: String }

struct MarvelResourceList<Item: Codable>: Codable { let items: [Item] }
struct MarvelCreatorSummary: Codable { let resourceURI: String; let name: String; let role: String? }
struct MarvelCharacterSummary: Codable { let resourceURI: String; let name: String }

// MARK: - View-Specific Models
struct MarvelComicSearchResult: Identifiable {
    let id: Int
    let title: String
    let issueNumber: Double
    let year: Int?
    let thumbnailURL: URL?
    let overview: String?
    
    init(from comic: MarvelComic) {
        self.id = comic.id
        self.title = comic.title
        self.issueNumber = comic.issueNumber
        self.overview = comic.description
        // Derive year from onsaleDate if present
        if let dateStr = comic.dates?.first(where: { $0.type == "onsaleDate" })?.date,
           let date = ISO8601DateFormatter().date(from: dateStr) {
            self.year = Calendar.current.component(.year, from: date)
        } else {
            self.year = nil
        }
        if let thumb = comic.thumbnail {
            self.thumbnailURL = MarvelAPIManager.shared.imageURL(path: thumb.path, ext: thumb.extension, variant: "portrait_medium")
        } else {
            self.thumbnailURL = nil
        }
    }
}

struct MarvelComicDetails {
    let id: Int
    let title: String
    let issueNumber: Double
    let description: String?
    let pageCount: Int?
    let publicationDate: String?
    let format: String?
    let series: MarvelSeriesSummary?
    let coverURLString: String?
    let thumbnailURLString: String?
    let writers: [String]
    let artists: [String]
    let characters: [String]
    
    init(from comic: MarvelComic) {
        self.id = comic.id
        self.title = comic.title
        self.issueNumber = comic.issueNumber
        self.description = comic.description
        self.pageCount = comic.pageCount
        self.format = comic.format
        self.series = comic.series
        if let dateStr = comic.dates?.first(where: { $0.type == "onsaleDate" })?.date {
            self.publicationDate = dateStr
        } else {
            self.publicationDate = nil
        }
        // Prefer first image, fall back to thumbnail
        let img = comic.images?.first ?? comic.thumbnail
        if let img {
            self.coverURLString = "\(img.path).\(img.extension)"
            self.thumbnailURLString = "\(img.path)/portrait_medium.\(img.extension)"
        } else {
            self.coverURLString = nil
            self.thumbnailURLString = nil
        }
        // Creators parsing
        let allCreators = comic.creators?.items ?? []
        self.writers = allCreators.filter { ($0.role ?? "").lowercased().contains("writer") }.map { $0.name }
        self.artists = allCreators.filter { ($0.role ?? "").lowercased().contains("artist") }.map { $0.name }
        self.characters = comic.characters?.items.map { $0.name } ?? []
    }
    
    // Helper to convert into local Comic entity
    func toComic() -> Comic {
        Comic(
            marvelId: id,
            title: title,
            issueNumber: Int(issueNumber),
            seriesName: series?.name,
            publicationDate: publicationDate,
            format: format,
            pageCount: pageCount,
            synopsis: description,
            coverURLString: coverURLString,
            thumbnailURLString: thumbnailURLString,
            writers: writers.joined(separator: ", "),
            artists: artists.joined(separator: ", "),
            characters: characters.joined(separator: ", ")
        )
    }
}

// MARK: - Utility Extensions (from MarvelApi.swift sample)

private extension Date {
    /// Returns the current time in milliseconds since 1970 (Unix epoch).
    func currentTimeInMillis() -> Int64 {
        Int64(timeIntervalSince1970 * 1000)
    }
}

private extension String {
    /// MD5 digest rendered as lowercase hexadecimal string.
    var md5Value: String {
        let digest = Insecure.MD5.hash(data: Data(utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
} 
