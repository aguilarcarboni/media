//
//  AddToReadingListView.swift
//  media
//
//  Created by AI on [date]
//
//  Reusable component for adding comics to reading lists.
//

import SwiftUI
import SwiftData

struct AddToReadingListView: View {
    let comic: Comic
    @Environment(\.dismiss) private var dismiss
    @Query private var readingLists: [ReadingList]
    
    @State private var showingCreateList = false
    @State private var selectedLists: Set<UUID> = []
    
    private var availableReadingLists: [ReadingList] {
        readingLists.filter { readingList in
            // Only show lists that don't already contain this comic
            !readingList.orderedItems.contains { $0.comic?.id == comic.id }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if availableReadingLists.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Reading Lists Available")
                            .font(.title2)
                            .bold()
                        Text("Create a reading list to organize your comics")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Create Reading List") {
                            showingCreateList = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(availableReadingLists) { readingList in
                            ReadingListSelectionRow(
                                readingList: readingList,
                                isSelected: selectedLists.contains(readingList.id),
                                onToggle: { toggleSelection(readingList) }
                            )
                        }
                    } header: {
                        Text("Select Reading Lists")
                    } footer: {
                        if !selectedLists.isEmpty {
                            Text("This comic will be added to \(selectedLists.count) reading list\(selectedLists.count == 1 ? "" : "s")")
                        }
                    }
                }
            }
            .navigationTitle("Add to Reading List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addToSelectedLists()
                    }
                    .disabled(selectedLists.isEmpty)
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button("New List") {
                        showingCreateList = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateList) {
                NavigationStack {
                    CreateReadingListView()
                }
            }
        }
    }
    
    private func toggleSelection(_ readingList: ReadingList) {
        if selectedLists.contains(readingList.id) {
            selectedLists.remove(readingList.id)
        } else {
            selectedLists.insert(readingList.id)
        }
    }
    
    private func addToSelectedLists() {
        let listsToUpdate = readingLists.filter { selectedLists.contains($0.id) }
        
        for readingList in listsToUpdate {
            readingList.addComic(comic)
            readingList.updateCounts()
        }
        
        dismiss()
    }
}

// Row for selecting reading lists
private struct ReadingListSelectionRow: View {
    let readingList: ReadingList
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title2)
                
                // Reading list thumbnail
                ReadingListThumbnailView(readingList: readingList)
                    .frame(width: 40, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(readingList.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        Text("\(readingList.totalIssues) issues")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
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
                        
                        Spacer()
                    }
                    
                    if let description = readingList.listDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// Reusable thumbnail component
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
                Image(systemName: "list.bullet.rectangle")
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