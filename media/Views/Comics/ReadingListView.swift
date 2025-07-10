//
//  ReadingListView.swift
//  media
//
//  Created by AI on [date]
//
//  Detailed view for a specific reading list showing ordered comics.
//

import SwiftUI
import SwiftData

struct ReadingListView: View {
    @Bindable var readingList: ReadingList
    @State private var isEditing = false
    @State private var showingEditSheet = false
    @State private var showingAddComics = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            // Header section with reading list info
            Section {
                ReadingListHeaderView(readingList: readingList)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // Reading progress section
            if readingList.totalIssues > 0 {
                Section("Progress") {
                    ProgressSectionView(readingList: readingList)
                }
            }
            
            // Issues section
            Section {
                if readingList.orderedItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No comics in this reading list yet")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Button("Add Comics") {
                            showingAddComics = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(readingList.orderedItems.indices, id: \.self) { index in
                        let item = readingList.orderedItems[index]
                        ReadingListItemRowView(
                            item: item,
                            position: index + 1,
                            isEditing: isEditing
                        )
                    }
                    .onMove(perform: isEditing ? moveItems : nil)
                    .onDelete(perform: isEditing ? deleteItems : nil)
                }
            } header: {
                if !readingList.orderedItems.isEmpty {
                    HStack {
                        Text("Reading Order (\(readingList.totalIssues) issues)")
                        Spacer()
                        Button(isEditing ? "Done" : "Edit") {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(readingList.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit List", systemImage: "pencil") {
                        showingEditSheet = true
                    }
                    
                    Button("Add Comics", systemImage: "plus") {
                        showingAddComics = true
                    }
                    
                    Divider()
                    
                    if readingList.isFavorite {
                        Button("Remove from Favorites", systemImage: "heart.slash") {
                            readingList.isFavorite = false
                        }
                    } else {
                        Button("Add to Favorites", systemImage: "heart") {
                            readingList.isFavorite = true
                        }
                    }
                    
                    if readingList.isCompleted {
                        Button("Mark as Incomplete", systemImage: "arrow.counterclockwise") {
                            readingList.markAsIncomplete()
                        }
                    } else {
                        Button("Mark as Complete", systemImage: "checkmark") {
                            readingList.markAsCompleted()
                        }
                    }
                    
                    Divider()
                    
                    Button("Delete List", systemImage: "trash", role: .destructive) {
                        deleteReadingList()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                EditReadingListView(readingList: readingList)
            }
        }
        .sheet(isPresented: $showingAddComics) {
            NavigationStack {
                AddComicsToReadingListView(readingList: readingList)
            }
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        // Reorder the items
        var items = readingList.orderedItems
        items.move(fromOffsets: source, toOffset: destination)
        
        // Update positions
        for (index, item) in items.enumerated() {
            item.updatePosition(index)
        }
        
        readingList.updated = Date()
    }
    
    private func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { readingList.orderedItems[$0] }
        
        for item in itemsToDelete {
            modelContext.delete(item)
        }
        
        readingList.updateCounts()
    }
    
    private func deleteReadingList() {
        modelContext.delete(readingList)
        dismiss()
    }
}

// Header view with reading list metadata
private struct ReadingListHeaderView: View {
    @Bindable var readingList: ReadingList
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Thumbnail
                ReadingListThumbnailView(readingList: readingList)
                    .frame(width: 120, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(readingList.name)
                        .font(.title2)
                        .bold()
                    
                    // Creator and metadata
                    if let creator = readingList.creator {
                        Text("Created by \(creator)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        if readingList.isCompleted {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Label("\(readingList.totalIssues) issues", systemImage: "book")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if readingList.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    // Tags
                    if let tags = readingList.tags, !tags.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 2), spacing: 4) {
                            ForEach(tags.components(separatedBy: ", ").prefix(4), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            
            // Description
            if let description = readingList.listDescription, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

// Progress section
private struct ProgressSectionView: View {
    @Bindable var readingList: ReadingList
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(readingList.completedIssues) of \(readingList.totalIssues) issues")
                        .font(.headline)
                    Text("\(Int(readingList.completionPercentage * 100))% complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(progress: readingList.completionPercentage)
                    .frame(width: 50, height: 50)
            }
            
            ProgressView(value: readingList.completionPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
            
            if let lastReadDate = readingList.lastReadDate {
                HStack {
                    Text("Last read: \(lastReadDate, format: .dateTime.day().month().year())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }
}

// Individual reading list item row
private struct ReadingListItemRowView: View {
    @Bindable var item: ReadingListItem
    let position: Int
    let isEditing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Position number
            Text("\(position)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            // Comic thumbnail
            AsyncImage(url: item.comic?.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(.secondary.opacity(0.2))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 40, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(item.displaySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                if let contextualNote = item.contextualNote {
                    Text(contextualNote)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .italic()
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if !isEditing {
                // Read status button
                Button(action: { toggleReadStatus() }) {
                    Image(systemName: item.effectiveReadStatus ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.effectiveReadStatus ? .green : .secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .opacity(item.isSkipped ? 0.5 : 1.0)
        .overlay(alignment: .leading) {
            if item.isOptional {
                Rectangle()
                    .fill(.blue.opacity(0.3))
                    .frame(width: 3)
            }
        }
    }
    
    private func toggleReadStatus() {
        if item.effectiveReadStatus {
            item.markAsUnread()
        } else {
            item.markAsRead()
        }
    }
}

// Reusable components (these would be the same as in ReadingListsView)
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
                    
                    ForEach(firstItems.count..<4, id: \.self) { _ in
                        Rectangle()
                            .fill(.secondary.opacity(0.1))
                    }
                }
            }
        }
    }
}

private struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))")
                .font(.caption)
                .bold()
        }
    }
} 