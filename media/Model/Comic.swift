//
//  Comic.swift
//  media
//
//  Created by Andrés on 6/7/2025.
//

import Foundation
import SwiftData

@Model
final class Comic: Identifiable {
    // Core identifiers
    var id: UUID = UUID()
    var comicVineId: Int?
    
    // Basic info
    var title: String = ""
    var issueNumber: Int?
    var seriesName: String?
    var publicationDate: String? // Publish/cover date as returned by ComicVine (YYYY-MM-DD)
    var format: String?
    var pageCount: Int?
    @Attribute(.externalStorage) var synopsis: String?
    
    // Extended metadata & tracking
    @Relationship(deleteRule: .nullify, inverse: \Volume.issues) var volume: Volume?
    
    // Storyline / Event
    var storylineName: String?
    var universe: String?
    var eventType: String? // Crossover, Tie-in, One-shot…
    var relatedIssues: String? // Free-form list or range, e.g. "#3–#5"
    
    // Logistics / Purchase
    var owned: Bool = false
    var purchaseDate: Date?
    var location: String? // Shelf or storage location
    var collectedEdition: Bool = false // Part of a trade paperback / collection
    
    // Reading order
    var readingOrderPosition: Int?
    
    // Media
    var coverURLString: String?
    var thumbnailURLString: String?
    
    // Creators & characters
    var writers: String? // comma-separated
    var artists: String?
    var characters: String?
    var teams: String? // comma-separated team names
    var concepts: String? // New – concepts/universes (comma-separated)
    var storyArcs: String? // New – story arcs / events (comma-separated)
    
    // User tracking
    var read: Bool = false
    var readDate: Date?
    var rating: Double?
    var notes: String?
    
    // Timestamps
    var created: Date = Date()
    var updated: Date = Date()
    
    // MARK: - Init
    init(
        comicVineId: Int? = nil,
        title: String = "",
        issueNumber: Int? = nil,
        seriesName: String? = nil,
        publicationDate: String? = nil,
        format: String? = nil,
        pageCount: Int? = nil,
        synopsis: String? = nil,
        coverURLString: String? = nil,
        thumbnailURLString: String? = nil,
        writers: String? = nil,
        artists: String? = nil,
        characters: String? = nil,
        teams: String? = nil,
        concepts: String? = nil,
        storyArcs: String? = nil,
        read: Bool = false,
        readDate: Date? = nil,
        rating: Double? = nil,
        notes: String? = nil,
        volume: Volume? = nil,
        storylineName: String? = nil,
        universe: String? = nil,
        eventType: String? = nil,
        relatedIssues: String? = nil,
        owned: Bool = false,
        purchaseDate: Date? = nil,
        location: String? = nil,
        collectedEdition: Bool = false,
        readingOrderPosition: Int? = nil
    ) {
        self.id = UUID()
        self.comicVineId = comicVineId
        self.title = title
        self.issueNumber = issueNumber
        self.seriesName = seriesName
        self.publicationDate = publicationDate
        self.format = format
        self.pageCount = pageCount
        self.synopsis = synopsis
        self.coverURLString = coverURLString
        self.thumbnailURLString = thumbnailURLString
        self.writers = writers
        self.artists = artists
        self.characters = characters
        self.teams = teams
        self.concepts = concepts
        self.storyArcs = storyArcs
        self.read = read
        self.readDate = readDate
        self.rating = rating
        self.notes = notes
        self.created = Date()
        self.updated = Date()
        self.volume = volume
        self.storylineName = storylineName
        self.universe = universe
        self.eventType = eventType
        self.relatedIssues = relatedIssues
        self.owned = owned
        self.purchaseDate = purchaseDate
        self.location = location
        self.collectedEdition = collectedEdition
        self.readingOrderPosition = readingOrderPosition
    }
    
    // MARK: - Computed properties
    var coverURL: URL? {
        guard let coverURLString else { return nil }
        return URL(string: coverURLString)
    }
    
    var thumbnailURL: URL? {
        guard let thumbnailURLString else { return nil }
        return URL(string: thumbnailURLString)
    }
    
    // MARK: - Actions
    func markAsRead() {
        read = true
        readDate = Date()
        updated = Date()
    }
    
    func markAsUnread() {
        read = false
        updated = Date()
    }
    
    // Update from Comic Vine details
    func updateFromComicVine(_ details: ComicVineIssueDetails) {
        self.comicVineId = details.id
        self.title = details.title
        self.issueNumber = details.issueNumber
        self.seriesName = details.volumeName
        self.publicationDate = details.coverDate
        self.pageCount = details.pageCount
        self.synopsis = details.description
        self.coverURLString = details.coverURL
        self.thumbnailURLString = details.thumbnailURL
        self.writers = details.writers.joined(separator: ", ")
        self.artists = details.artists.joined(separator: ", ")
        self.characters = details.characters.joined(separator: ", ")
        self.teams = details.teams.joined(separator: ", ")
        self.concepts = details.concepts.joined(separator: ", ")
        self.storyArcs = details.storyArcs.joined(separator: ", ")
        self.updated = Date()
        self.volume = nil // set externally if needed
    }
} 