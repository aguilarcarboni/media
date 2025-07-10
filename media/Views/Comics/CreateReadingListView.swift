//
//  CreateReadingListView.swift
//  media
//
//  Created by AI on [date]
//
//  Form for creating new reading lists with optional comic selection.
//

import SwiftUI
import SwiftData

struct CreateReadingListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var description = ""
    @State private var creator = ""
    @State private var tags = ""
    @State private var isPublic = false
    @State private var isFavorite = false
    
    @State private var showingComicSelection = false
    @State private var selectedComics: [Comic] = []
    
    var body: some View {
        Form {
            Section("Reading List Details") {
                TextField("Name", text: $name)
                    .font(.headline)
                
                TextField("Description (Optional)", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                
                TextField("Creator (Optional)", text: $creator)
            }
            
            Section("Settings") {
                Toggle("Add to Favorites", isOn: $isFavorite)
                Toggle("Make Public", isOn: $isPublic)
                
                TextField("Tags (comma-separated)", text: $tags)
                    .textInputAutocapitalization(.words)
            }
            
            Section("Add Comics") {
                Button(action: { showingComicSelection = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Select Comics to Add")
                        Spacer()
                        if !selectedComics.isEmpty {
                            Text("\(selectedComics.count) selected")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if !selectedComics.isEmpty {
                    ForEach(selectedComics) { comic in
                        ComicRowView(comic: comic)
                    }
                    .onDelete(perform: removeComics)
                }
            }
        }
        .navigationTitle("New Reading List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    createReadingList()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .sheet(isPresented: $showingComicSelection) {
            NavigationStack {
                ComicSelectionView(selectedComics: $selectedComics)
            }
        }
    }
    
    private func removeComics(at offsets: IndexSet) {
        selectedComics.remove(atOffsets: offsets)
    }
    
    private func createReadingList() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let readingList = ReadingList(
            name: trimmedName,
            listDescription: description.isEmpty ? nil : description,
            creator: creator.isEmpty ? nil : creator,
            isPublic: isPublic,
            tags: tags.isEmpty ? nil : tags,
            isFavorite: isFavorite
        )
        
        modelContext.insert(readingList)
        
        // Add selected comics to the reading list
        for (index, comic) in selectedComics.enumerated() {
            readingList.addComic(comic, at: index)
        }
        
        readingList.updateCounts()
        
        dismiss()
    }
}

// Simple comic row for the selected comics list
private struct ComicRowView: View {
    let comic: Comic
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: comic.thumbnailURL) { image in
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
                if let seriesName = comic.seriesName, let issueNumber = comic.issueNumber {
                    Text("\(seriesName) #\(issueNumber)")
                        .font(.headline)
                } else {
                    Text(comic.title)
                        .font(.headline)
                }
                
                if let publicationDate = comic.publicationDate {
                    Text(publicationDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

// Comic selection view
struct ComicSelectionView: View {
    @Binding var selectedComics: [Comic]
    @Environment(\.dismiss) private var dismiss
    @Query private var allComics: [Comic]
    
    @State private var searchText = ""
    
    private var filteredComics: [Comic] {
        if searchText.isEmpty {
            return allComics.sorted { lhs, rhs in
                // Sort by series name, then by issue number
                if let lhsSeries = lhs.seriesName, let rhsSeries = rhs.seriesName {
                    if lhsSeries != rhsSeries {
                        return lhsSeries < rhsSeries
                    }
                }
                return (lhs.issueNumber ?? 0) < (rhs.issueNumber ?? 0)
            }
        } else {
            return allComics.filter { comic in
                comic.title.localizedCaseInsensitiveContains(searchText) ||
                (comic.seriesName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (comic.characters?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { lhs, rhs in
                if let lhsSeries = lhs.seriesName, let rhsSeries = rhs.seriesName {
                    if lhsSeries != rhsSeries {
                        return lhsSeries < rhsSeries
                    }
                }
                return (lhs.issueNumber ?? 0) < (rhs.issueNumber ?? 0)
            }
        }
    }
    
    var body: some View {
        List {
            if filteredComics.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No comics found")
                        .font(.title2)
                        .bold()
                    Text("Try adjusting your search or add comics to your library first")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredComics) { comic in
                    ComicSelectionRowView(
                        comic: comic,
                        isSelected: selectedComics.contains { $0.id == comic.id },
                        onToggle: { toggleComicSelection(comic) }
                    )
                }
            }
        }
        .navigationTitle("Select Comics")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search comics...")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button(selectedComics.isEmpty ? "Select All" : "Clear All") {
                    if selectedComics.isEmpty {
                        selectedComics = Array(filteredComics)
                    } else {
                        selectedComics.removeAll()
                    }
                }
            }
        }
    }
    
    private func toggleComicSelection(_ comic: Comic) {
        if let index = selectedComics.firstIndex(where: { $0.id == comic.id }) {
            selectedComics.remove(at: index)
        } else {
            selectedComics.append(comic)
        }
    }
}

// Row view for comic selection
private struct ComicSelectionRowView: View {
    let comic: Comic
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title2)
                
                // Comic thumbnail
                AsyncImage(url: comic.thumbnailURL) { image in
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
                    if let seriesName = comic.seriesName, let issueNumber = comic.issueNumber {
                        Text("\(seriesName) #\(issueNumber)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } else {
                        Text(comic.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    
                    HStack {
                        if let publicationDate = comic.publicationDate {
                            Text(publicationDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if comic.read {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// Edit reading list view (for updating existing lists)
struct EditReadingListView: View {
    @Bindable var readingList: ReadingList
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var description: String
    @State private var creator: String
    @State private var tags: String
    @State private var isPublic: Bool
    @State private var isFavorite: Bool
    
    init(readingList: ReadingList) {
        self.readingList = readingList
        self._name = State(initialValue: readingList.name)
        self._description = State(initialValue: readingList.listDescription ?? "")
        self._creator = State(initialValue: readingList.creator ?? "")
        self._tags = State(initialValue: readingList.tags ?? "")
        self._isPublic = State(initialValue: readingList.isPublic)
        self._isFavorite = State(initialValue: readingList.isFavorite)
    }
    
    var body: some View {
        Form {
            Section("Reading List Details") {
                TextField("Name", text: $name)
                    .font(.headline)
                
                TextField("Description (Optional)", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                
                TextField("Creator (Optional)", text: $creator)
            }
            
            Section("Settings") {
                Toggle("Add to Favorites", isOn: $isFavorite)
                Toggle("Make Public", isOn: $isPublic)
                
                TextField("Tags (comma-separated)", text: $tags)
                    .textInputAutocapitalization(.words)
            }
        }
        .navigationTitle("Edit Reading List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private func saveChanges() {
        readingList.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        readingList.listDescription = description.isEmpty ? nil : description
        readingList.creator = creator.isEmpty ? nil : creator
        readingList.tags = tags.isEmpty ? nil : tags
        readingList.isPublic = isPublic
        readingList.isFavorite = isFavorite
        readingList.updated = Date()
        
        dismiss()
    }
}

// Add comics to existing reading list view
struct AddComicsToReadingListView: View {
    @Bindable var readingList: ReadingList
    @Environment(\.dismiss) private var dismiss
    @Query private var allComics: [Comic]
    
    @State private var selectedComics: [Comic] = []
    @State private var searchText = ""
    
    private var availableComics: [Comic] {
        let existingComicIds = Set(readingList.orderedItems.compactMap { $0.comic?.id })
        return allComics.filter { !existingComicIds.contains($0.id) }
    }
    
    private var filteredComics: [Comic] {
        if searchText.isEmpty {
            return availableComics.sorted { lhs, rhs in
                if let lhsSeries = lhs.seriesName, let rhsSeries = rhs.seriesName {
                    if lhsSeries != rhsSeries {
                        return lhsSeries < rhsSeries
                    }
                }
                return (lhs.issueNumber ?? 0) < (rhs.issueNumber ?? 0)
            }
        } else {
            return availableComics.filter { comic in
                comic.title.localizedCaseInsensitiveContains(searchText) ||
                (comic.seriesName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (comic.characters?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { lhs, rhs in
                if let lhsSeries = lhs.seriesName, let rhsSeries = rhs.seriesName {
                    if lhsSeries != rhsSeries {
                        return lhsSeries < rhsSeries
                    }
                }
                return (lhs.issueNumber ?? 0) < (rhs.issueNumber ?? 0)
            }
        }
    }
    
    var body: some View {
        List {
            if filteredComics.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No comics available")
                        .font(.title2)
                        .bold()
                    Text("All comics in your library are already in this reading list")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredComics) { comic in
                    ComicSelectionRowView(
                        comic: comic,
                        isSelected: selectedComics.contains { $0.id == comic.id },
                        onToggle: { toggleComicSelection(comic) }
                    )
                }
            }
        }
        .navigationTitle("Add Comics")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search comics...")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Add \(selectedComics.count)") {
                    addSelectedComics()
                }
                .disabled(selectedComics.isEmpty)
            }
        }
    }
    
    private func toggleComicSelection(_ comic: Comic) {
        if let index = selectedComics.firstIndex(where: { $0.id == comic.id }) {
            selectedComics.remove(at: index)
        } else {
            selectedComics.append(comic)
        }
    }
    
    private func addSelectedComics() {
        for comic in selectedComics {
            readingList.addComic(comic)
        }
        
        readingList.updateCounts()
        dismiss()
    }
} 