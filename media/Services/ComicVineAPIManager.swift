//  ComicVineAPIManager.swift
//  media
//
//  Created by Migration Script on 07/07/2025.
//
//  Replaces the deprecated MarvelAPIManager.
//  Handles searching comics & fetching comic details through the ComicVine API.
//

import Foundation
import Combine

// MARK: - ComicVine API Manager
@MainActor
final class ComicVineAPIManager: ObservableObject {
    static let shared = ComicVineAPIManager()

    // TODO: Replace with your actual ComicVine key. Grab one at https://comicvine.gamespot.com/api/
    private let apiKey: String = "e083e4de9e841458cc82203eb2573f5f9f0a7b9c"
    private let baseURL: String = "https://comicvine.gamespot.com/api"

    private init() {}

    // MARK: - Generic Helpers
    private func endpoint(_ path: String) -> URL { URL(string: baseURL + path)! }

    private func buildRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Recommended by ComicVine docs to avoid blocking
        request.setValue("media.app", forHTTPHeaderField: "User-Agent")
        return request
    }

    private func performRequest<T: Decodable>(url: URL, decode type: T.Type) async throws -> T {
        let request = buildRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("🚨 ComicVineAPI: Error \(response)")
            throw ComicVineError.networkError
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Issue Search
    func searchIssues(query: String, limit: Int = 20, offset: Int = 0, fieldList: String = "id,name,issue_number,cover_date,description,page_count,image,volume,person_credits,character_credits,team_credits,concept_credits,story_arc_credits") async throws -> [ComicVineIssueSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        var components = URLComponents(url: endpoint("/issues/"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "filter", value: "name:\(query)"),
            URLQueryItem(name: "field_list", value: fieldList),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components.url else { throw ComicVineError.invalidURL }
        let wrapper: ComicVineListWrapper<ComicVineIssue> = try await performRequest(url: url, decode: ComicVineListWrapper<ComicVineIssue>.self)
        guard (wrapper.statusCode ?? 1) == 1 else {
            throw ComicVineError.apiError(wrapper.error)
        }
        return wrapper.results.map { ComicVineIssueSearchResult(from: $0) }
    }

    // MARK: - Issue Details
    func getIssue(id: Int, fieldList: String = "id,name,issue_number,cover_date,description,page_count,image,volume,person_credits,character_credits,team_credits,concept_credits,story_arc_credits") async throws -> ComicVineIssueDetails {
        // ComicVine uses the "4000-<id>" format for issue lookup
        var components = URLComponents(url: endpoint("/issue/4000-\(id)/"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "field_list", value: fieldList),
            URLQueryItem(name: "include", value: "character_credits,team_credits,person_credits")
        ]
        guard let url = components.url else { throw ComicVineError.invalidURL }
        let wrapper: ComicVineSingleWrapper<ComicVineIssue> = try await performRequest(url: url, decode: ComicVineSingleWrapper<ComicVineIssue>.self)
        guard (wrapper.statusCode ?? 1) == 1 else {
            throw ComicVineError.apiError(wrapper.error)
        }
        let details = ComicVineIssueDetails(from: wrapper.results)
        return details
    }

    // MARK: - Utility
    func thumbnailURL(for path: String?) -> URL? {
        guard let path else { return nil }
        return URL(string: path)
    }
}

// MARK: - Errors
enum ComicVineError: Error, LocalizedError {
    case invalidURL
    case networkError
    case apiError(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Comic Vine URL"
        case .networkError: return "Network error contacting Comic Vine"
        case .apiError(let message): return message
        case .notFound: return "Resource not found"
        }
    }
}

// MARK: - Generic Response Containers
struct ComicVineListWrapper<T: Decodable>: Decodable {
    let error: String
    let limit: Int?
    let offset: Int?
    let numberOfPageResults: Int?
    let numberOfTotalResults: Int?
    let statusCode: Int?
    let results: [T]
}

struct ComicVineSingleWrapper<T: Decodable>: Decodable {
    let error: String
    let statusCode: Int?

    // ComicVine sometimes uses "results" (plural) or "result" (singular) depending on endpoint.
    // We normalize everything into a single non-optional `results` property.
    let results: T

    enum CodingKeys: String, CodingKey {
        case error
        case statusCode = "status_code"
        case result
        case results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.error = try container.decode(String.self, forKey: .error)
        self.statusCode = try? container.decodeIfPresent(Int.self, forKey: .statusCode)
        if let plural = try? container.decode(T.self, forKey: .results) {
            self.results = plural
        } else if let singular = try? container.decode(T.self, forKey: .result) {
            self.results = singular
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "No result(s)/result key found."))
        }
    }
}

// MARK: - Core API Models
struct ComicVineIssue: Decodable {
    let id: Int
    let name: String?
    let issueNumber: String
    let coverDate: String?
    let description: String?
    let pageCount: Int?
    let volume: ComicVineVolume?
    let image: ComicVineImage?
    let characterCredits: [ComicVineCharacter]?
    let personCredits: [ComicVinePerson]?
    let teamCredits: [ComicVineTeam]?
    let conceptCredits: [ComicVineConcept]?
    let storyArcCredits: [ComicVineStoryArc]?

    // Leverage JSONDecoder.convertFromSnakeCase – snake_case keys map automatically
    enum CodingKeys: String, CodingKey {
        case id, name, volume, image, description, issueNumber, coverDate, pageCount,
             characterCredits, personCredits, teamCredits, conceptCredits, storyArcCredits
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        // `issue_number` can arrive as a String ("12") **or** an Int (12).  Decode flexibly:
        if let str = try? container.decode(String.self, forKey: .issueNumber) {
            issueNumber = str
        } else if let int = try? container.decode(Int.self, forKey: .issueNumber) {
            issueNumber = String(int)
        } else {
            issueNumber = "0"
        }
        coverDate = try container.decodeIfPresent(String.self, forKey: .coverDate)
        description = try container.decodeIfPresent(String.self, forKey: .description)

        // page_count can be Int, String, or null
        if let intVal = try? container.decodeIfPresent(Int.self, forKey: .pageCount) {
            pageCount = intVal
        } else if let strVal = try? container.decodeIfPresent(String.self, forKey: .pageCount),
                  let intFromStr = Int(strVal) {
            pageCount = intFromStr
        } else {
            pageCount = nil
        }

        volume = try container.decodeIfPresent(ComicVineVolume.self, forKey: .volume)
        image = try container.decodeIfPresent(ComicVineImage.self, forKey: .image)

        // These arrays decode straight through now that keys match
        characterCredits = try container.decodeIfPresent([ComicVineCharacter].self, forKey: .characterCredits)
        personCredits    = try container.decodeIfPresent([ComicVinePerson].self,    forKey: .personCredits)
        teamCredits      = try container.decodeIfPresent([ComicVineTeam].self,      forKey: .teamCredits)
        conceptCredits   = try container.decodeIfPresent([ComicVineConcept].self,   forKey: .conceptCredits)
        storyArcCredits  = try container.decodeIfPresent([ComicVineStoryArc].self,  forKey: .storyArcCredits)
    }
}

struct ComicVineVolume: Codable {
    let id: Int?
    let name: String?
    let startYear: String?
    let countOfIssues: Int?
    let image: ComicVineImage?
    let deck: String?
    let description: String?
    let publisher: ComicVinePublisher?
}

struct ComicVineImage: Codable {
    let originalUrl: String?
    let thumbUrl: String?
}

struct ComicVineCharacter: Codable { let name: String? }

struct ComicVinePerson: Codable { let name: String?; let role: String? }

struct ComicVineTeam: Codable { let name: String? }

struct ComicVinePublisher: Codable {
    let name: String?
}

struct ComicVineConcept: Codable { let name: String? }
struct ComicVineStoryArc: Codable { let name: String? }

// MARK: - View-Specific Search Result
struct ComicVineIssueSearchResult: Identifiable {
    let id: Int
    let title: String
    let issueNumber: Int
    let year: Int?
    let thumbnailURL: URL?
    let overview: String?

    init(from issue: ComicVineIssue) {
        self.id = issue.id
        self.title = issue.name ?? "Unknown Title"
        self.issueNumber = Int(issue.issueNumber.filter( { $0.isNumber } )) ?? 0
        if let dateStr = issue.coverDate, let yearInt = Int(dateStr.prefix(4)) {
            self.year = yearInt
        } else { self.year = nil }
        self.thumbnailURL = URL(string: issue.image?.thumbUrl ?? "")
        self.overview = issue.description?.htmlStripped
    }
}

// MARK: - Detailed View Model
struct ComicVineIssueDetails {
    let id: Int
    let title: String
    let issueNumber: Int
    let description: String?
    let pageCount: Int?
    let coverDate: String?
    let volumeName: String?
    let coverURL: String?
    let thumbnailURL: String?
    let writers: [String]
    let artists: [String]
    let characters: [String]
    let concepts: [String]
    let teams: [String]
    let storyArcs: [String]

    init(from issue: ComicVineIssue) {
        self.id = issue.id
        self.title = issue.name ?? "Unknown Title"
        self.issueNumber = Int(issue.issueNumber.filter({ $0.isNumber })) ?? 0
        self.description = issue.description?.htmlStripped
        self.pageCount = issue.pageCount
        self.coverDate = issue.coverDate
        self.volumeName = issue.volume?.name
        self.coverURL = issue.image?.originalUrl
        self.thumbnailURL = issue.image?.thumbUrl
        // Parse creators
        // Broaden creator-role parsing – ComicVine uses many different labels (e.g. "penciler", "inker", "colorist")
        let people = issue.personCredits ?? []

        let writerKeywords: [String] = [
            "writer", "script", "story", "plot"
        ]

        // Anything that isn’t classified as a writer falls into the artists bucket for now
        var tmpWriters: Set<String> = []
        var tmpArtists: Set<String> = []

        for person in people {
            let role = (person.role ?? "").lowercased()
            let name = person.name ?? ""
            guard !name.isEmpty else { continue }

            if writerKeywords.contains(where: { role.contains($0) }) {
                tmpWriters.insert(name)
            } else {
                tmpArtists.insert(name)
            }
        }

        self.writers = Array(tmpWriters).sorted()
        self.artists = Array(tmpArtists).sorted()
        self.characters = (issue.characterCredits ?? []).compactMap { $0.name }
        self.concepts = (issue.conceptCredits ?? []).compactMap { $0.name }
        self.teams = (issue.teamCredits ?? []).compactMap { $0.name }
        self.storyArcs = (issue.storyArcCredits ?? []).compactMap { $0.name }
    }

    // Helper to convert into local Comic entity
    func toComic() -> Comic {
        Comic(
            comicVineId: id,
            title: title,
            issueNumber: issueNumber,
            seriesName: volumeName,
            publicationDate: coverDate,
            pageCount: pageCount,
            synopsis: description,
            coverURLString: coverURL,
            thumbnailURLString: thumbnailURL,
            writers: writers.joined(separator: ", "),
            artists: artists.joined(separator: ", "),
            characters: characters.joined(separator: ", "),
            teams: teams.joined(separator: ", "),
            concepts: concepts.joined(separator: ", "),
            storyArcs: storyArcs.joined(separator: ", ")
        )
    }
}

// MARK: - Volume Search Result (for UI)
struct ComicVineVolumeSearchResult: Identifiable {
    let id: Int
    let title: String
    let startYear: Int?
    let issueCount: Int?
    let thumbnailURL: URL?
    let overview: String?

    init(from volume: ComicVineVolume) {
        self.id = volume.id ?? 0
        self.title = volume.name ?? "Unknown Title"
        self.startYear = Int(volume.startYear ?? "")
        self.issueCount = volume.countOfIssues
        self.thumbnailURL = URL(string: volume.image?.thumbUrl ?? "")
        self.overview = volume.deck?.htmlStripped ?? volume.description?.htmlStripped
    }
}

// MARK: - Volume Detailed Model
struct ComicVineVolumeDetails {
    let id: Int
    let name: String
    let startYear: Int?
    let issueCount: Int?
    let description: String?
    let coverURL: String?
    let thumbnailURL: String?
    let publisher: String?

    init(from volume: ComicVineVolume) {
        self.id = volume.id ?? 0
        self.name = volume.name ?? "Unknown Title"
        self.startYear = Int(volume.startYear ?? "")
        self.issueCount = volume.countOfIssues
        self.description = volume.description?.htmlStripped ?? volume.deck?.htmlStripped
        self.coverURL = volume.image?.originalUrl
        self.thumbnailURL = volume.image?.thumbUrl
        self.publisher = volume.publisher?.name
    }

    // Convert to local Volume entity
    func toVolume() -> Volume {
        Volume(
            comicVineId: id,
            name: name,
            startYear: startYear,
            countOfIssues: issueCount,
            summary: description,
            publisher: publisher,
            coverURLString: coverURL,
            thumbnailURLString: thumbnailURL
        )
    }
}

// MARK: - Volume API Methods
extension ComicVineAPIManager {
    func searchVolumes(query: String, limit: Int = 20, offset: Int = 0, fieldList: String = "id,name,start_year,count_of_issues,image,deck,description,publisher") async throws -> [ComicVineVolumeSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        var components = URLComponents(url: endpoint("/volumes/"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "filter", value: "name:\(query)"),
            URLQueryItem(name: "field_list", value: fieldList),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components.url else { throw ComicVineError.invalidURL }
        let wrapper: ComicVineListWrapper<ComicVineVolume> = try await performRequest(url: url, decode: ComicVineListWrapper<ComicVineVolume>.self)
        // Debug: log number of issue search results
        guard (wrapper.statusCode ?? 1) == 1 else { throw ComicVineError.apiError(wrapper.error) }
        return wrapper.results.map { ComicVineVolumeSearchResult(from: $0) }
    }

    func getVolume(id: Int, fieldList: String = "id,name,start_year,count_of_issues,image,deck,description,publisher") async throws -> ComicVineVolumeDetails {
        var components = URLComponents(url: endpoint("/volume/4050-\(id)/"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "field_list", value: fieldList)
        ]
        guard let url = components.url else { throw ComicVineError.invalidURL }
        let wrapper: ComicVineSingleWrapper<ComicVineVolume> = try await performRequest(url: url, decode: ComicVineSingleWrapper<ComicVineVolume>.self)
        guard (wrapper.statusCode ?? 1) == 1 else { throw ComicVineError.apiError(wrapper.error) }
        return ComicVineVolumeDetails(from: wrapper.results)
    }

    // Fetch issues associated with a volume
    func issuesForVolume(volumeId: Int, limit: Int = 100, offset: Int = 0, fieldList: String = "id,name,issue_number,cover_date,description,page_count,image,volume,person_credits,character_credits,team_credits,concept_credits,story_arc_credits") async throws -> [ComicVineIssueSearchResult] {
        var components = URLComponents(url: endpoint("/issues/"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "filter", value: "volume:\(volumeId)"),
            URLQueryItem(name: "field_list", value: fieldList),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components.url else { throw ComicVineError.invalidURL }
        let wrapper: ComicVineListWrapper<ComicVineIssue> = try await performRequest(url: url, decode: ComicVineListWrapper<ComicVineIssue>.self)
        guard (wrapper.statusCode ?? 1) == 1 else { throw ComicVineError.apiError(wrapper.error) }
        return wrapper.results.map { ComicVineIssueSearchResult(from: $0) }
    }
}

struct ComicVineCharacterSimple: Identifiable, Decodable {
    let id: Int
    let name: String?
}

extension ComicVineAPIManager {
    /// Fetch characters that appear in any issue of a given volume
    func charactersForVolume(volumeId: Int, limit: Int = 100, offset: Int = 0, fieldList: String = "id,name") async throws -> [ComicVineCharacterSimple] {
        var components = URLComponents(url: endpoint("/characters/"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "filter", value: "volume:\(volumeId)"),
            URLQueryItem(name: "field_list", value: fieldList),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components.url else { throw ComicVineError.invalidURL }
        let wrapper: ComicVineListWrapper<ComicVineCharacterSimple> = try await performRequest(url: url, decode: ComicVineListWrapper<ComicVineCharacterSimple>.self)
        guard (wrapper.statusCode ?? 1) == 1 else { throw ComicVineError.apiError(wrapper.error) }
        return wrapper.results
    }
}

struct ComicVineTeamSimple: Identifiable, Decodable { let id: Int; let name: String? }

extension ComicVineAPIManager {

    /// Fetch teams that appear in any issue of a given volume.
    func teamsForVolume(volumeId: Int, limit: Int = 100, offset: Int = 0, fieldList: String = "id,name") async throws -> [ComicVineTeamSimple] {
        var components = URLComponents(url: endpoint("/teams/"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "filter", value: "volume:\(volumeId)"),
            URLQueryItem(name: "field_list", value: fieldList),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components.url else { throw ComicVineError.invalidURL }
        let wrapper: ComicVineListWrapper<ComicVineTeamSimple> = try await performRequest(url: url, decode: ComicVineListWrapper<ComicVineTeamSimple>.self)
        guard (wrapper.statusCode ?? 1) == 1 else { throw ComicVineError.apiError(wrapper.error) }
        return wrapper.results
    }
} 
