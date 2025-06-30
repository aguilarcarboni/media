//
//  CreateTVShowView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

struct CreateTVShowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showingPreview = false
    
    // TV Show data
    @State private var name = ""
    @State private var year = ""
    @State private var genre = ""
    @State private var rating = ""
    @State private var seasons = ""
    @State private var overview = ""
    @State private var airDate = ""
    @State private var status = ""
    @State private var numberOfSeasons = ""
    @State private var numberOfEpisodes = ""
    @State private var creators = ""
    @State private var cast = ""
    
    // TMDB Integration
    @State private var searchQuery = ""
    @State private var searchResults: [TMDBTVShowSearchResult] = []
    @State private var isSearching = false
    @State private var selectedTMDBTVShow: TMDBTVShowDetails?
    @State private var isLoadingTVShowDetails = false
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
        TabView(selection: $selectedTab) {
            manualEntryTab
                .tabItem {
                    Label("Manual Entry", systemImage: "pencil")
                }
                .tag(0)
            
            tmdbSearchTab
                .tabItem {
                    Label("Search TMDB", systemImage: "magnifyingglass")
                }
                .tag(1)
        }
        .navigationTitle("Add TV Show")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private var manualEntryTab: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                TextField("TV Show Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                
                HStack(spacing: 12) {
                    TextField("Year", text: $year)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Number of Seasons", text: $numberOfSeasons)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack(spacing: 12) {
                    TextField("Genre", text: $genre)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Rating (0-10)", text: $rating)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack(spacing: 12) {
                    TextField("Status", text: $status)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Episodes", text: $numberOfEpisodes)
                        .textFieldStyle(.roundedBorder)
                }
                
                TextField("Creators", text: $creators)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Main Cast", text: $cast)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Seasons (e.g., Season 1; Season 2)", text: $seasons)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Air Date (MM/DD/YYYY)", text: $airDate)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Overview or notes", text: $overview, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4...8)
            }
            
            Spacer()
            
            Button(action: {
                showingPreview = true
            }) {
                Text("Continue to Preview")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.accentColor)
                    .cornerRadius(12)
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
    
    private var tmdbSearchTab: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                HStack {
                    TextField("Search for a TV show...", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            searchTVShows()
                        }
                    
                    Button(action: searchTVShows) {
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
                    ProgressView("Searching TMDB...")
                        .padding()
                }
            }
            
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults.prefix(10)) { result in
                            tvShowSearchResultRow(result)
                        }
                    }
                    .padding(.horizontal)
                }
            } else if !searchQuery.isEmpty && !isSearching {
                VStack(spacing: 8) {
                    Image(systemName: "tv")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    
                    Text("No results found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Try a different search term")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func tvShowSearchResultRow(_ result: TMDBTVShowSearchResult) -> some View {
        Button(action: {
            selectTVShow(result)
        }) {
            HStack(spacing: 12) {
                AsyncImage(url: result.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.secondary.opacity(0.2))
                        .overlay {
                            Image(systemName: "tv")
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(width: 50, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let year = result.year {
                        Text("\(year)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let overview = result.overview {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                if isLoadingTVShowDetails {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
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
                VStack(spacing: 16) {
                    Text("Preview")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Review your TV show details before adding")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 16) {
                    previewRow("Name", value: name)
                    
                    HStack {
                        previewRow("Year", value: year.isEmpty ? "Unknown" : year)
                        Spacer()
                        previewRow("Seasons", value: numberOfSeasons.isEmpty ? "Unknown" : numberOfSeasons)
                    }
                    
                    HStack {
                        previewRow("Genre", value: genre.isEmpty ? "Unknown" : genre)
                        Spacer()
                        previewRow("Rating", value: rating.isEmpty ? "Unrated" : "\(rating)/10")
                    }
                    
                    if !status.isEmpty {
                        previewRow("Status", value: status)
                    }
                    
                    if !numberOfEpisodes.isEmpty {
                        previewRow("Episodes", value: numberOfEpisodes)
                    }
                    
                    if !creators.isEmpty {
                        previewRow("Creators", value: creators)
                    }
                    
                    if !cast.isEmpty {
                        previewRow("Cast", value: cast)
                    }
                    
                    if !seasons.isEmpty {
                        previewRow("Season Info", value: seasons, isLong: true)
                    }
                    
                    if !airDate.isEmpty {
                        previewRow("Air Date", value: airDate)
                    }
                    
                    if !overview.isEmpty {
                        previewRow("Overview", value: overview, isLong: true)
                    }
                    
                    if selectedTMDBTVShow != nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Imported from TMDB")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
                .cornerRadius(16)
                
                VStack(spacing: 12) {
                    Button(action: addTVShow) {
                        Text("Add TV Show")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingPreview = false
                    }) {
                        Text("Back to Edit")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Add TV Show")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private func previewRow(_ label: String, value: String, isLong: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(isLong ? .body : .headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func searchTVShows() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            return 
        }
        
        isSearching = true
        searchResults = []
        
        Task {
            do {
                let results = try await TMDBAPIManager.shared.searchTVShowResults(query: searchQuery)
                
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
    
    private func selectTVShow(_ searchResult: TMDBTVShowSearchResult) {
        isLoadingTVShowDetails = true
        
        Task {
            do {
                let tvShowDetails = try await TMDBAPIManager.shared.getTVShow(id: searchResult.id)
                await MainActor.run {
                    populateFields(with: tvShowDetails)
                    self.selectedTMDBTVShow = tvShowDetails
                    self.isLoadingTVShowDetails = false
                    self.searchResults = []
                    self.searchQuery = ""
                    self.showingPreview = true
                }
            } catch {
                await MainActor.run {
                    self.isLoadingTVShowDetails = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    private func populateFields(with tvShow: TMDBTVShowDetails) {
        name = tvShow.name
        year = tvShow.firstAirYear.map(String.init) ?? ""
        genre = tvShow.genreNames
        rating = String(format: "%.1f", tvShow.voteAverage)
        numberOfSeasons = String(tvShow.numberOfSeasons)
        numberOfEpisodes = String(tvShow.numberOfEpisodes)
        overview = tvShow.overview ?? ""
        status = tvShow.status
        creators = tvShow.creators.map { $0.name }.joined(separator: ", ")
        cast = tvShow.cast.prefix(5).map { $0.name }.joined(separator: ", ")
        
        // Convert first air date to MM/DD/YYYY format
        if let firstAirDate = tvShow.firstAirDate {
            let inputFormatter = DateFormatter()
            inputFormatter.dateFormat = "yyyy-MM-dd"
            if let date = inputFormatter.date(from: firstAirDate) {
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "MM/dd/yyyy"
                airDate = outputFormatter.string(from: date)
            }
        }
    }
    
    private func addTVShow() {
        let newTVShow: TVShow
        
        if let tmdbTVShow = selectedTMDBTVShow {
            // Create TV show from TMDB data
            newTVShow = tmdbTVShow.toTVShow()
            // Override with any manual edits
            newTVShow.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if let yearInt = Int(year.trimmingCharacters(in: .whitespacesAndNewlines)) {
                newTVShow.year = yearInt
            }
            if let ratingDouble = Double(rating.trimmingCharacters(in: .whitespacesAndNewlines)) {
                newTVShow.rating = ratingDouble
            }
            if let numberOfSeasonsInt = Int(numberOfSeasons.trimmingCharacters(in: .whitespacesAndNewlines)) {
                newTVShow.numberOfSeasons = numberOfSeasonsInt
            }
            if let numberOfEpisodesInt = Int(numberOfEpisodes.trimmingCharacters(in: .whitespacesAndNewlines)) {
                newTVShow.numberOfEpisodes = numberOfEpisodesInt
            }
            let genreText = genre.trimmingCharacters(in: .whitespacesAndNewlines)
            newTVShow.genres = genreText.isEmpty ? nil : genreText
            let overviewText = overview.trimmingCharacters(in: .whitespacesAndNewlines)
            newTVShow.overview = overviewText.isEmpty ? nil : overviewText
            let statusText = status.trimmingCharacters(in: .whitespacesAndNewlines)
            newTVShow.status = statusText.isEmpty ? nil : statusText
            let creatorsText = creators.trimmingCharacters(in: .whitespacesAndNewlines)
            newTVShow.creators = creatorsText.isEmpty ? nil : creatorsText
            let castText = cast.trimmingCharacters(in: .whitespacesAndNewlines)
            newTVShow.cast = castText.isEmpty ? nil : castText
            let seasonsText = seasons.trimmingCharacters(in: .whitespacesAndNewlines)
            newTVShow.seasons = seasonsText.isEmpty ? nil : seasonsText
        } else {
            // Parse air date
            let airDateString: String? = {
                let trimmed = airDate.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { return nil }
                
                // Try to convert MM/DD/YYYY to yyyy-MM-dd
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yyyy"
                if let date = dateFormatter.date(from: trimmed) {
                    let outputFormatter = DateFormatter()
                    outputFormatter.dateFormat = "yyyy-MM-dd"
                    return outputFormatter.string(from: date)
                }
                
                // If conversion fails, just use the original string
                return trimmed
            }()
            
            newTVShow = TVShow(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                year: Int(year.trimmingCharacters(in: .whitespacesAndNewlines)),
                rating: Double(rating.trimmingCharacters(in: .whitespacesAndNewlines)),
                seasons: seasons.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : seasons.trimmingCharacters(in: .whitespacesAndNewlines),
                genres: genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : genre.trimmingCharacters(in: .whitespacesAndNewlines),
                overview: overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : overview.trimmingCharacters(in: .whitespacesAndNewlines),
                airDate: airDateString,
                creators: creators.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : creators.trimmingCharacters(in: .whitespacesAndNewlines),
                cast: cast.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : cast.trimmingCharacters(in: .whitespacesAndNewlines),
                status: status.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : status.trimmingCharacters(in: .whitespacesAndNewlines),
                numberOfSeasons: Int(numberOfSeasons.trimmingCharacters(in: .whitespacesAndNewlines)),
                numberOfEpisodes: Int(numberOfEpisodes.trimmingCharacters(in: .whitespacesAndNewlines))
            )
        }
        
        modelContext.insert(newTVShow)
        dismiss()
    }
} 