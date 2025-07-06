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
    var marvelId: Int?
    
    // Basic info
    var title: String = ""
    var issueNumber: Int?
    var seriesName: String?
    var publicationDate: String? // ISO-8601 string returned by Marvel API
    var format: String?
    var pageCount: Int?
    @Attribute(.externalStorage) var synopsis: String?
    
    // Media
    var coverURLString: String?
    var thumbnailURLString: String?
    
    // Creators & characters
    var writers: String? // comma-separated
    var artists: String?
    var characters: String?
    
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
        marvelId: Int? = nil,
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
        read: Bool = false,
        readDate: Date? = nil,
        rating: Double? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.marvelId = marvelId
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
        self.read = read
        self.readDate = readDate
        self.rating = rating
        self.notes = notes
        self.created = Date()
        self.updated = Date()
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
    
    // Update from Marvel API details
    func updateFromMarvel(_ details: MarvelComicDetails) {
        self.marvelId = details.id
        self.title = details.title
        self.issueNumber = Int(details.issueNumber)
        self.seriesName = details.series?.name
        self.publicationDate = details.publicationDate
        self.format = details.format
        self.pageCount = details.pageCount
        self.synopsis = details.description
        self.coverURLString = details.coverURLString
        self.thumbnailURLString = details.thumbnailURLString
        self.writers = details.writers.joined(separator: ", ")
        self.artists = details.artists.joined(separator: ", ")
        self.characters = details.characters.joined(separator: ", ")
        self.updated = Date()
    }
} 