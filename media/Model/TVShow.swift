//
//  TVShow.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class TVShow: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var watched: Bool = false
    var year: Int?
    var rating: Double?
    var tmdbRating: Double? // TMDB vote average
    var posterPath: String? // TMDB poster path
    var backdropPath: String? // TMDB backdrop path
    var seasons: String? // Season information (e.g., "Season 1; Season 2; Season 3")
    var genres: String? // comma-separated genre names
    @Attribute(.externalStorage) var overview: String?
    var airDate: String? // First air date
    var tmdbId: String?
    var creators: String? // comma-separated creator names
    var cast: String? // comma-separated main cast names
    var status: String? // Status like "Ended", "Ongoing", etc.
    var numberOfSeasons: Int?
    var numberOfEpisodes: Int?
    var created: Date = Date()
    var updated: Date = Date()
    
    init(
        name: String = "",
        watched: Bool = false,
        year: Int? = nil,
        rating: Double? = nil,
        tmdbRating: Double? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        seasons: String? = nil,
        genres: String? = nil,
        overview: String? = nil,
        airDate: String? = nil,
        tmdbId: String? = nil,
        creators: String? = nil,
        cast: String? = nil,
        status: String? = nil,
        numberOfSeasons: Int? = nil,
        numberOfEpisodes: Int? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.watched = watched
        self.year = year
        self.rating = rating
        self.tmdbRating = tmdbRating
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.seasons = seasons
        self.genres = genres
        self.overview = overview
        self.airDate = airDate
        self.tmdbId = tmdbId
        self.creators = creators
        self.cast = cast
        self.status = status
        self.numberOfSeasons = numberOfSeasons
        self.numberOfEpisodes = numberOfEpisodes
        self.created = Date()
        self.updated = Date()
    }
    
    // MARK: - Computed Properties
    
    var posterURL: URL? {
        return TMDBAPIManager.shared.imageURL(path: posterPath)
    }
    
    var thumbnailURL: URL? {
        return TMDBAPIManager.shared.thumbnailURL(path: posterPath)
    }
    
    var backdropURL: URL? {
        return TMDBAPIManager.shared.imageURL(path: backdropPath)
    }
    
    var genreList: [String] {
        return genres?.components(separatedBy: ", ").filter { !$0.isEmpty } ?? []
    }
    
    var creatorList: [String] {
        return creators?.components(separatedBy: ", ").filter { !$0.isEmpty } ?? []
    }
    
    var castList: [String] {
        return cast?.components(separatedBy: ", ").filter { !$0.isEmpty } ?? []
    }
    
    var seasonList: [String] {
        return seasons?.components(separatedBy: "; ").filter { !$0.isEmpty } ?? []
    }
    
    var airDateFormatted: Date? {
        guard let airDate = airDate else { return nil }
        return DateFormatter.tmdbDateFormatter.date(from: airDate)
    }
    
    var displayRating: Double? {
        return rating ?? tmdbRating
    }
    
    var hasCompleteData: Bool {
        return tmdbId != nil && posterPath != nil && overview != nil
    }
    
    // MARK: - Actions
    
    func markAsWatched() {
        watched = true
        updated = Date()
    }
    
    func markAsUnwatched() {
        watched = false
        updated = Date()
    }
    
    func updateFromTMDB(_ tmdbShow: TMDBTVShowDetails) {
        self.name = tmdbShow.name
        self.year = tmdbShow.firstAirYear
        self.tmdbRating = tmdbShow.voteAverage
        self.posterPath = tmdbShow.posterPath
        self.backdropPath = tmdbShow.backdropPath
        self.genres = tmdbShow.genreNames.isEmpty ? nil : tmdbShow.genreNames
        self.overview = tmdbShow.overview
        self.airDate = tmdbShow.firstAirDate
        self.tmdbId = String(tmdbShow.id)
        self.creators = tmdbShow.creators.map { $0.name }.joined(separator: ", ")
        self.cast = tmdbShow.cast.prefix(5).map { $0.name }.joined(separator: ", ")
        self.status = tmdbShow.status
        self.numberOfSeasons = tmdbShow.numberOfSeasons
        self.numberOfEpisodes = tmdbShow.numberOfEpisodes
        self.updated = Date()
    }
    
    // MARK: - CloudKit Support
    
    /// Creates a CloudKit-compatible dictionary representation
    func cloudKitRecord() -> [String: Any] {
        var record: [String: Any] = [:]
        record["id"] = id.uuidString
        record["name"] = name
        record["watched"] = watched
        record["year"] = year
        record["rating"] = rating
        record["tmdbRating"] = tmdbRating
        record["posterPath"] = posterPath
        record["backdropPath"] = backdropPath
        record["seasons"] = seasons
        record["genres"] = genres
        record["overview"] = overview
        record["airDate"] = airDate
        record["tmdbId"] = tmdbId
        record["creators"] = creators
        record["cast"] = cast
        record["status"] = status
        record["numberOfSeasons"] = numberOfSeasons
        record["numberOfEpisodes"] = numberOfEpisodes
        record["created"] = created
        record["updated"] = updated
        return record
    }
}
