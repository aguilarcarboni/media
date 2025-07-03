//
//  Book.swift
//  media
//
//  Created by Andrés on 01/07/2025.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class Book: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var author: String = ""
    var read: Bool = false
    var year: Int?
    var rating: Double? // user rating
    var appleRating: Double? // average user rating from store
    var coverURLString: String? // artwork URL
    @Attribute(.externalStorage) var synopsis: String?
    var releaseDate: Date?
    var appleBookId: String?
    var genres: String? // comma separated
    var created: Date = Date()
    var updated: Date = Date()
    
    init(
        title: String = "",
        author: String = "",
        read: Bool = false,
        year: Int? = nil,
        rating: Double? = nil,
        appleRating: Double? = nil,
        coverURLString: String? = nil,
        synopsis: String? = nil,
        releaseDate: Date? = nil,
        appleBookId: String? = nil,
        genres: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.read = read
        self.year = year
        self.rating = rating
        self.appleRating = appleRating
        self.coverURLString = coverURLString
        self.synopsis = synopsis
        self.releaseDate = releaseDate
        self.appleBookId = appleBookId
        self.genres = genres
        self.created = Date()
        self.updated = Date()
    }
    
    // MARK: Computed
    var coverURL: URL? { URL(string: coverURLString ?? "") }
    var genreList: [String] { genres?.components(separatedBy: ", ").filter{ !$0.isEmpty } ?? [] }
    var displayRating: Double? { rating ?? appleRating }
    var hasCompleteData: Bool { appleBookId != nil && coverURLString != nil && synopsis != nil }
    
    // MARK: Actions
    func markAsRead() { read = true; updated = Date() }
    func markAsUnread() { read = false; updated = Date() }
    
    func updateFromAppleBooks(_ details: AppleBookDetails) {
        self.title = details.trackName ?? ""
        self.author = details.artistName ?? ""
        self.appleRating = details.averageUserRating
        self.coverURLString = details.artworkUrl100
        self.year = details.year
        if let releaseISO = details.releaseDate, let date = ISO8601DateFormatter().date(from: releaseISO) { self.releaseDate = date }
        self.synopsis = details.description
        self.appleBookId = String(details.trackId)
        self.genres = details.genreNames.isEmpty ? nil : details.genreNames
        self.updated = Date()
    }
    
    // CloudKit
    func cloudKitRecord() -> [String: Any] {
        var record: [String: Any] = [:]
        record["id"] = id.uuidString
        record["title"] = title
        record["author"] = author
        record["read"] = read
        record["year"] = year
        record["rating"] = rating
        record["appleRating"] = appleRating
        record["coverURLString"] = coverURLString
        record["synopsis"] = synopsis
        record["releaseDate"] = releaseDate
        record["appleBookId"] = appleBookId
        record["genres"] = genres
        record["created"] = created
        record["updated"] = updated
        return record
    }
} 