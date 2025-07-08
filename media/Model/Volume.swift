//
//  Volume.swift
//  media
//
//  Created by AI on 07/07/2025.
//
//  Represents a Comic Vine Volume.
//

import Foundation
import SwiftData

@Model
final class Volume: Identifiable {
    // Local identifier
    var id: UUID = UUID()

    // ComicVine identifiers
    var comicVineId: Int?

    // Basic info
    var name: String = ""
    var startYear: Int?
    var countOfIssues: Int?
    @Attribute(.externalStorage) var summary: String? // deck / description trimmed

    // Publisher (simple string for now; could be own entity in future)
    var publisher: String?

    // Images
    var coverURLString: String?
    var thumbnailURLString: String?

    // Relationship to issues (comics) in this volume
    @Relationship(deleteRule: .cascade) var issues: [Comic]? = nil

    // User tracking
    var read: Bool = false
    var readDate: Date?
    var rating: Double?

    // Metadata
    var created: Date = Date()
    var updated: Date = Date()

    // MARK: - Init
    init(
        comicVineId: Int? = nil,
        name: String = "",
        startYear: Int? = nil,
        countOfIssues: Int? = nil,
        summary: String? = nil,
        publisher: String? = nil,
        coverURLString: String? = nil,
        thumbnailURLString: String? = nil,
        issues: [Comic]? = nil,
        read: Bool = false,
        readDate: Date? = nil,
        rating: Double? = nil
    ) {
        self.id = UUID()
        self.comicVineId = comicVineId
        self.name = name
        self.startYear = startYear
        self.countOfIssues = countOfIssues
        self.summary = summary
        self.publisher = publisher
        self.coverURLString = coverURLString
        self.thumbnailURLString = thumbnailURLString
        self.issues = issues
        // Add user tracking
        self.read = read
        self.readDate = readDate
        self.rating = rating
        self.created = Date()
        self.updated = Date()
    }

    // MARK: - Computed
    var coverURL: URL? { URL(string: coverURLString ?? "") }
    var thumbnailURL: URL? { URL(string: thumbnailURLString ?? "") }
    /// Returns the user's rating if available.
    var displayRating: Double? { rating }

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
} 