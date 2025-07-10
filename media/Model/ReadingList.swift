//
//  ReadingList.swift
//  media
//
//  Created by AI on [date]
//
//  Represents a user-created reading list (like a playlist) for comics.
//

import Foundation
import SwiftData

@Model
final class ReadingList: Identifiable {
    // Core identifiers
    var id: UUID = UUID()
    
    // Basic info
    var name: String = ""
    @Attribute(.externalStorage) var listDescription: String?
    var creator: String? // User who created the list
    
    // List metadata
    var isPublic: Bool = false
    var totalIssues: Int = 0 // Computed/cached count
    var estimatedReadingTime: TimeInterval? // In minutes
    
    // Visual customization
    var coverImageURL: String? // Custom cover or auto-generated from first issue
    var colorTheme: String? // Custom color theme for the list
    
    // Relationship to reading list items (ordered)
    @Relationship(deleteRule: .cascade) var items: [ReadingListItem]? = []
    
    // User tracking
    var currentPosition: Int = 0 // Current reading position in the list
    var completedIssues: Int = 0 // Number of issues marked as read
    var lastReadDate: Date?
    var isCompleted: Bool = false
    
    // List metadata
    var isFavorite: Bool = false
    var tags: String? // Comma-separated tags like "Hickman, Marvel, Event"
    
    // Timestamps
    var created: Date = Date()
    var updated: Date = Date()
    
    // MARK: - Init
    init(
        name: String = "",
        listDescription: String? = nil,
        creator: String? = nil,
        isPublic: Bool = false,
        coverImageURL: String? = nil,
        colorTheme: String? = nil,
        tags: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.listDescription = listDescription
        self.creator = creator
        self.isPublic = isPublic
        self.coverImageURL = coverImageURL
        self.colorTheme = colorTheme
        self.tags = tags
        self.isFavorite = isFavorite
        self.created = Date()
        self.updated = Date()
    }
    
    // MARK: - Computed Properties
    var coverURL: URL? {
        guard let coverImageURL else { return nil }
        return URL(string: coverImageURL)
    }
    
    var completionPercentage: Double {
        guard totalIssues > 0 else { return 0.0 }
        return Double(completedIssues) / Double(totalIssues)
    }
    
    var orderedItems: [ReadingListItem] {
        return (items ?? []).sorted { $0.position < $1.position }
    }
    
    // MARK: - Actions
    func updateCounts() {
        let sortedItems = orderedItems
        totalIssues = sortedItems.count
        completedIssues = sortedItems.filter { $0.comic?.read == true }.count
        updated = Date()
    }
    
    func addComic(_ comic: Comic, at position: Int? = nil) {
        let newPosition = position ?? ((items?.map { $0.position }.max() ?? -1) + 1)
        let item = ReadingListItem(comic: comic, position: newPosition, readingList: self)
        
        if items == nil {
            items = []
        }
        items?.append(item)
        updateCounts()
    }
    
    func removeComic(_ comic: Comic) {
        items?.removeAll { $0.comic?.id == comic.id }
        updateCounts()
    }
    
    func moveItem(from source: Int, to destination: Int) {
        guard let items = items else { return }
        let sortedItems = orderedItems
        guard source < sortedItems.count && destination < sortedItems.count else { return }
        
        // Update positions
        let movedItem = sortedItems[source]
        sortedItems.enumerated().forEach { index, item in
            if index < destination {
                item.position = index
            } else if index == destination {
                movedItem.position = destination
            } else {
                item.position = index + 1
            }
        }
        updated = Date()
    }
    
    func markAsCompleted() {
        isCompleted = true
        lastReadDate = Date()
        updated = Date()
    }
    
    func markAsIncomplete() {
        isCompleted = false
        updated = Date()
    }
} 