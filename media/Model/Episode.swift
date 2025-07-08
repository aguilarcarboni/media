//  Episode.swift
//  media
//
//  Created by AI on 08/07/2025.
//
//  Represents an individual episode of a TV show, fetched from TMDB.

import Foundation
import SwiftData

@Model
final class Episode: Identifiable {
    // Core identifiers
    var id: UUID = UUID()
    var tmdbId: Int?

    // Episode info
    var name: String = ""
    var overview: String?
    var seasonNumber: Int?
    var episodeNumber: Int?
    var airDate: String?
    var runtime: Int?
    var rating: Double?
    var stillPath: String?

    // Relationship back to parent TV show
    @Relationship(deleteRule: .nullify, inverse: \TVShow.episodes) var tvShow: TVShow?

    // Timestamps
    var created: Date = Date()
    var updated: Date = Date()

    // MARK: - Init
    init(
        tmdbId: Int? = nil,
        name: String = "",
        overview: String? = nil,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        airDate: String? = nil,
        runtime: Int? = nil,
        rating: Double? = nil,
        stillPath: String? = nil,
        tvShow: TVShow? = nil
    ) {
        self.id = UUID()
        self.tmdbId = tmdbId
        self.name = name
        self.overview = overview
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.airDate = airDate
        self.runtime = runtime
        self.rating = rating
        self.stillPath = stillPath
        self.tvShow = tvShow
        self.created = Date()
        self.updated = Date()
    }

    // MARK: - Computed
    var stillURL: URL? { TMDBAPIManager.shared.imageURL(path: stillPath) }
    var thumbnailURL: URL? { TMDBAPIManager.shared.thumbnailURL(path: stillPath) }
} 