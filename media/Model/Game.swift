//
//  Game.swift
//  media
//
//  Created by Andrés on 30/6/2025.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class Game: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var played: Bool = false
    var year: Int?
    var rating: Double?
    var igdbRating: Double?
    var coverImageID: String?
    var genres: String? // comma-separated genre names
    var platforms: String? // comma-separated platform names
    @Attribute(.externalStorage) var summary: String?
    var releaseDate: Date?
    var igdbId: String?
    var created: Date = Date()
    var updated: Date = Date()
    
    init(
        name: String = "",
        played: Bool = false,
        year: Int? = nil,
        rating: Double? = nil,
        igdbRating: Double? = nil,
        coverImageID: String? = nil,
        genres: String? = nil,
        platforms: String? = nil,
        summary: String? = nil,
        releaseDate: Date? = nil,
        igdbId: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.played = played
        self.year = year
        self.rating = rating
        self.igdbRating = igdbRating
        self.coverImageID = coverImageID
        self.genres = genres
        self.platforms = platforms
        self.summary = summary
        self.releaseDate = releaseDate
        self.igdbId = igdbId
        self.created = Date()
        self.updated = Date()
    }
    
    // MARK: - Computed Properties
    
    var coverURL: URL? {
        return IGDBAPIManager.shared.imageURL(imageID: coverImageID, size: .original)
    }
    
    var thumbnailURL: URL? {
        return IGDBAPIManager.shared.imageURL(imageID: coverImageID)
    }
    
    var genreList: [String] {
        return genres?.components(separatedBy: ", ").filter { !$0.isEmpty } ?? []
    }
    
    var platformList: [String] {
        return platforms?.components(separatedBy: ", ").filter { !$0.isEmpty } ?? []
    }
    
    var displayRating: Double? {
        return rating ?? igdbRating
    }
    
    var hasCompleteData: Bool {
        return igdbId != nil && coverImageID != nil && summary != nil
    }
    
    // MARK: - Actions
    func markAsPlayed() {
        played = true
        updated = Date()
    }
    
    func markAsUnplayed() {
        played = false
        updated = Date()
    }
    
    func updateFromIGDB(_ igdbGame: IGDBGameDetails) {
        self.name = igdbGame.name ?? ""
        if let date = igdbGame.releaseDate {
            self.year = Calendar.current.component(.year, from: date)
            self.releaseDate = date
        }
        self.coverImageID = igdbGame.cover?.image_id
        self.genres = igdbGame.genreNames.isEmpty ? nil : igdbGame.genreNames
        self.platforms = igdbGame.platformNames.joined(separator: ", ")
        self.summary = igdbGame.summary
        self.igdbId = String(igdbGame.id)
        self.updated = Date()
    }
    
    // MARK: - CloudKit Support
    func cloudKitRecord() -> [String: Any] {
        var record: [String: Any] = [:]
        record["id"] = id.uuidString
        record["name"] = name
        record["played"] = played
        record["year"] = year
        record["rating"] = rating
        record["igdbRating"] = igdbRating
        record["coverImageID"] = coverImageID
        record["genres"] = genres
        record["platforms"] = platforms
        record["summary"] = summary
        record["releaseDate"] = releaseDate
        record["igdbId"] = igdbId
        record["created"] = created
        record["updated"] = updated
        return record
    }
} 