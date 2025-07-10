//
//  ReadingListItem.swift
//  media
//
//  Created by AI on [date]
//
//  Junction model representing a comic within a reading list, with ordering and metadata.
//

import Foundation
import SwiftData

@Model
final class ReadingListItem: Identifiable {
    // Core identifiers
    var id: UUID = UUID()
    
    // Position in the reading list (0-based)
    var position: Int = 0
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \ReadingList.items) var readingList: ReadingList?
    
    @Relationship(inverse: \Comic.readingListItems)
    var comic: Comic?
    
    // Item-specific metadata within this reading list
    var notes: String? // Notes specific to this comic in this reading list context
    var isRead: Bool = false // Completion status within this specific reading list
    var readDate: Date? // When this item was read in this list
    
    // Optional metadata for reading order context
    var contextualNote: String? // e.g., "Read after Secret Wars #8", "Skip if you've read Civil War"
    var isOptional: Bool = false // Whether this issue is optional in the reading order
    var isSkipped: Bool = false // Whether user chose to skip this issue
    
    // Visual indicators
    var highlightColor: String? // Custom highlight color for this item
    var isBookmarked: Bool = false // Quick bookmark for important issues
    
    // Timestamps
    var created: Date = Date()
    var updated: Date = Date()
    
    // MARK: - Init
    init(
        comic: Comic? = nil,
        position: Int = 0,
        readingList: ReadingList? = nil,
        notes: String? = nil,
        contextualNote: String? = nil,
        isOptional: Bool = false,
        highlightColor: String? = nil
    ) {
        self.id = UUID()
        self.comic = comic
        self.position = position
        self.readingList = readingList
        self.notes = notes
        self.contextualNote = contextualNote
        self.isOptional = isOptional
        self.highlightColor = highlightColor
        self.created = Date()
        self.updated = Date()
    }
    
    // MARK: - Computed Properties
    
    // Use the comic's read status if item-specific status isn't set
    var effectiveReadStatus: Bool {
        // Prioritize item-specific read status, fallback to comic's global status
        return isRead || (comic?.read == true)
    }
    
    var displayTitle: String {
        guard let comic = comic else { return "Unknown Issue" }
        
        if let seriesName = comic.seriesName, let issueNumber = comic.issueNumber {
            return "\(seriesName) #\(issueNumber)"
        } else if !comic.title.isEmpty {
            return comic.title
        } else {
            return "Issue #\(comic.issueNumber ?? 0)"
        }
    }
    
    var displaySubtitle: String {
        var parts: [String] = []
        
        if let comic = comic {
            if let publicationDate = comic.publicationDate {
                parts.append(publicationDate)
            }
            if let pageCount = comic.pageCount {
                parts.append("\(pageCount) pages")
            }
        }
        
        if isOptional {
            parts.append("Optional")
        }
        
        return parts.joined(separator: " • ")
    }
    
    // MARK: - Actions
    func markAsRead() {
        isRead = true
        readDate = Date()
        updated = Date()
        
        // Optionally also mark the comic globally as read
        comic?.markAsRead()
        
        // Update the reading list's completion counts
        readingList?.updateCounts()
    }
    
    func markAsUnread() {
        isRead = false
        readDate = nil
        updated = Date()
        readingList?.updateCounts()
    }
    
    func skip() {
        isSkipped = true
        updated = Date()
        readingList?.updateCounts()
    }
    
    func unskip() {
        isSkipped = false
        updated = Date()
        readingList?.updateCounts()
    }
    
    func toggleBookmark() {
        isBookmarked.toggle()
        updated = Date()
    }
    
    func updatePosition(_ newPosition: Int) {
        position = newPosition
        updated = Date()
    }
} 
