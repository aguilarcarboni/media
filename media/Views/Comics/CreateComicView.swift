//
//  CreateComicView.swift
//  media
//
//  Created by Andrés on 6/7/2025.
//

import SwiftUI
import SwiftData

struct CreateComicView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // View state
    @State private var showingPreview = false
    
    // Comic fields
    @State private var title = ""
    @State private var issueNumber = ""
    @State private var seriesName = ""
    @State private var rating = ""
    @State private var notes = ""
    
    // Marvel search state
    @State private var searchQuery = ""
    @State private var searchResults: [MarvelComicSearchResult] = []
    @State private var isSearching = false
    @State private var selectedMarvelComic: MarvelComicDetails?
    @State private var isLoadingComicDetails = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            if showingPreview {
                previewView
            } else {
                mainView
            }
        }
        .alert("Error", isPresented: $showingError) { Button("OK") { } } message: { Text(errorMessage) }
    }
    
    // MARK: - Main search/edit UI
    private var mainView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                HStack {
                    TextField("Search for a comic…", text: $searchQuery).onSubmit { searchComics() }.textFieldStyle(.plain)

                    Button(action: searchComics) {
                        if isSearching { ProgressView().scaleEffect(0.8) } else {
                            Image(systemName: "magnifyingglass").foregroundColor(.accentColor)
                        }
                    }
                    .disabled(isSearching || searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.bordered)
                }
                if isSearching {
                    ProgressView("Searching Marvel…")
                        .padding()
                }
            }
            
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults.prefix(10)) { result in
                            comicSearchResultRow(result)
                        }
                    }
                    .padding(.horizontal)
                }
            } else if !searchQuery.isEmpty && !isSearching {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.system(size: 32)).foregroundStyle(.secondary)
                    Text("No results found").font(.headline).foregroundStyle(.secondary)
                    Text("Try a different search term").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Add Comic")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
    
    private func comicSearchResultRow(_ result: MarvelComicSearchResult) -> some View {
        Button(action: { selectComic(result) }) {
            HStack(spacing: 12) {
                AsyncImage(url: result.thumbnailURL) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(.secondary.opacity(0.2)).overlay {
                        Image(systemName: "photo").foregroundStyle(.secondary)
                    }
                }
                .frame(width: 50, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title).font(.headline)
                    if let year = result.year {
                        Text("\(year)").font(.subheadline).foregroundStyle(.secondary)
                    }
                    if let overview = result.overview {
                        Text(overview).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                    }
                }
                Spacer()
                if isLoadingComicDetails {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
            }
            .padding()
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Preview UI
    private var previewView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Preview").font(.largeTitle).bold()
                VStack(spacing: 16) {
                    previewRow("Title", value: title)
                    previewRow("Issue #", value: issueNumber.isEmpty ? "?" : issueNumber)
                    previewRow("Series", value: seriesName.isEmpty ? "Unknown" : seriesName)
                    if selectedMarvelComic != nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("Imported from Marvel").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
                .cornerRadius(16)
                
                VStack(spacing: 12) {
                    Button(action: addComic) {
                        Text("Add Comic")
                            .font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding().background(Color.accentColor).cornerRadius(12)
                    }
                    Button("Back to Edit") { showingPreview = false }
                        .font(.headline).foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity).padding().cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Add Comic")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
    
    private func previewRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Actions
    private func searchComics() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSearching = true
        searchResults = []
        Task {
            do {
                let results = try await MarvelAPIManager.shared.searchComics(query: searchQuery)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.isSearching = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    private func selectComic(_ result: MarvelComicSearchResult) {
        isLoadingComicDetails = true
        Task {
            do {
                let details = try await MarvelAPIManager.shared.getComic(id: result.id)
                await MainActor.run {
                    populateFields(with: details)
                    self.selectedMarvelComic = details
                    self.isLoadingComicDetails = false
                    self.searchResults = []
                    self.searchQuery = ""
                    self.showingPreview = true
                }
            } catch {
                await MainActor.run {
                    self.isLoadingComicDetails = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    private func populateFields(with comic: MarvelComicDetails) {
        title = comic.title
        issueNumber = comic.issueNumber == 0 ? "" : String(format: "%.0f", comic.issueNumber)
        seriesName = comic.series?.name ?? ""
    }
    
    private func addComic() {
        let newComic: Comic
        if let marvelComic = selectedMarvelComic {
            newComic = marvelComic.toComic()
            // Override with manual edits if any
            newComic.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if let issue = Int(issueNumber) { newComic.issueNumber = issue }
            let seriesText = seriesName.trimmingCharacters(in: .whitespacesAndNewlines)
            newComic.seriesName = seriesText.isEmpty ? nil : seriesText
            newComic.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            if let ratingDouble = Double(rating) { newComic.rating = ratingDouble }
        } else {
            newComic = Comic(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                issueNumber: Int(issueNumber),
                seriesName: seriesName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        modelContext.insert(newComic)
        dismiss()
    }
} 