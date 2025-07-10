//
//  ReadingListsView.swift
//  media
//
//  Created by AI on [date]
//
//  Lists user-created reading lists (comic playlists).
//

import SwiftUI
import SwiftData

struct ReadingListsView: View {
    @Query private var readingLists: [ReadingList]
    @State private var selectedReadingList: ReadingList?
    @State private var searchQuery = ""
    @State private var showingCreateList = false

    // Filtering options
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case completed = "Completed"
        case inProgress = "In Progress"
        case favorites = "Favorites"
        var id: Self { self }
    }
    @State private var filterOption: FilterOption = .all

    // Sorting options
    enum SortOption: String, CaseIterable, Identifiable {
        case nameAZ = "Name A-Z"
        case nameZA = "Name Z-A"
        case recentlyCreated = "Recently Created"
        case recentlyUpdated = "Recently Updated"
        case completionHighLow = "Completion High-Low"
        case issuesHighLow = "Issues High-Low"
        var id: Self { self }
    }
    @State private var sortOption: SortOption = .recentlyUpdated

    private var filteredReadingLists: [ReadingList] {
        readingLists
            .filter { list in
                switch filterOption {
                case .all:
                    return true
                case .completed:
                    return list.isCompleted
                case .inProgress:
                    return !list.isCompleted && list.totalIssues > 0
                case .favorites:
                    return list.isFavorite
                }
            }
            .filter { list in
                searchQuery.isEmpty || list.name.localizedCaseInsensitiveContains(searchQuery)
            }
            .sorted { lhs, rhs in
                switch sortOption {
                case .nameAZ:
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                case .nameZA:
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending
                case .recentlyCreated:
                    return lhs.created > rhs.created
                case .recentlyUpdated:
                    return lhs.updated > rhs.updated
                case .completionHighLow:
                    return lhs.completionPercentage > rhs.completionPercentage
                case .issuesHighLow:
                    return lhs.totalIssues > rhs.totalIssues
                }
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            if readingLists.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        Text("No Reading Lists Yet").font(.title2).bold()
                        Text("Create your first reading list to organize your comic reading order").font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    
                    Button(action: { showingCreateList = true }) {
                        Label("Create Reading List", systemImage: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                }
                .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredReadingLists) { readingList in
                        Button(action: { selectedReadingList = readingList }) {
                            ReadingListRowView(readingList: readingList)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Reading Lists")
        .searchable(text: $searchQuery)
        .sheet(item: $selectedReadingList) { list in
            NavigationStack { ReadingListView(readingList: list) }
        }
        .sheet(isPresented: $showingCreateList) {
            NavigationStack { CreateReadingListView() }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateList = true }) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Picker("Filter", selection: $filterOption) {
                        ForEach(FilterOption.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: { Image(systemName: "arrow.up.arrow.down") }
            }
        }
    }
}

// Row View for reading list
private struct ReadingListRowView: View {
    @Bindable var readingList: ReadingList
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover image or generated thumbnail
            ReadingListThumbnailView(readingList: readingList)
                .frame(width: 50, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(readingList.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if readingList.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    if readingList.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                if let description = readingList.listDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("\(readingList.totalIssues) issues")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if readingList.totalIssues > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(readingList.completionPercentage * 100))% complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let tags = readingList.tags, !tags.isEmpty {
                        let tagArray = tags.components(separatedBy: ", ").prefix(2)
                        ForEach(Array(tagArray), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            if readingList.totalIssues > 0 {
                CircularProgressView(progress: readingList.completionPercentage)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.vertical, 4)
    }
}

// Thumbnail view for reading lists
private struct ReadingListThumbnailView: View {
    let readingList: ReadingList
    
    var body: some View {
        if let coverURL = readingList.coverURL {
            AsyncImage(url: coverURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                defaultThumbnail
            }
        } else {
            // Generate thumbnail from first few issues
            generatedThumbnail
        }
    }
    
    private var defaultThumbnail: some View {
        Rectangle()
            .fill(.secondary.opacity(0.2))
            .overlay {
                Image(systemName: "books.vertical")
                    .foregroundStyle(.secondary)
            }
    }
    
    private var generatedThumbnail: some View {
        let firstItems = Array(readingList.orderedItems.prefix(4))
        
        return Group {
            if firstItems.isEmpty {
                defaultThumbnail
            } else if firstItems.count == 1, let comic = firstItems.first?.comic {
                AsyncImage(url: comic.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultThumbnail
                }
            } else {
                // Create a grid of up to 4 covers
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 2), spacing: 1) {
                    ForEach(firstItems.indices, id: \.self) { index in
                        AsyncImage(url: firstItems[index].comic?.thumbnailURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(.secondary.opacity(0.3))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Fill remaining slots if needed
                    ForEach(firstItems.count..<4, id: \.self) { _ in
                        Rectangle()
                            .fill(.secondary.opacity(0.1))
                    }
                }
            }
        }
    }
}

// Simple circular progress view
private struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))")
                .font(.caption2)
                .bold()
        }
    }
} 
