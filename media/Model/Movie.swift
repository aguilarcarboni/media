//
//  Movie.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class Movie: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var watched: Bool = false
    var year: Int?
    var rating: Double?
    var tmdbRating: Double? // TMDB vote average
    var posterPath: String? // TMDB poster path
    var backdropPath: String? // TMDB backdrop path
    var runtime: Int? // in minutes
    var genres: String? // comma-separated genre names
    @Attribute(.externalStorage) var overview: String?
    var releaseDate: String? // TMDB format: yyyy-MM-dd
    var tmdbId: String?
    var directors: String? // comma-separated director names
    var cast: String? // comma-separated main cast names
    var created: Date = Date()
    var updated: Date = Date()
    
    init(
        title: String = "",
        watched: Bool = false,
        year: Int? = nil,
        rating: Double? = nil,
        tmdbRating: Double? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        runtime: Int? = nil,
        genres: String? = nil,
        overview: String? = nil,
        releaseDate: String? = nil,
        tmdbId: String? = nil,
        directors: String? = nil,
        cast: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.watched = watched
        self.year = year
        self.rating = rating
        self.tmdbRating = tmdbRating
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.runtime = runtime
        self.genres = genres
        self.overview = overview
        self.releaseDate = releaseDate
        self.tmdbId = tmdbId
        self.directors = directors
        self.cast = cast
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
    
    var directorList: [String] {
        return directors?.components(separatedBy: ", ").filter { !$0.isEmpty } ?? []
    }
    
    var castList: [String] {
        return cast?.components(separatedBy: ", ").filter { !$0.isEmpty } ?? []
    }
    
    var releaseDateFormatted: Date? {
        guard let releaseDate = releaseDate else { return nil }
        return DateFormatter.tmdbDateFormatter.date(from: releaseDate)
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
    
    func updateFromTMDB(_ tmdbMovie: TMDBMovieDetails) {
        self.title = tmdbMovie.title
        self.year = tmdbMovie.year
        self.tmdbRating = tmdbMovie.voteAverage
        self.posterPath = tmdbMovie.posterPath
        self.backdropPath = tmdbMovie.backdropPath
        self.runtime = tmdbMovie.runtime
        self.genres = tmdbMovie.genreNames.isEmpty ? nil : tmdbMovie.genreNames
        self.overview = tmdbMovie.overview
        self.releaseDate = tmdbMovie.releaseDate
        self.tmdbId = String(tmdbMovie.id)
        self.directors = tmdbMovie.directors.map { $0.name }.joined(separator: ", ")
        self.cast = tmdbMovie.cast.prefix(5).map { $0.name }.joined(separator: ", ")
        self.updated = Date()
    }
    
    // MARK: - CloudKit Support
    
    /// Creates a CloudKit-compatible dictionary representation
    func cloudKitRecord() -> [String: Any] {
        var record: [String: Any] = [:]
        record["id"] = id.uuidString
        record["title"] = title
        record["watched"] = watched
        record["year"] = year
        record["rating"] = rating
        record["tmdbRating"] = tmdbRating
        record["posterPath"] = posterPath
        record["backdropPath"] = backdropPath
        record["runtime"] = runtime
        record["genres"] = genres
        record["overview"] = overview
        record["releaseDate"] = releaseDate
        record["tmdbId"] = tmdbId
        record["directors"] = directors
        record["cast"] = cast
        record["created"] = created
        record["updated"] = updated
        return record
    }
}
