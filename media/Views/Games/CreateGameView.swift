//
//  CreateGameView.swift
//  media
//
//  Created by Andrés on 30/6/2025.
//

import SwiftUI
import SwiftData

struct CreateGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPreview = false
    
    // Game data
    @State private var name = ""
    @State private var year = ""
    @State private var genre = ""
    @State private var rating = ""
    @State private var platforms = ""
    @State private var summary = ""
    
    // IGDB integration
    @State private var searchQuery = ""
    @State private var searchResults: [IGDBGameSearchResult] = []
    @State private var isSearching = false
    @State private var selectedIGDBGame: IGDBGameDetails?
    @State private var isLoadingGameDetails = false
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
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var mainView: some View {
        VStack(spacing: 20) {
            // Search bar
            VStack(spacing: 16) {
                HStack {
                    TextField("Search for a game...", text: $searchQuery).onSubmit { searchGames() }.textFieldStyle(.plain)
                    Button(action: searchGames) {
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .disabled(isSearching || searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.bordered)
                }
                if isSearching {
                    ProgressView("Searching IGDB...")
                        .padding()
                }
            }
            
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults.prefix(10)) { result in
                            gameSearchResultRow(result)
                        }
                    }
                    .padding(.horizontal)
                }
            } else if !searchQuery.isEmpty && !isSearching {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No results found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Try a different search term")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Add Game")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
    
    private func gameSearchResultRow(_ result: IGDBGameSearchResult) -> some View {
        Button(action: {
            selectGame(result)
        }) {
            HStack(spacing: 12) {
                AsyncImage(url: result.thumbnailURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(.secondary.opacity(0.2)).overlay {
                        Image(systemName: "photo").foregroundStyle(.secondary)
                    }
                }
                .frame(width: 50, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let timestamp = result.first_release_date {
                        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                        Text("\(Calendar.current.component(.year, from: date))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let summary = result.summary {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
                Spacer()
                if isLoadingGameDetails {
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
    
    private var previewView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Preview").font(.largeTitle).bold()
                VStack(spacing: 16) {
                    previewRow("Name", value: name)
                    previewRow("Year", value: year.isEmpty ? "Unknown" : year)
                    previewRow("Platforms", value: platforms.isEmpty ? "Unknown" : platforms, isLong: true)
                    previewRow("Genre", value: genre.isEmpty ? "Unknown" : genre)
                    previewRow("Rating", value: rating.isEmpty ? "Unrated" : rating)
                    if !summary.isEmpty {
                        previewRow("Summary", value: summary, isLong: true)
                    }
                    if selectedIGDBGame != nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("Imported from IGDB").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
                .cornerRadius(16)
                
                VStack(spacing: 12) {
                    Button(action: addGame) {
                        Text("Add Game")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    Button("Back to Edit") { showingPreview = false }
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Add Game")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        }
    }
    
    private func previewRow(_ label: String, value: String, isLong: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(isLong ? .body : .headline).foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Actions
    private func searchGames() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSearching = true
        searchResults = []
        Task {
            do {
                let results = try await IGDBAPIManager.shared.searchGameResults(query: searchQuery)
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
    
    private func selectGame(_ searchResult: IGDBGameSearchResult) {
        isLoadingGameDetails = true
        Task {
            do {
                let details = try await IGDBAPIManager.shared.getGame(id: searchResult.id)
                await MainActor.run {
                    populateFields(with: details)
                    self.selectedIGDBGame = details
                    self.isLoadingGameDetails = false
                    self.searchResults = []
                    self.searchQuery = ""
                    self.showingPreview = true
                }
            } catch {
                await MainActor.run {
                    self.isLoadingGameDetails = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    private func populateFields(with game: IGDBGameDetails) {
        name = game.name ?? ""
        if let date = game.releaseDate {
            year = String(Calendar.current.component(.year, from: date))
        }
        genre = game.genreNames
        platforms = game.platformNames.joined(separator: ", ")
        summary = game.summary ?? ""
    }
    
    private func addGame() {
        let newGame: Game
        if let igdbGame = selectedIGDBGame {
            newGame = Game()
            newGame.updateFromIGDB(igdbGame)
            // Override with manual edits
            applyManualEdits(to: newGame)
        } else {
            newGame = Game()
            applyManualEdits(to: newGame)
        }
        modelContext.insert(newGame)
        dismiss()
    }
    
    private func applyManualEdits(to game: Game) {
        game.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let y = Int(year) { game.year = y }
        if let r = Double(rating) { game.rating = r }
        let genreText = genre.trimmingCharacters(in: .whitespacesAndNewlines)
        game.genres = genreText.isEmpty ? nil : genreText
        let platformText = platforms.trimmingCharacters(in: .whitespacesAndNewlines)
        game.platforms = platformText.isEmpty ? nil : platformText
        let summaryText = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        game.summary = summaryText.isEmpty ? nil : summaryText
    }
} 